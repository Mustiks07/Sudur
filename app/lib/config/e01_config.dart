// Keep the constructor spelling consistent with the rest of the application.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Product values used by the first-run and daily-plan screens.
final class E01Config {
  /// Creates screen configuration from specification-backed values.
  const E01Config({
    this.skeletonDelay = const Duration(milliseconds: 300),
    this.freeVoiceLimit = const Duration(minutes: 10),
    this.defaultDailyMinutes = 10,
    this.firstSurah = 1,
    this.firstShortSurah = 114,
    this.lastShortSurah = 78,
  });

  /// Delay before a loading skeleton is shown (spec section 13).
  final Duration skeletonDelay;

  /// Daily free voice-check allowance from the monetization specification.
  final Duration freeVoiceLimit;

  /// Initial study budget.
  final int defaultDailyMinutes;

  /// Surah of the start “Al-Fatiha” (docs/tz 13.1).
  final int firstSurah;

  /// First surah of the start “short surahs from the end of the Quran”
  /// (docs/tz 13.1): the last surah; later ones are added by learning new
  /// material (Q11).
  final int firstShortSurah;

  /// Last surah of the short surahs from the end (СТ-09: 114 → 78).
  final int lastShortSurah;
}
