// Data-model names mirror the terminology in the product specification.
// ignore_for_file: public_member_api_docs

import 'package:contracts/contracts.dart';

/// Kinds of material scheduled by the planner.
enum PlanUnitKind { passage, junction, hardSpot, skill }

/// Memorization queue for passages and junctions.
enum PlanQueue { notStarted, learning, recent, old }

/// Lifecycle of a difficult place.
enum HardSpotStage { open, practicing, closed }

/// Lifecycle of a course skill.
enum SkillStage { learning, review }

/// Planner-facing FSRS state, independent from storage and the FSRS package.
enum FsrsStage { learning, review, relearning }

/// How a reading was attempted.
enum AttemptMode {
  listening,
  supported,
  recall,
  selfCheck,
  selfReport,
}

/// What happened in an attempt before planner grading.
enum AttemptResult {
  clean,
  selfCorrected,
  confirmedError,
  unableToVerify,
  disputed,
  remembered,
  rememberedWithDifficulty,
  forgotten,
}

/// How the result was established.
enum VerificationMethod { voice, selfCheck, listener, none }

/// Four FSRS ratings used in the product wording.
enum PlannerRating { again, hard, good, easy }

/// Why no rating was applied.
enum NoRatingReason { supportedMode, unableToVerify, disputed, notAssessable }

/// A word range supplied by the content layer.
final class PassageRange {
  /// Creates a range with its known word count.
  const PassageRange({
    required this.from,
    required this.to,
    required this.wordCount,
  }) : assert(wordCount > 0, 'wordCount must be positive.');

  final WordKey from;
  final WordKey to;
  final int wordCount;

  /// Surah containing the first word.
  int get surah => from.surah;

  /// Whether this range is wholly inside [outer].
  bool isInside(PassageRange outer) =>
      from.compareTo(outer.from) >= 0 && to.compareTo(outer.to) <= 0;
}

/// Immutable snapshot of an FSRS card.
final class FsrsCardSnapshot {
  /// Creates a card snapshot.
  const FsrsCardSnapshot({
    required this.cardId,
    required this.stage,
    required this.due,
    this.step,
    this.stability,
    this.difficulty,
    this.lastReview,
  });

  /// Creates an unreviewed card due immediately.
  factory FsrsCardSnapshot.initial({
    required int cardId,
    required DateTime now,
  }) =>
      FsrsCardSnapshot(
        cardId: cardId,
        stage: FsrsStage.learning,
        step: 0,
        due: now.toUtc(),
      );

  final int cardId;
  final FsrsStage stage;
  final int? step;
  final double? stability;
  final double? difficulty;
  final DateTime due;
  final DateTime? lastReview;
}

/// Raw outcome of one complete plan-unit attempt.
final class Attempt {
  /// Creates an attempt.
  const Attempt({
    required this.unitId,
    required this.at,
    required this.mode,
    required this.result,
    required this.hints,
    required this.verification,
    required this.duration,
    required this.wordCount,
  })  : assert(hints >= 0, 'hints must not be negative.'),
        assert(wordCount > 0, 'wordCount must be positive.');

  final String unitId;
  final DateTime at;
  final AttemptMode mode;
  final AttemptResult result;
  final int hints;
  final VerificationMethod verification;
  final Duration duration;
  final int wordCount;

  /// Seconds per word for personal-speed estimation.
  double get secondsPerWord => duration.inMilliseconds / wordCount / 1000;

  /// A clean attempt without help.
  bool get isCleanWithoutHints => result == AttemptResult.clean && hints == 0;
}

/// Result of applying the product grading table to an attempt.
final class AttemptAssessment {
  /// Creates an assessed attempt.
  const AttemptAssessment({
    this.rating,
    this.noRatingReason,
    this.needsRecheck = false,
  }) : assert(
          (rating == null) != (noRatingReason == null),
          'Exactly one result must be set.',
        );

  final PlannerRating? rating;
  final NoRatingReason? noRatingReason;
  final bool needsRecheck;

  /// Whether this attempt moves the FSRS card and due date.
  bool get isRated => rating != null;
}

/// Attempt together with its derived planner assessment.
final class AttemptRecord {
  /// Creates a record.
  const AttemptRecord({required this.attempt, required this.assessment});

  final Attempt attempt;
  final AttemptAssessment assessment;
}

