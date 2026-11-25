// Parameter names mirror config keys and make constructor assertions readable.
// ignore_for_file: prefer_asserts_with_message, public_member_api_docs
// ignore_for_file: sort_constructors_first

/// Tunable planner values from docs/tz section 12.4.
final class PlannerParams {
  /// Creates planner parameters.
  PlannerParams({
    required this.newShare,
    required this.recentShare,
    required this.oldShare,
    required this.hardSpotMaxShare,
    required this.recentDays,
    required List<int> recentLadderDays,
    required this.recentStrongAttempts,
    required this.desiredRetention,
    required this.breakDays,
    required this.diagnosticMinSize,
    required this.diagnosticMaxSize,
    required this.afterBreakNewFactor,
    required this.afterBreakDays,
    required this.defaultSecondsPerWord,
    required this.speedWindow,
    required this.debtLimitFactor,
    required this.passageMaxAyahs,
    required this.recallMultiplier,
    required this.hardSpotMultiplier,
    required this.newLearningMultiplier,
    required this.learnListenRepeats,
    required this.learnSupportedRepeats,
    required this.exerciseContextWords,
    required this.junctionWords,
    required this.junctionRepeats,
    required this.learnJunctionWords,
    required this.hardHintCount,
    required this.forgotHintCount,
    required this.oldForgotRelearnCount,
    required List<int> hardSpotReviewDays,
    required this.easyConsecutiveCleanAttempts,
    required this.easyMinIntervalDays,
    required this.staleAfterDays,
    required this.staleRecallBelow,
    required this.confirmedLaterMinDays,
    required this.memoryConfirmationAttempts,
    required this.unfinishedLookbackDays,
    required this.recoveryMinSample,
    required this.recoveryMaxSample,
    required this.diagnosticBaseWeight,
    required this.diagnosticStalenessWeight,
    required this.diagnosticErrorWeight,
  })  : recentLadderDays = List.unmodifiable(recentLadderDays),
        hardSpotReviewDays = List.unmodifiable(hardSpotReviewDays),
        assert(newShare >= 0 && newShare <= 1),
        assert(recentShare >= 0 && recentShare <= 1),
        assert(oldShare >= 0 && oldShare <= 1),
        assert(hardSpotMaxShare >= 0 && hardSpotMaxShare <= 1),
        assert(recentDays > 0),
        assert(recentLadderDays.isNotEmpty),
        assert(recentLadderDays.every((days) => days > 0)),
        assert(recentStrongAttempts > 0),
        assert(desiredRetention > 0 && desiredRetention < 1),
        assert(breakDays > 0),
        assert(diagnosticMinSize > 0),
        assert(diagnosticMaxSize >= diagnosticMinSize),
        assert(afterBreakNewFactor >= 0 && afterBreakNewFactor <= 1),
        assert(afterBreakDays > 0),
        assert(defaultSecondsPerWord > 0),
        assert(speedWindow > 0),
        assert(debtLimitFactor >= 0),
        assert(passageMaxAyahs > 0),
        assert(recallMultiplier > 0),
        assert(hardSpotMultiplier > 0),
        assert(newLearningMultiplier > 0),
        assert(learnListenRepeats >= 0),
        assert(learnSupportedRepeats >= 0),
        assert(exerciseContextWords >= 0),
        assert(junctionWords > 0),
        assert(junctionRepeats > 0),
        assert(learnJunctionWords > 0),
        assert(hardHintCount > 0),
        assert(forgotHintCount > hardHintCount),
        assert(oldForgotRelearnCount > 0),
        assert(hardSpotReviewDays.isNotEmpty),
        assert(hardSpotReviewDays.every((days) => days > 0)),
        assert(easyConsecutiveCleanAttempts > 1),
        assert(easyMinIntervalDays > 0),
        assert(staleAfterDays > 0),
        assert(staleRecallBelow >= 0 && staleRecallBelow <= 1),
        assert(confirmedLaterMinDays > 0),
        assert(memoryConfirmationAttempts > 1),
        assert(unfinishedLookbackDays > 0),
        assert(recoveryMinSample > 0),
        assert(recoveryMaxSample >= recoveryMinSample),
        assert(diagnosticBaseWeight > 0),
        assert(diagnosticStalenessWeight >= 0),
        assert(diagnosticErrorWeight >= 0);

