import 'dart:math';

import 'package:fsrs/fsrs.dart' as fsrs;

import 'package:planner/src/clock.dart';
import 'package:planner/src/grading.dart';
import 'package:planner/src/models.dart';
import 'package:planner/src/params.dart';

/// Pure-Dart planner transitions and FSRS scheduling.
final class PlannerEngine {
  /// Creates an engine with explicit time and randomness dependencies.
  PlannerEngine({
    required this.params,
    required this.clock,
    required Random random,
  })  : _random = random,
        _scheduler = fsrs.Scheduler(
          desiredRetention: params.desiredRetention,
          learningSteps: const [],
          relearningSteps: const [],
          enableFuzzing: false,
        );

  /// Tunable product parameters used by transitions and scheduling.
  final PlannerParams params;

  /// Time source used by every date-dependent operation.
  final Clock clock;
  final Random _random;
  final fsrs.Scheduler _scheduler;

  /// Starts or resumes memorization of [unit].
  PlanUnit startLearning(PlanUnit unit) {
    final now = clock.now().toUtc();
    return unit.copyWith(
      queue: PlanQueue.learning,
      learningStartedAt: unit.learningStartedAt ?? now,
      due: now,
    );
  }

  /// Applies one attempt, preserving history even when it has no rating.
  PlanUnit applyAttempt(PlanUnit unit, Attempt attempt) {
    if (attempt.unitId != unit.id) {
      throw ArgumentError.value(
        attempt.unitId,
        'attempt.unitId',
        'Must match unit.id.',
      );
    }
    final at = attempt.at.toUtc();
    final normalized = Attempt(
      unitId: attempt.unitId,
      at: at,
      mode: attempt.mode,
      result: attempt.result,
      hints: attempt.hints,
      verification: attempt.verification,
      duration: attempt.duration,
      wordCount: attempt.wordCount,
    );
    final assessment = assessAttempt(normalized, unit.history, params);
    final history = List<AttemptRecord>.unmodifiable([
      ...unit.history,
      AttemptRecord(attempt: normalized, assessment: assessment),
    ]);
    var changed = unit.copyWith(history: history);
    final rating = assessment.rating;
    if (rating == null) return changed;

    final scheduled = _reviewCard(unit.card, rating, normalized);
    changed = changed.copyWith(
      card: scheduled,
      due: scheduled.due,
      priorErrorCount:
          unit.priorErrorCount + (rating == PlannerRating.again ? 1 : 0),
    );

    return switch (unit.kind) {
      PlanUnitKind.hardSpot => _updateHardSpot(changed, normalized, rating),
      PlanUnitKind.skill => _updateSkill(changed, rating),
      PlanUnitKind.passage ||
      PlanUnitKind.junction =>
        _updatePassage(changed, normalized, rating),
    };
  }

  PlanUnit _updatePassage(
    PlanUnit unit,
    Attempt attempt,
    PlannerRating rating,
  ) {
    final learned = (unit.queue == PlanQueue.learning ||
            unit.queue == PlanQueue.notStarted) &&
        attempt.mode == AttemptMode.selfCheck &&
        attempt.isCleanWithoutHints;
    if (learned) {
      return unit.copyWith(
        queue: PlanQueue.recent,
        recentStartedAt: attempt.at,
        recentReviewIndex: 0,
        consecutiveForgot: 0,
        due: attempt.at.add(Duration(days: params.recentLadderDays.first)),
      );
    }

    if (unit.queue == PlanQueue.recent) {
      final index = unit.recentReviewIndex + 1;
      final ladderIndex = index < params.recentLadderDays.length
          ? index
          : params.recentLadderDays.length - 1;
      final recentDue = attempt.at.add(
        Duration(days: params.recentLadderDays[ladderIndex]),
      );
      final recentStartedAt = unit.recentStartedAt;
      final oldEnough = recentStartedAt != null &&
          attempt.at.difference(recentStartedAt).inDays >= params.recentDays;
      final rated = unit.history
          .where((record) => record.assessment.rating != null)
          .toList();
      final enoughStrong = rated.length >= params.recentStrongAttempts &&
          rated.sublist(rated.length - params.recentStrongAttempts).every(
                (record) =>
                    record.assessment.rating == PlannerRating.good ||
                    record.assessment.rating == PlannerRating.easy,
              );
      if (oldEnough && enoughStrong) {
        return unit.copyWith(
          queue: PlanQueue.old,
          recentReviewIndex: index,
          due: unit.card.due,
        );
      }
      return unit.copyWith(
        recentReviewIndex: index,
        due: recentDue,
      );
    }

    if (unit.queue == PlanQueue.old) {
      final forgot =
          rating == PlannerRating.again ? unit.consecutiveForgot + 1 : 0;
      if (forgot >= params.oldForgotRelearnCount) {
        return unit.copyWith(
          queue: PlanQueue.learning,
          learningStartedAt: attempt.at,
          consecutiveForgot: forgot,
          acceleratedLearning: true,
          due: attempt.at,
        );
      }
      return unit.copyWith(consecutiveForgot: forgot);
    }

    return unit;
  }