/// One immutable unit handled by the planner.
final class PlanUnit {
  /// Creates a plan unit.
  PlanUnit({
    required this.id,
    required this.kind,
    required this.range,
    required this.card,
    required this.due,
    Set<String> goalIds = const {},
    this.queue = PlanQueue.notStarted,
    this.hardSpotStage,
    this.skillStage,
    this.recentStartedAt,
    this.learningStartedAt,
    this.recentReviewIndex = 0,
    this.consecutiveForgot = 0,
    this.hardSpotCleanAt,
    List<AttemptRecord> history = const [],
    this.knownBefore = false,
    this.acceleratedLearning = false,
    this.previousUnitId,
    this.hasOpenHardSpot = false,
    this.priorErrorCount = 0,
  })  : goalIds = Set.unmodifiable(goalIds),
        history = List.unmodifiable(history),
        assert(
          recentReviewIndex >= 0,
          'recentReviewIndex must not be negative.',
        ),
        assert(
          consecutiveForgot >= 0,
          'consecutiveForgot must not be negative.',
        ),
        assert(priorErrorCount >= 0, 'priorErrorCount must not be negative.'),
        assert(
          kind == PlanUnitKind.hardSpot || hardSpotStage == null,
          'Only a hard spot has hardSpotStage.',
        ),
        assert(
          kind == PlanUnitKind.skill || skillStage == null,
          'Only a skill has skillStage.',
        );

  final String id;
  final PlanUnitKind kind;
  final PassageRange range;
  final Set<String> goalIds;
  final PlanQueue queue;
  final HardSpotStage? hardSpotStage;
  final SkillStage? skillStage;
  final FsrsCardSnapshot card;
  final DateTime due;
  final DateTime? recentStartedAt;
  final DateTime? learningStartedAt;
  final int recentReviewIndex;
  final int consecutiveForgot;
  final DateTime? hardSpotCleanAt;
  final List<AttemptRecord> history;
  final bool knownBefore;
  final bool acceleratedLearning;
  final String? previousUnitId;
  final bool hasOpenHardSpot;
  final int priorErrorCount;

  /// Most recent attempt, including ungraded attempts.
  Attempt? get lastAttempt => history.isEmpty ? null : history.last.attempt;

  /// How the latest attempt was verified.
  VerificationMethod? get lastVerification => lastAttempt?.verification;

  /// Creates a changed immutable copy.
  PlanUnit copyWith({
    PlanQueue? queue,
    HardSpotStage? hardSpotStage,
    SkillStage? skillStage,
    FsrsCardSnapshot? card,
    DateTime? due,
    DateTime? recentStartedAt,
    DateTime? learningStartedAt,
    int? recentReviewIndex,
    int? consecutiveForgot,
    DateTime? hardSpotCleanAt,
    bool clearHardSpotCleanAt = false,
    List<AttemptRecord>? history,
    bool? knownBefore,
    bool? acceleratedLearning,
    String? previousUnitId,
    bool? hasOpenHardSpot,
    int? priorErrorCount,
  }) =>
      PlanUnit(
        id: id,
        kind: kind,
        range: range,
        goalIds: goalIds,
        queue: queue ?? this.queue,
        hardSpotStage: hardSpotStage ?? this.hardSpotStage,
        skillStage: skillStage ?? this.skillStage,
        card: card ?? this.card,
        due: due ?? this.due,
        recentStartedAt: recentStartedAt ?? this.recentStartedAt,
        learningStartedAt: learningStartedAt ?? this.learningStartedAt,
        recentReviewIndex: recentReviewIndex ?? this.recentReviewIndex,
        consecutiveForgot: consecutiveForgot ?? this.consecutiveForgot,
        hardSpotCleanAt: clearHardSpotCleanAt
            ? null
            : hardSpotCleanAt ?? this.hardSpotCleanAt,
        history: List.unmodifiable(history ?? this.history),
        knownBefore: knownBefore ?? this.knownBefore,
        acceleratedLearning: acceleratedLearning ?? this.acceleratedLearning,
        previousUnitId: previousUnitId ?? this.previousUnitId,
        hasOpenHardSpot: hasOpenHardSpot ?? this.hasOpenHardSpot,
        priorErrorCount: priorErrorCount ?? this.priorErrorCount,
      );
}

/// A user goal. [unitIds] preserves the person's chosen order.
final class PlanGoal {
  /// Creates a goal.
  PlanGoal({
    required this.id,
    required List<String> unitIds,
    this.active = true,
  }) : unitIds = List.unmodifiable(unitIds);

  final String id;
  final List<String> unitIds;
  final bool active;
}

/// A course lesson available for today's session.
final class CourseLesson {
  /// Creates a lesson with content-provided duration.
  const CourseLesson({required this.id, required this.duration});

  final String id;
  final Duration duration;
}