  /// Defaults from docs/tz 12.4 and explicit rules in docs/tz 11.1.
  static final defaults = PlannerParams(
    newShare: 0.2,
    recentShare: 0.3,
    oldShare: 0.5,
    hardSpotMaxShare: 0.25,
    recentDays: 30,
    recentLadderDays: [1, 2, 4, 7],
    recentStrongAttempts: 2,
    desiredRetention: 0.9,
    breakDays: 7,
    diagnosticMinSize: 3,
    diagnosticMaxSize: 5,
    afterBreakNewFactor: 0.5,
    afterBreakDays: 7,
    defaultSecondsPerWord: 1,
    speedWindow: 10,
    debtLimitFactor: 1,
    passageMaxAyahs: 5,
    recallMultiplier: 1.3,
    hardSpotMultiplier: 3,
    newLearningMultiplier: 8,
    learnListenRepeats: 3,
    learnSupportedRepeats: 2,
    exerciseContextWords: 2,
    junctionWords: 2,
    junctionRepeats: 3,
    learnJunctionWords: 2,
    hardHintCount: 1,
    forgotHintCount: 2,
    oldForgotRelearnCount: 2,
    hardSpotReviewDays: [1, 3],
    easyConsecutiveCleanAttempts: 2,
    easyMinIntervalDays: 1,
    staleAfterDays: 7,
    staleRecallBelow: 0.7,
    confirmedLaterMinDays: 1,
    memoryConfirmationAttempts: 2,
    unfinishedLookbackDays: 1,
    recoveryMinSample: 2,
    recoveryMaxSample: 3,
    diagnosticBaseWeight: 1,
    diagnosticStalenessWeight: 1,
    diagnosticErrorWeight: 1,
  );

  /// Creates parameters by overriding defaults with a config map.
  factory PlannerParams.fromJson(Map<String, Object?> json) {
    final defaults = PlannerParams.defaults;
    return PlannerParams(
      newShare: _double(json, 'newShare', defaults.newShare),
      recentShare: _double(json, 'recentShare', defaults.recentShare),
      oldShare: _double(json, 'oldShare', defaults.oldShare),
      hardSpotMaxShare:
          _double(json, 'hardSpotMaxShare', defaults.hardSpotMaxShare),
      recentDays: _int(json, 'recentDays', defaults.recentDays),
      recentLadderDays: _ints(
        json,
        'recentLadderDays',
        defaults.recentLadderDays,
      ),
      recentStrongAttempts: _int(
        json,
        'recentStrongAttempts',
        defaults.recentStrongAttempts,
      ),
      desiredRetention:
          _double(json, 'desiredRetention', defaults.desiredRetention),
      breakDays: _int(json, 'breakDays', defaults.breakDays),
      diagnosticMinSize:
          _int(json, 'diagnosticMinSize', defaults.diagnosticMinSize),
      diagnosticMaxSize:
          _int(json, 'diagnosticMaxSize', defaults.diagnosticMaxSize),
      afterBreakNewFactor: _double(
        json,
        'afterBreakNewFactor',
        defaults.afterBreakNewFactor,
      ),
      afterBreakDays: _int(json, 'afterBreakDays', defaults.afterBreakDays),
      defaultSecondsPerWord: _double(
        json,
        'defaultSecondsPerWord',
        defaults.defaultSecondsPerWord,
      ),
      speedWindow: _int(json, 'speedWindow', defaults.speedWindow),
      debtLimitFactor:
          _double(json, 'debtLimitFactor', defaults.debtLimitFactor),
      passageMaxAyahs: _int(json, 'passageMaxAyahs', defaults.passageMaxAyahs),
      recallMultiplier:
          _double(json, 'recallMultiplier', defaults.recallMultiplier),
      hardSpotMultiplier: _double(
        json,
        'hardSpotMultiplier',
        defaults.hardSpotMultiplier,
      ),
      newLearningMultiplier: _double(
        json,
        'newLearningMultiplier',
        defaults.newLearningMultiplier,
      ),
      learnListenRepeats:
          _int(json, 'learnListenRepeats', defaults.learnListenRepeats),
      learnSupportedRepeats: _int(
        json,
        'learnSupportedRepeats',
        defaults.learnSupportedRepeats,
      ),
      exerciseContextWords: _int(
        json,
        'exerciseContextWords',
        defaults.exerciseContextWords,
      ),
      junctionWords: _int(json, 'junctionWords', defaults.junctionWords),
      junctionRepeats: _int(json, 'junctionRepeats', defaults.junctionRepeats),
      learnJunctionWords: _int(
        json,
        'learnJunctionWords',
        defaults.learnJunctionWords,
      ),
      hardHintCount: _int(json, 'hardHintCount', defaults.hardHintCount),
      forgotHintCount: _int(json, 'forgotHintCount', defaults.forgotHintCount),
      oldForgotRelearnCount: _int(
        json,
        'oldForgotRelearnCount',
        defaults.oldForgotRelearnCount,
      ),
      hardSpotReviewDays: _ints(
        json,
        'hardSpotReviewDays',
        defaults.hardSpotReviewDays,
      ),
      easyConsecutiveCleanAttempts: _int(
        json,
        'easyConsecutiveCleanAttempts',
        defaults.easyConsecutiveCleanAttempts,
      ),
      easyMinIntervalDays: _int(
        json,
        'easyMinIntervalDays',
        defaults.easyMinIntervalDays,
      ),
      staleAfterDays: _int(json, 'staleAfterDays', defaults.staleAfterDays),
      staleRecallBelow: _double(
        json,
        'staleRecallBelow',
        defaults.staleRecallBelow,
      ),
      confirmedLaterMinDays: _int(
        json,
        'confirmedLaterMinDays',
        defaults.confirmedLaterMinDays,
      ),
      memoryConfirmationAttempts: _int(
        json,
        'memoryConfirmationAttempts',
        defaults.memoryConfirmationAttempts,
      ),
      unfinishedLookbackDays: _int(
        json,
        'unfinishedLookbackDays',
        defaults.unfinishedLookbackDays,
      ),
      recoveryMinSample:
          _int(json, 'recoveryMinSample', defaults.recoveryMinSample),
      recoveryMaxSample:
          _int(json, 'recoveryMaxSample', defaults.recoveryMaxSample),
      diagnosticBaseWeight: _double(
        json,
        'diagnosticBaseWeight',
        defaults.diagnosticBaseWeight,
      ),
      diagnosticStalenessWeight: _double(
        json,
        'diagnosticStalenessWeight',
        defaults.diagnosticStalenessWeight,
      ),
      diagnosticErrorWeight: _double(
        json,
        'diagnosticErrorWeight',
        defaults.diagnosticErrorWeight,
      ),
    );
  }