  PlanUnit _updateHardSpot(
    PlanUnit unit,
    Attempt attempt,
    PlannerRating rating,
  ) {
    if (unit.hardSpotStage == HardSpotStage.closed) return unit;
    final clean = attempt.isCleanWithoutHints &&
        (rating == PlannerRating.good || rating == PlannerRating.easy);
    if (!clean) {
      return unit.copyWith(
        hardSpotStage: HardSpotStage.open,
        clearHardSpotCleanAt: true,
        due: attempt.at.add(Duration(days: params.hardSpotReviewDays.first)),
      );
    }
    final firstClean = unit.hardSpotCleanAt;
    if (unit.hardSpotStage == HardSpotStage.practicing &&
        firstClean != null &&
        attempt.at.difference(firstClean).inDays >=
            params.hardSpotReviewDays.first) {
      return unit.copyWith(
        hardSpotStage: HardSpotStage.closed,
        due: unit.card.due,
      );
    }
    return unit.copyWith(
      hardSpotStage: HardSpotStage.practicing,
      hardSpotCleanAt: attempt.at,
      due: attempt.at.add(Duration(days: params.hardSpotReviewDays.last)),
    );
  }

  PlanUnit _updateSkill(PlanUnit unit, PlannerRating rating) {
    final reviewed =
        rating == PlannerRating.good || rating == PlannerRating.easy;
    return unit.copyWith(
      skillStage: reviewed ? SkillStage.review : SkillStage.learning,
      due: unit.card.due,
    );
  }

  FsrsCardSnapshot _reviewCard(
    FsrsCardSnapshot snapshot,
    PlannerRating rating,
    Attempt attempt,
  ) {
    final result = _scheduler.reviewCard(
      _toFsrs(snapshot),
      _toFsrsRating(rating),
      reviewDateTime: attempt.at,
      reviewDuration: attempt.duration.inMilliseconds,
    );
    return _fromFsrs(result.card);
  }

  /// Current FSRS probability of remembering [unit].
  double retrievability(PlanUnit unit, {DateTime? at}) {
    if (unit.card.lastReview == null || unit.card.stability == null) return 0;
    return _scheduler.getCardRetrievability(
      _toFsrs(unit.card),
      currentDateTime: (at ?? clock.now()).toUtc(),
    );
  }

  /// Chooses 2–3 passages for the simple “known before” recovery check.
  List<PlanUnit> recoverySample(List<PlanUnit> surahUnits) {
    final candidates =
        surahUnits.where((unit) => unit.kind == PlanUnitKind.passage).toList();
    if (candidates.isEmpty) return const [];
    candidates.shuffle(_random);
    final span = params.recoveryMaxSample - params.recoveryMinSample + 1;
    final wanted = params.recoveryMinSample + _random.nextInt(span);
    return List.unmodifiable(candidates.take(min(wanted, candidates.length)));
  }

  /// Marks a passage as previously known but not yet checked.
  PlanUnit markKnownBefore(PlanUnit unit) => unit.copyWith(
        queue: PlanQueue.notStarted,
        knownBefore: true,
        due: clock.now().toUtc(),
      );

  /// Applies the first selective recovery check for a previously known unit.
  PlanUnit applyRecoveryCheck(PlanUnit unit, Attempt attempt) {
    final updated = applyAttempt(unit, attempt);
    if (attempt.isCleanWithoutHints) {
      return updated.copyWith(
        queue: PlanQueue.recent,
        recentStartedAt: attempt.at.toUtc(),
        recentReviewIndex: 0,
        acceleratedLearning: false,
        due: attempt.at
            .toUtc()
            .add(Duration(days: params.recentLadderDays.first)),
      );
    }
    return updated.copyWith(
      queue: PlanQueue.learning,
      learningStartedAt: attempt.at.toUtc(),
      acceleratedLearning: true,
      due: attempt.at.toUtc(),
    );
  }
}

fsrs.Card _toFsrs(FsrsCardSnapshot snapshot) => fsrs.Card(
      cardId: snapshot.cardId,
      state: switch (snapshot.stage) {
        FsrsStage.learning => fsrs.State.learning,
        FsrsStage.review => fsrs.State.review,
        FsrsStage.relearning => fsrs.State.relearning,
      },
      step: snapshot.step,
      stability: snapshot.stability,
      difficulty: snapshot.difficulty,
      due: snapshot.due.toUtc(),
      lastReview: snapshot.lastReview?.toUtc(),
    );

FsrsCardSnapshot _fromFsrs(fsrs.Card card) => FsrsCardSnapshot(
      cardId: card.cardId,
      stage: switch (card.state) {
        fsrs.State.learning => FsrsStage.learning,
        fsrs.State.review => FsrsStage.review,
        fsrs.State.relearning => FsrsStage.relearning,
      },
      step: card.step,
      stability: card.stability,
      difficulty: card.difficulty,
      due: card.due.toUtc(),
      lastReview: card.lastReview?.toUtc(),
    );

fsrs.Rating _toFsrsRating(PlannerRating rating) => switch (rating) {
      PlannerRating.again => fsrs.Rating.again,
      PlannerRating.hard => fsrs.Rating.hard,
      PlannerRating.good => fsrs.Rating.good,
      PlannerRating.easy => fsrs.Rating.easy,
    };
