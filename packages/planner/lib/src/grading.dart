import 'package:planner/src/models.dart';
import 'package:planner/src/params.dart';

/// Applies the grading table from docs/tz section 3.4.
AttemptAssessment assessAttempt(
  Attempt attempt,
  List<AttemptRecord> priorHistory,
  PlannerParams params,
) {
  if (attempt.mode == AttemptMode.supported ||
      attempt.mode == AttemptMode.listening) {
    return const AttemptAssessment(
      noRatingReason: NoRatingReason.supportedMode,
    );
  }
  if (attempt.result == AttemptResult.unableToVerify) {
    return const AttemptAssessment(
      noRatingReason: NoRatingReason.unableToVerify,
    );
  }
  if (attempt.result == AttemptResult.disputed) {
    return const AttemptAssessment(
      noRatingReason: NoRatingReason.disputed,
      needsRecheck: true,
    );
  }

  if (attempt.mode == AttemptMode.selfReport) {
    return switch (attempt.result) {
      AttemptResult.remembered =>
        const AttemptAssessment(rating: PlannerRating.good),
      AttemptResult.rememberedWithDifficulty =>
        const AttemptAssessment(rating: PlannerRating.hard),
      AttemptResult.forgotten =>
        const AttemptAssessment(rating: PlannerRating.again),
      _ => const AttemptAssessment(
          noRatingReason: NoRatingReason.notAssessable,
        ),
    };
  }

  if (attempt.result == AttemptResult.confirmedError ||
      attempt.hints >= params.forgotHintCount) {
    return const AttemptAssessment(rating: PlannerRating.again);
  }
  if (attempt.result == AttemptResult.selfCorrected ||
      attempt.hints >= params.hardHintCount) {
    return const AttemptAssessment(rating: PlannerRating.hard);
  }
  if (attempt.result != AttemptResult.clean || attempt.hints != 0) {
    return const AttemptAssessment(
      noRatingReason: NoRatingReason.notAssessable,
    );
  }

  if (_qualifiesForEasy(attempt, priorHistory, params)) {
    return const AttemptAssessment(rating: PlannerRating.easy);
  }
  return const AttemptAssessment(rating: PlannerRating.good);
}

bool _qualifiesForEasy(
  Attempt attempt,
  List<AttemptRecord> priorHistory,
  PlannerParams params,
) {
  final priorCount = params.easyConsecutiveCleanAttempts - 1;
  if (attempt.verification != VerificationMethod.voice ||
      priorHistory.length < priorCount) {
    return false;
  }
  final previousAttempts = priorHistory
      .sublist(priorHistory.length - priorCount)
      .map((record) => record.attempt);
  final consecutiveClean = previousAttempts.every(
    (previous) =>
        previous.verification == VerificationMethod.voice &&
        previous.isCleanWithoutHints,
  );
  final previous = priorHistory.last.attempt;
  final enoughInterval =
      attempt.at.difference(previous.at).inDays >= params.easyMinIntervalDays;
  final average = personalSecondsPerWord(priorHistory, params);
  return consecutiveClean &&
      enoughInterval &&
      average != null &&
      attempt.secondsPerWord < average;
}

/// Moving average of the latest recall attempts with a measurable duration.
double? personalSecondsPerWord(
  List<AttemptRecord> history,
  PlannerParams params,
) {
  final speeds = history
      .where(
        (record) =>
            record.attempt.mode == AttemptMode.recall ||
            record.attempt.mode == AttemptMode.selfCheck,
      )
      .where((record) => record.attempt.duration > Duration.zero)
      .map((record) => record.attempt.secondsPerWord)
      .toList();
  if (speeds.isEmpty) return null;
  final start = speeds.length > params.speedWindow
      ? speeds.length - params.speedWindow
      : 0;
  final window = speeds.sublist(start);
  return window.reduce((left, right) => left + right) / window.length;
}
