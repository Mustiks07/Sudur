// Keep the constructor spelling consistent with the rest of the application.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Product values used by the first-run and daily-plan screens.
final class E01Config {
  /// Creates screen configuration from specification-backed values.
  const E01Config({
    this.skeletonDelay = const Duration(milliseconds: 300),
    this.freeVoiceLimit = const Duration(minutes: 10),
    this.defaultDailyMinutes = 10,
    this.defaultMemorizationRepeats = 3,
  });

  /// Delay before a loading skeleton is shown (spec section 13).
  final Duration skeletonDelay;

  /// Daily free voice-check allowance from the monetization specification.
  final Duration freeVoiceLimit;

  /// Initial study budget.
  final int defaultDailyMinutes;

  /// Initial number of repetitions when learning new material.
  final int defaultMemorizationRepeats;
}
