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
    this.firstSurah = 1,
    this.firstShortSurah = 114,
    this.lastShortSurah = 78,
    this.learnJunctionWords = 2,
    this.courseStages = 10,
    this.firstPaidStage = 4,
    this.staleOverdueDays = 7,
    this.staleRetrievability = 0.7,
    this.confirmIntervalDays = 1,
    this.maxRemindersPerDay = 2,
  });

  /// Delay before a loading skeleton is shown (spec section 13).
  final Duration skeletonDelay;

  /// Daily free voice-check allowance from the monetization specification.
  final Duration freeVoiceLimit;

  /// Initial study budget.
  final int defaultDailyMinutes;

  /// Initial number of repetitions when learning new material.
  final int defaultMemorizationRepeats;

  /// Surah of the start “Al-Fatiha” (docs/tz 13.1).
  final int firstSurah;

  /// First surah of the start “short surahs from the end of the Quran”
  /// (docs/tz 13.1): the last surah; later ones are added by learning new
  /// material (Q11).
  final int firstShortSurah;

  /// Last surah of the short surahs from the end (СТ-09: 114 → 78).
  final int lastShortSurah;

  /// Words on each side of the junction of two passages (ЗН-03); the spec
  /// gives no number yet (question to the owner).
  final int learnJunctionWords;

  /// Stages of the reading course (docs/tz 3.1, УЧ-08: stages 1–10).
  final int courseStages;

  /// First paid stage (13.9: «этап 4 и дальше»).
  final int firstPaidStage;

  /// «Давно не проверял»: overdue by more than this many days (11.1).
  final int staleOverdueDays;

  /// «Давно не проверял»: probability of remembering below this (11.1).
  final double staleRetrievability;

  /// «Подтвердил позже»: clean attempts this many days apart (11.1).
  final int confirmIntervalDays;

  /// `maxRemindersPerDay` (12.4, 11.8).
  final int maxRemindersPerDay;
}