  final double newShare;
  final double recentShare;
  final double oldShare;
  final double hardSpotMaxShare;
  final int recentDays;
  final List<int> recentLadderDays;
  final int recentStrongAttempts;
  final double desiredRetention;
  final int breakDays;
  final int diagnosticMinSize;
  final int diagnosticMaxSize;
  final double afterBreakNewFactor;
  final int afterBreakDays;
  final double defaultSecondsPerWord;
  final int speedWindow;
  final double debtLimitFactor;
  final int passageMaxAyahs;
  final double recallMultiplier;
  final double hardSpotMultiplier;
  final double newLearningMultiplier;
  final int learnListenRepeats;
  final int learnSupportedRepeats;

  /// Words on each side of a mistake in «Трудный отрывок» (УП-01, 12.4).
  final int exerciseContextWords;

  /// Words on each side of an ayah junction (УП-02, 12.4).
  final int junctionWords;

  /// Hidden readings of an ayah junction (УП-02, 12.4).
  final int junctionRepeats;

  /// Words on each side of the junction of two passages when learning
  /// (ЗН-03, 12.4).
  final int learnJunctionWords;

  /// Hint thresholds from the grading table in docs/tz 3.4.
  final int hardHintCount;
  final int forgotHintCount;

  /// Two consecutive “Again” ratings from docs/tz 11.1.
  final int oldForgotRelearnCount;

  /// 1 and 3 days from docs/tz 11.1.
  final List<int> hardSpotReviewDays;

  /// Consecutive clean readings required for an Easy rating.
  final int easyConsecutiveCleanAttempts;

  /// Explicit interpretation of “with an interval” in the Easy rule.
  final int easyMinIntervalDays;

  /// 7 days from the memory-map rule in docs/tz 11.1.
  final int staleAfterDays;

  /// 0.7 from the memory-map rule in docs/tz 11.1.
  final double staleRecallBelow;

  /// One-day interval from the memory-map confirmation rule.
  final int confirmedLaterMinDays;

  /// Clean attempts required for the confirmed-later memory state.
  final int memoryConfirmationAttempts;

  /// Calendar distance used to identify yesterday's unfinished material.
  final int unfinishedLookbackDays;

  /// 2–3 passages from recovery in docs/tz 11.1.
  final int recoveryMinSample;
  final int recoveryMaxSample;

  /// Diagnostic weighting is configurable because the specification gives no
  /// relative coefficients for staleness and past errors.
  final double diagnosticBaseWeight;
  final double diagnosticStalenessWeight;
  final double diagnosticErrorWeight;
}

double _double(Map<String, Object?> json, String key, double fallback) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  throw FormatException('$key must be a number', value);
}

int _int(Map<String, Object?> json, String key, int fallback) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is int) return value;
  throw FormatException('$key must be an integer', value);
}

List<int> _ints(Map<String, Object?> json, String key, List<int> fallback) {
  final value = json[key];
  if (value == null) return List.unmodifiable(fallback);
  if (value is! List<Object?> || value.any((item) => item is! int)) {
    throw FormatException('$key must be a list of integers', value);
  }
  return List.unmodifiable(value.cast<int>());
}
