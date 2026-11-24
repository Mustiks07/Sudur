// Immutable DTOs intentionally expose descriptive fields and enum values.
// ignore_for_file: public_member_api_docs
// ignore_for_file: unnecessary_type_name_in_constructor
// ignore_for_file: sort_constructors_first

import 'package:contracts/contracts.dart';

/// Interface languages supported by the application.
enum AppLanguage { ru, kk, uz, en }

/// Learning paths offered during first run.
enum AppLearningPath { learnReading, memorize, restore }

/// First material offered when no familiar surah was selected.
enum AppStartPoint { firstSurah, shortSurahs }

/// “Do you know the letters?” choice for the reading course.
enum LetterKnowledge { no, aLittle }

/// Stable first-run steps persisted after every choice.
enum OnboardingStep {
  language,
  path,
  familiarSurahs,
  dailyTime,
  model,
  startPoint,
  letters,
  completed,
}

/// Resumable first-run state.
final class OnboardingDraft {
  /// Creates a first-run draft.
  OnboardingDraft({
    this.step = OnboardingStep.language,
    this.language,
    this.path,
    Set<int> familiarSurahs = const <int>{},
    this.dailyMinutes,
    this.downloadModelNow,
    this.startPoint,
    this.letterKnowledge,
  }) : familiarSurahs = Set<int>.unmodifiable(familiarSurahs);

  /// Current visible step.
  final OnboardingStep step;

  /// Selected interface language.
  final AppLanguage? language;

  /// Selected learning path.
  final AppLearningPath? path;

  /// Surah numbers selected as familiar, without handwritten names or text.
  final Set<int> familiarSurahs;

  /// Daily time budget.
  final int? dailyMinutes;

  /// Whether the model should be downloaded before first completion.
  final bool? downloadModelNow;

  /// Default material when there is nothing to repeat.
  final AppStartPoint? startPoint;

  /// Course entry choice.
  final LetterKnowledge? letterKnowledge;

  /// Creates an immutable changed copy.
  OnboardingDraft copyWith({
    OnboardingStep? step,
    AppLanguage? language,
    AppLearningPath? path,
    Set<int>? familiarSurahs,
    int? dailyMinutes,
    bool? downloadModelNow,
    AppStartPoint? startPoint,
    LetterKnowledge? letterKnowledge,
  }) => OnboardingDraft(
    step: step ?? this.step,
    language: language ?? this.language,
    path: path ?? this.path,
    familiarSurahs: familiarSurahs ?? this.familiarSurahs,
    dailyMinutes: dailyMinutes ?? this.dailyMinutes,
    downloadModelNow: downloadModelNow ?? this.downloadModelNow,
    startPoint: startPoint ?? this.startPoint,
    letterKnowledge: letterKnowledge ?? this.letterKnowledge,
  );

  /// JSON stored in the settings table while onboarding is unfinished.
  Map<String, Object?> toJson() => <String, Object?>{
    'step': step.name,
    'language': language?.name,
    'path': path?.name,
    'familiarSurahs': familiarSurahs.toList()..sort(),
    'dailyMinutes': dailyMinutes,
    'downloadModelNow': downloadModelNow,
    'startPoint': startPoint?.name,
    'letterKnowledge': letterKnowledge?.name,
  };

  /// Parses a validated settings value.
  factory OnboardingDraft.fromJson(Map<String, Object?> json) {
    T? named<T extends Enum>(List<T> values, String key) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is! String) throw FormatException('$key must be a string.');
      for (final value in values) {
        if (value.name == raw) return value;
      }
      throw FormatException('Unknown $key value.');
    }

    final rawSurahs = json['familiarSurahs'];
    if (rawSurahs is! List<Object?>) {
      throw const FormatException('familiarSurahs must be a list.');
    }
    final surahs = <int>{};
    for (final raw in rawSurahs) {
      if (raw is! int || raw < 1 || raw > 114) {
        throw const FormatException('A surah number is invalid.');
      }
      surahs.add(raw);
    }
    final minutes = json['dailyMinutes'];
    final download = json['downloadModelNow'];
    if (minutes != null && (minutes is! int || minutes <= 0)) {
      throw const FormatException('dailyMinutes must be positive.');
    }
    if (download != null && download is! bool) {
      throw const FormatException('downloadModelNow must be boolean.');
    }
    return OnboardingDraft(
      step: named(OnboardingStep.values, 'step') ?? OnboardingStep.language,
      language: named(AppLanguage.values, 'language'),
      path: named(AppLearningPath.values, 'path'),
      familiarSurahs: surahs,
      dailyMinutes: minutes as int?,
      downloadModelNow: download as bool?,
      startPoint: named(AppStartPoint.values, 'startPoint'),
      letterKnowledge: named(LetterKnowledge.values, 'letterKnowledge'),
    );
  }
}

/// Names of a surah as the content package has them; `null` where the
/// package has no name yet (names are never written in code).
final class SurahNameData {
  /// Creates the names.
  const SurahNameData({
    required this.number,
    this.arabic,
    this.russian,
    this.kazakh,
    this.uzbek,
  });

  /// Surah number.
  final int number;

  /// Arabic name.
  final String? arabic;

  /// Russian name.
  final String? russian;

  /// Kazakh name.
  final String? kazakh;

  /// Uzbek name.
  final String? uzbek;

  /// Name in [language], else the Arabic one, else `null`.
  String? nameIn(AppLanguage language) =>
      switch (language) {
        AppLanguage.ru || AppLanguage.en => russian,
        AppLanguage.kk => kazakh,
        AppLanguage.uz => uzbek,
      } ??
      arabic;

  /// All known names.
  Iterable<String> get all =>
      [arabic, russian, kazakh, uzbek].whereType<String>();
}

/// Profile data exposed to application ViewModels.
final class AppUserProfile {
  /// Creates an application profile.
  const AppUserProfile({
    required this.id,
    required this.createdAt,
    required this.language,
    required this.path,
    required this.dailyMinutes,
    required this.strictBehavior,
    required this.showFirstWord,
  });

  /// Stable profile id.
  final String id;

  /// Creation instant.
  final DateTime createdAt;

  /// Interface language.
  final AppLanguage language;

  /// Learning path.
  final AppLearningPath path;

  /// Daily study budget.
  final int dailyMinutes;

  /// Whether mistakes stop word reveals.
  final bool strictBehavior;

  /// Whether a passage starts with its first word visible.
  final bool showFirstWord;
}

/// Why a step is included in today's session.
enum TodayStepReason {
  returnDiagnosis,
  yesterdayNew,
  yesterdayError,
  recentDue,
  longUnchecked,
  newMaterial,
  courseLesson,
  skillDue,
  userAdded,
}

/// User-facing kinds of daily-plan steps.
enum TodayStepKind { diagnostic, passage, hardSpot, lesson, skill }

/// One stable daily-plan row.
final class TodayStepData {
  /// Creates a daily-plan row.
  const TodayStepData({
    required this.id,
    required this.kind,
    required this.reason,
    required this.estimatedSeconds,
    this.surah,
    this.unitId,
    this.from,
    this.to,
    this.requiresVoice = false,
    this.selfCheck = false,
    this.done = false,
  });

  /// Stable step identifier.
  final String id;

  /// Visible step kind.
  final TodayStepKind kind;

  /// Explanation shown below the title.
  final TodayStepReason reason;

  /// Planner estimate.
  final int estimatedSeconds;

  /// Surah number, when known; names always come from content later.
  final int? surah;

  /// Plan unit the step reads, when it has one.
  final String? unitId;

  /// First word to read, for steps with words (passage, hard spot, check).
  final WordKey? from;

  /// Last word to read, inclusive.
  final WordKey? to;

  /// Whether this step normally uses voice checking.
  final bool requiresVoice;

  /// Whether voice checking was replaced by self-check.
  final bool selfCheck;

  /// Whether the step was finished today.
  final bool done;

  /// The same step with [done] changed.
  TodayStepData withDone({required bool done}) => TodayStepData(
    id: id,
    kind: kind,
    reason: reason,
    estimatedSeconds: estimatedSeconds,
    surah: surah,
    unitId: unitId,
    from: from,
    to: to,
    requiresVoice: requiresVoice,
    selfCheck: selfCheck,
    done: done,
  );
}

/// Special state rendered above the stable daily plan.
enum TodayCondition {
  firstDay,
  normal,
  returning,
  completed,
  freeLimitReached,
  modelMissing,
}

/// Immutable screen data for “Today”.
final class TodayDashboardData {
  /// Creates dashboard data.
  TodayDashboardData({
    required this.date,
    required this.approximateMinutes,
    required List<TodayStepData> steps,
    required List<TodayStepData> extraReview,
    required this.condition,
    this.inProgress = false,
    this.currentStepId,
  }) : steps = List.unmodifiable(steps),
       extraReview = List.unmodifiable(extraReview);

  /// Local calendar date key.
  final String date;

  /// Rounded planner estimate.
  final int approximateMinutes;

  /// Steps frozen for this date.
  final List<TodayStepData> steps;

  /// Optional review beyond today's budget.
  final List<TodayStepData> extraReview;

  /// Special screen condition.
  final TodayCondition condition;

  /// Whether the main action becomes “Continue”.
  final bool inProgress;

  /// The step that was started and is not finished yet.
  final String? currentStepId;

  /// The step the main action opens: the started one, else the first one
  /// not done; `null` when every step is done.
  TodayStepData? get nextStep {
    for (final step in steps) {
      if (step.id == currentStepId && !step.done) return step;
    }
    for (final step in steps) {
      if (!step.done) return step;
    }
    return null;
  }

  /// Steps finished today.
  int get doneCount => steps.where((step) => step.done).length;
}

/// Settings displayed under “More”.
final class MoreSettingsData {
  /// Creates settings data.
  const MoreSettingsData({
    required this.profile,
    required this.memorizationRepeats,
  });

  /// Profile-backed settings.
  final AppUserProfile profile;

  /// Number of repetitions for new material.
  final int memorizationRepeats;
}

/// Installed download shown in “Downloads”.
final class AppDownloadData {
  /// Creates download data.
  const AppDownloadData({
    required this.id,
    required this.kind,
    required this.bytes,
    required this.installed,
  });

  /// Package identifier.
  final String id;

  /// Stable non-localized package kind.
  final String kind;

  /// Installed size.
  final int bytes;

  /// Whether the package is active.
  final bool installed;
}
