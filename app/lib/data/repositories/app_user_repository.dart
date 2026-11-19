import 'dart:io';

// The explicit constructor names keep this storage adapter easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor
// ignore_for_file: prefer_initializing_formals

import 'package:contracts/contracts.dart';
import 'package:planner/planner.dart';
import 'package:storage/storage.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/services/app_file_service.dart';
import 'package:sudur/data/services/app_planner_service.dart';
import 'package:sudur/data/services/app_storage_service.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';

/// Creates UUID v4 identifiers without exposing the implementation to data UI.
typedef AppIdFactory = String Function();

/// User, onboarding, daily-plan, and settings persistence boundary.
abstract interface class AppUserRepository {
  /// Loads the single V1 profile.
  Future<Result<AppUserProfile?>> loadProfile();

  /// Loads the resumable onboarding draft.
  Future<Result<OnboardingDraft>> loadOnboardingDraft();

  /// Persists the current onboarding step and choices.
  Future<Result<void>> saveOnboardingDraft(OnboardingDraft draft);

  /// Downloads the selected on-device model through the verified installer.
  Future<Result<void>> downloadModel({
    required void Function(PrototypeDownloadProgress progress) onProgress,
  });

  /// Writes the completed profile and initial plan metadata.
  Future<Result<AppUserProfile>> completeOnboarding(OnboardingDraft draft);

  /// Loads or creates today's stable plan.
  Future<Result<TodayDashboardData>> loadToday();

  /// Marks today's plan as started at [stepId].
  Future<Result<TodayDashboardData>> startToday(String stepId);

  /// Removes one step for today without changing future scheduling.
  Future<Result<TodayDashboardData>> skipTodayStep(String stepId);

  /// Loads settings for the “More” screen.
  Future<Result<MoreSettingsData>> loadMoreSettings();

  /// Updates profile-backed study settings.
  Future<Result<MoreSettingsData>> updateStudySettings({
    required int dailyMinutes,
    required bool strictBehavior,
    required bool showFirstWord,
    required int memorizationRepeats,
  });

  /// Updates the current interface language.
  Future<Result<AppUserProfile>> updateLanguage(AppLanguage language);

  /// Lists stored downloadable packages.
  Future<Result<List<AppDownloadData>>> listDownloads();

  /// Deletes installed ASR models and resets their storage records.
  Future<Result<void>> deleteModels();

  /// Exports all user data and opens the system share sheet.
  Future<Result<void>> exportUserData();

  /// Picks, validates, and imports a user-data archive.
  Future<Result<bool>> importUserData();

  /// Deletes all user data and explicitly saved recordings.
  Future<Result<void>> eraseAllUserData();
}

/// Storage-backed repository; drift row records never cross this boundary.
final class StorageAppUserRepository implements AppUserRepository {
  /// Creates a production repository.
  const StorageAppUserRepository({
    required AppStorageService storage,
    required AppFileService files,
    required PrototypeAssetInstaller modelInstaller,
    required AppPlannerService planner,
    required Clock clock,
    required AppIdFactory createId,
    required E01Config config,
  }) : _storageService = storage,
       _files = files,
       _modelInstaller = modelInstaller,
       _planner = planner,
       _clock = clock,
       _createId = createId,
       _config = config;

  static const _draftKey = 'onboardingDraft';
  static const _languageKey = 'appLanguage';
  static const _selectedSurahsKey = 'selectedSurahs';
  static const _startPointKey = 'startPoint';
  static const _modelDeferredKey = 'modelDeferred';
  static const _memorizationRepeatsKey = 'memorizationRepeats';

  final AppStorageService _storageService;
  final AppFileService _files;
  final PrototypeAssetInstaller _modelInstaller;
  final AppPlannerService _planner;
  final Clock _clock;
  final AppIdFactory _createId;
  final E01Config _config;

  @override
  Future<Result<AppUserProfile?>> loadProfile() => _guard(() async {
    final storage = await _storageService.storage;
    final profiles = _unwrap(await storage.profiles.list());
    if (profiles.isEmpty) return null;
    final stored = profiles.first;
    final language = await _language(storage, stored.uiLanguage);
    return _profile(stored, language);
  });

  @override
  Future<Result<OnboardingDraft>> loadOnboardingDraft() => _guard(() async {
    final storage = await _storageService.storage;
    final setting = _unwrap(await storage.settings.get(_draftKey));
    final raw = setting?.value.value;
    if (raw == null) return OnboardingDraft();
    if (raw is! Map<String, Object?>) {
      throw const FormatException('The onboarding draft is invalid.');
    }
    return OnboardingDraft.fromJson(raw);
  });

  @override
  Future<Result<void>> saveOnboardingDraft(OnboardingDraft draft) =>
      _guard(() async {
        final storage = await _storageService.storage;
        _unwrap(
          await storage.settings.put((
            key: _draftKey,
            value: JsonValueData.fromJson(draft.toJson()),
          )),
        );
      });

  @override
  Future<Result<void>> downloadModel({
    required void Function(PrototypeDownloadProgress progress) onProgress,
  }) => _guard(() async {
    final resources = await _modelInstaller.install(
      PrototypeModelChoice.small,
      onProgress: onProgress,
    );
    final modelDirectory = Directory(resources.modelDirectory);
    var bytes = 0;
    await for (final entry in modelDirectory.list(recursive: true)) {
      if (entry is File) bytes += await entry.length();
    }
    final storage = await _storageService.storage;
    _unwrap(
      await storage.downloads.put((
        packageId: 'prototype-asr-small',
        kind: DownloadKind.model,
        activeVersion: 'installed',
        pendingVersion: null,
        state: DownloadState.installed,
        bytesTotal: bytes,
        bytesDone: bytes,
        updatedAt: _nowMs,
      )),
    );
  });

  @override
  Future<Result<AppUserProfile>> completeOnboarding(OnboardingDraft draft) =>
      _guard(() async {
        final language = draft.language;
        final path = draft.path;
        final dailyMinutes = draft.dailyMinutes;
        if (language == null || path == null || dailyMinutes == null) {
          throw const FormatException('Onboarding choices are incomplete.');
        }
        final storage = await _storageService.storage;
        final existing = _unwrap(await storage.profiles.list());
        final id = existing.isEmpty ? _createId() : existing.first.id;
        final createdAt = existing.isEmpty ? _nowMs : existing.first.createdAt;
        final profile = (
          id: id,
          createdAt: createdAt,
          uiLanguage: _storedLanguage(language),
          path: _storedPath(path),
          dailyMinutes: dailyMinutes,
          behavior: ReadingBehavior.gentle,
          showFirstWord: true,
        );
        _unwrap(await storage.profiles.put(profile));
        await _putSetting(storage, _languageKey, language.name);
        await _putSetting(
          storage,
          _selectedSurahsKey,
          draft.familiarSurahs.toList()..sort(),
        );
        await _putSetting(storage, _startPointKey, draft.startPoint?.name);
        await _putSetting(
          storage,
          _modelDeferredKey,
          draft.downloadModelNow == false,
        );
        await _putSetting(
          storage,
          _memorizationRepeatsKey,
          _config.defaultMemorizationRepeats,
        );
        _unwrap(
          await storage.settings.put((
            key: _draftKey,
            value: JsonValueData.fromJson(
              draft.copyWith(step: OnboardingStep.completed).toJson(),
            ),
          )),
        );
        if (path == AppLearningPath.learnReading) {
          await _ensureCourseUnit(storage, id, createdAt);
        }
        return _profile(profile, language);
      });

  Future<void> _ensureCourseUnit(
    StorageService storage,
    String profileId,
    int createdAt,
  ) async {
    final units = _unwrap(await storage.units.listForProfile(profileId));
    if (units.any((unit) => unit.skillId == 'course-entry')) return;
    final id = _createId();
    _unwrap(
      await storage.units.putUnit((
        id: id,
        profileId: profileId,
        kind: UnitKind.skill,
        fromWordIndex: null,
        toWordIndex: null,
        skillId: 'course-entry',
        surah: null,
        origin: UnitOrigin.lesson,
        parentUnitId: null,
        createdAt: createdAt,
      )),
    );
    _unwrap(
      await storage.units.putState((
        unitId: id,
        queue: UnitQueue.notStarted,
        memoryState: null,
        fsrsCard: null,
        dueAt: _nowMs,
        recentSince: null,
        lastAttemptAt: null,
        lastMethod: null,
        updatedAt: _nowMs,
      )),
    );
  }

  @override
  Future<Result<TodayDashboardData>> loadToday() => _guard(() async {
    final storage = await _storageService.storage;
    final profile = await _requiredProfile(storage);
    final date = _localDate(_clock.now());
    final saved = _unwrap(await storage.dailyPlans.get(date));
    final plan = saved == null
        ? await _createToday(storage, profile, date)
        : _decodeToday(saved.items.toJson());
    return await _withCurrentLimitState(storage, plan);
  });

  @override
  Future<Result<TodayDashboardData>> startToday(String stepId) =>
      _changeToday((plan) {
        if (!plan.steps.any((step) => step.id == stepId) &&
            !plan.extraReview.any((step) => step.id == stepId)) {
          throw const FormatException('The selected step is not in today.');
        }
        return TodayDashboardData(
          date: plan.date,
          approximateMinutes: plan.approximateMinutes,
          steps: plan.steps,
          extraReview: plan.extraReview,
          condition: plan.condition,
          inProgress: true,
        );
      });

  @override
  Future<Result<TodayDashboardData>> skipTodayStep(String stepId) =>
      _changeToday((plan) {
        final remaining = plan.steps
            .where((step) => step.id != stepId)
            .toList(growable: false);
        return TodayDashboardData(
          date: plan.date,
          approximateMinutes: _minutesFor(remaining),
          steps: remaining,
          extraReview: plan.extraReview,
          condition: remaining.isEmpty
              ? TodayCondition.completed
              : plan.condition,
          inProgress: plan.inProgress,
        );
      });

  Future<Result<TodayDashboardData>> _changeToday(
    TodayDashboardData Function(TodayDashboardData plan) change,
  ) => _guard(() async {
    final storage = await _storageService.storage;
    final date = _localDate(_clock.now());
    final saved = _unwrap(await storage.dailyPlans.get(date));
    if (saved == null) throw const FormatException('Today has no plan.');
    final changed = change(_decodeToday(saved.items.toJson()));
    await _saveToday(storage, changed);
    return await _withCurrentLimitState(storage, changed);
  });

  Future<TodayDashboardData> _createToday(
    StorageService storage,
    AppUserProfile profile,
    String date,
  ) async {
    final storedUnits = _unwrap(await storage.units.listForProfile(profile.id));
    final units = <PlanUnit>[];
    for (final unit in storedUnits) {
      final state = _unwrap(await storage.units.getState(unit.id));
      final attempts = _unwrap(await storage.attempts.listForUnit(unit.id));
      units.add(_plannerUnit(unit, state, attempts));
    }
    final sessions = _unwrap(await storage.sessions.listForProfile(profile.id));
    final request = TodayPlanRequest(
      units: units,
      budgetSeconds: profile.dailyMinutes * Duration.secondsPerMinute,
      lessons: profile.path == AppLearningPath.learnReading
          ? <CourseLesson>[
              CourseLesson(
                id: 'first-course-lesson',
                duration: Duration(minutes: profile.dailyMinutes),
              ),
            ]
          : const <CourseLesson>[],
      lastStudyAt: sessions.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              sessions.last.endedAt ?? sessions.last.startedAt,
              isUtc: true,
            ),
    );
    final built = _planner.build(request);
    var steps = built.steps
        .map((step) => _todayStep(step, storedUnits))
        .toList(growable: false);
    if (steps.isEmpty) {
      steps = <TodayStepData>[
        TodayStepData(
          id: profile.path == AppLearningPath.learnReading
              ? 'lesson:first-course-lesson'
              : 'start:first-passage',
          kind: profile.path == AppLearningPath.learnReading
              ? TodayStepKind.lesson
              : TodayStepKind.passage,
          reason: profile.path == AppLearningPath.learnReading
              ? TodayStepReason.courseLesson
              : TodayStepReason.newMaterial,
          estimatedSeconds: profile.dailyMinutes * Duration.secondsPerMinute,
          requiresVoice: profile.path != AppLearningPath.learnReading,
        ),
      ];
    }
    final data = TodayDashboardData(
      date: date,
      approximateMinutes: _minutesFor(steps),
      steps: steps,
      extraReview: built.extraReview
          .map((step) => _todayStep(step, storedUnits))
          .toList(growable: false),
      condition: built.isDiagnostic
          ? TodayCondition.returning
          : sessions.isEmpty
          ? TodayCondition.firstDay
          : TodayCondition.normal,
    );
    await _saveToday(storage, data);
    return data;
  }

  PlanUnit _plannerUnit(
    UnitData unit,
    UnitStateData? state,
    List<AttemptData> attempts,
  ) {
    final now = _clock.now().toUtc();
    final fromIndex = unit.fromWordIndex ?? 0;
    final toIndex = unit.toWordIndex ?? fromIndex;
    final surah = unit.surah ?? 1;
    final due = state?.dueAt == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(state!.dueAt!, isUtc: true);
    final history = <AttemptRecord>[
      for (final attempt in attempts)
        AttemptRecord(
          attempt: Attempt(
            unitId: unit.id,
            at: DateTime.fromMillisecondsSinceEpoch(
              attempt.createdAt,
              isUtc: true,
            ),
            mode: _attemptMode(attempt.mode),
            result: _attemptResult(attempt.outcome),
            hints: attempt.hints.value.values.fold(
              0,
              (sum, value) => sum + value,
            ),
            verification: _verification(attempt.method),
            duration: Duration(milliseconds: attempt.durationMs),
            wordCount: attempt.words == 0 ? 1 : attempt.words,
          ),
          assessment: attempt.rating == null
              ? const AttemptAssessment(
                  noRatingReason: NoRatingReason.notAssessable,
                )
              : AttemptAssessment(rating: _plannerRating(attempt.rating!)),
        ),
    ];
    return PlanUnit(
      id: unit.id,
      kind: _planUnitKind(unit.kind),
      range: PassageRange(
        from: WordKey(surah, 1, fromIndex + 1),
        to: WordKey(surah, 1, toIndex + 1),
        wordCount: toIndex - fromIndex + 1,
      ),
      queue: _planQueue(state?.queue),
      hardSpotStage: unit.kind == UnitKind.hardSpot ? HardSpotStage.open : null,
      skillStage: unit.kind == UnitKind.skill ? SkillStage.learning : null,
      card: FsrsCardSnapshot.initial(cardId: fromIndex + 1, now: now),
      due: due,
      history: history,
      knownBefore: unit.origin == UnitOrigin.knownBefore,
      priorErrorCount: attempts
          .where((attempt) => attempt.outcome == AttemptOutcome.withErrors)
          .length,
    );
  }

  TodayStepData _todayStep(PlanStep step, List<UnitData> units) {
    UnitData? unit;
    for (final candidate in units) {
      if (candidate.id == step.unitId) unit = candidate;
    }
    final kind = switch (step.kind) {
      PlanStepKind.diagnostic => TodayStepKind.diagnostic,
      PlanStepKind.hardSpot => TodayStepKind.hardSpot,
      PlanStepKind.lesson => TodayStepKind.lesson,
      PlanStepKind.skill => TodayStepKind.skill,
      _ => TodayStepKind.passage,
    };
    return TodayStepData(
      id: step.id,
      kind: kind,
      reason: TodayStepReason.values.byName(step.reason.name),
      estimatedSeconds: step.estimatedSeconds,
      surah: unit?.surah,
      requiresVoice:
          kind == TodayStepKind.diagnostic ||
          kind == TodayStepKind.passage ||
          kind == TodayStepKind.hardSpot,
    );
  }

  Future<TodayDashboardData> _withCurrentLimitState(
    StorageService storage,
    TodayDashboardData plan,
  ) async {
    if (plan.condition == TodayCondition.completed) return plan;
    final usage = _unwrap(await storage.freeUsage.get(plan.date));
    final freeLimitReached =
        (usage?.listeningMs ?? 0) >= _config.freeVoiceLimit.inMilliseconds;
    final downloads = _unwrap(await storage.downloads.list());
    final modelMissing = !downloads.any(
      (download) =>
          download.kind == DownloadKind.model &&
          download.state == DownloadState.installed,
    );
    final condition = freeLimitReached
        ? TodayCondition.freeLimitReached
        : modelMissing
        ? TodayCondition.modelMissing
        : plan.condition;
    return TodayDashboardData(
      date: plan.date,
      approximateMinutes: plan.approximateMinutes,
      steps: <TodayStepData>[
        for (final step in plan.steps)
          TodayStepData(
            id: step.id,
            kind: step.kind,
            reason: step.reason,
            estimatedSeconds: step.estimatedSeconds,
            surah: step.surah,
            requiresVoice: step.requiresVoice,
            selfCheck: step.requiresVoice && (freeLimitReached || modelMissing),
          ),
      ],
      extraReview: plan.extraReview,
      condition: condition,
      inProgress: plan.inProgress,
    );
  }

  Future<void> _saveToday(
    StorageService storage,
    TodayDashboardData plan,
  ) async {
    _unwrap(
      await storage.dailyPlans.put((
        date: plan.date,
        items: DailyPlanItems.fromJson(_encodeToday(plan)),
        createdAt: _nowMs,
      )),
    );
  }

  List<Object?> _encodeToday(TodayDashboardData plan) => <Object?>[
    <String, Object?>{
      'format': 1,
      'approximateMinutes': plan.approximateMinutes,
      'condition': plan.condition.name,
      'inProgress': plan.inProgress,
      'steps': plan.steps.map(_encodeStep).toList(),
      'extraReview': plan.extraReview.map(_encodeStep).toList(),
    },
  ];

  Map<String, Object?> _encodeStep(TodayStepData step) => <String, Object?>{
    'id': step.id,
    'kind': step.kind.name,
    'reason': step.reason.name,
    'estimatedSeconds': step.estimatedSeconds,
    'surah': step.surah,
    'requiresVoice': step.requiresVoice,
  };

  TodayDashboardData _decodeToday(List<Object?> json) {
    if (json.length != 1 || json.first is! Map<String, Object?>) {
      throw const FormatException('The daily plan is invalid.');
    }
    final root = json.first! as Map<String, Object?>;
    if (root['format'] != 1) {
      throw const FormatException('The daily plan format is unsupported.');
    }
    List<TodayStepData> steps(String key) {
      final raw = root[key];
      if (raw is! List<Object?>) {
        throw FormatException('$key must be a list.');
      }
      return raw
          .map((item) {
            if (item is! Map<String, Object?>) {
              throw FormatException('$key contains an invalid step.');
            }
            return TodayStepData(
              id: item['id']! as String,
              kind: TodayStepKind.values.byName(item['kind']! as String),
              reason: TodayStepReason.values.byName(item['reason']! as String),
              estimatedSeconds: item['estimatedSeconds']! as int,
              surah: item['surah'] as int?,
              requiresVoice: item['requiresVoice']! as bool,
            );
          })
          .toList(growable: false);
    }

    return TodayDashboardData(
      date: _localDate(_clock.now()),
      approximateMinutes: root['approximateMinutes']! as int,
      steps: steps('steps'),
      extraReview: steps('extraReview'),
      condition: TodayCondition.values.byName(root['condition']! as String),
      inProgress: root['inProgress']! as bool,
    );
  }

  @override
  Future<Result<MoreSettingsData>> loadMoreSettings() => _guard(() async {
    final storage = await _storageService.storage;
    final profile = await _requiredProfile(storage);
    final repeats = await _settingInt(
      storage,
      _memorizationRepeatsKey,
      _config.defaultMemorizationRepeats,
    );
    return MoreSettingsData(profile: profile, memorizationRepeats: repeats);
  });

  @override
  Future<Result<MoreSettingsData>> updateStudySettings({
    required int dailyMinutes,
    required bool strictBehavior,
    required bool showFirstWord,
    required int memorizationRepeats,
  }) => _guard(() async {
    if (dailyMinutes <= 0 || memorizationRepeats <= 0) {
      throw const FormatException('Study settings must be positive.');
    }
    final storage = await _storageService.storage;
    final profiles = _unwrap(await storage.profiles.list());
    if (profiles.isEmpty) throw StateError('The profile is missing.');
    final stored = profiles.first;
    final language = await _language(storage, stored.uiLanguage);
    final changed = (
      id: stored.id,
      createdAt: stored.createdAt,
      uiLanguage: stored.uiLanguage,
      path: stored.path,
      dailyMinutes: dailyMinutes,
      behavior: strictBehavior
          ? ReadingBehavior.strict
          : ReadingBehavior.gentle,
      showFirstWord: showFirstWord,
    );
    _unwrap(await storage.profiles.put(changed));
    await _putSetting(storage, _memorizationRepeatsKey, memorizationRepeats);
    return MoreSettingsData(
      profile: _profile(changed, language),
      memorizationRepeats: memorizationRepeats,
    );
  });

  @override
  Future<Result<AppUserProfile>> updateLanguage(AppLanguage language) =>
      _guard(() async {
        final storage = await _storageService.storage;
        final profiles = _unwrap(await storage.profiles.list());
        if (profiles.isEmpty) throw StateError('The profile is missing.');
        final stored = profiles.first;
        final changed = (
          id: stored.id,
          createdAt: stored.createdAt,
          uiLanguage: _storedLanguage(language),
          path: stored.path,
          dailyMinutes: stored.dailyMinutes,
          behavior: stored.behavior,
          showFirstWord: stored.showFirstWord,
        );
        _unwrap(await storage.profiles.put(changed));
        await _putSetting(storage, _languageKey, language.name);
        return _profile(changed, language);
      });

  @override
  Future<Result<List<AppDownloadData>>> listDownloads() => _guard(() async {
    final storage = await _storageService.storage;
    final downloads = _unwrap(await storage.downloads.list());
    return List<AppDownloadData>.unmodifiable(
      downloads.map(
        (download) => AppDownloadData(
          id: download.packageId,
          kind: download.kind.name,
          bytes: download.bytesDone,
          installed: download.state == DownloadState.installed,
        ),
      ),
    );
  });

  @override
  Future<Result<void>> deleteModels() => _guard(() async {
    await _files.deleteModels();
    final storage = await _storageService.storage;
    final downloads = _unwrap(await storage.downloads.list());
    for (final download in downloads.where(
      (download) => download.kind == DownloadKind.model,
    )) {
      _unwrap(
        await storage.downloads.put((
          packageId: download.packageId,
          kind: download.kind,
          activeVersion: null,
          pendingVersion: null,
          state: DownloadState.pending,
          bytesTotal: 0,
          bytesDone: 0,
          updatedAt: _nowMs,
        )),
      );
    }
  });

  @override
  Future<Result<void>> exportUserData() => _guard(() async {
    final storage = await _storageService.storage;
    final bytes = _unwrap(await storage.exportData());
    await _files.shareUserData(bytes);
  });

  @override
  Future<Result<bool>> importUserData() => _guard(() async {
    final bytes = await _files.pickUserData();
    if (bytes == null) return false;
    final storage = await _storageService.storage;
    _unwrap(await storage.importData(bytes));
    return true;
  });

  @override
  Future<Result<void>> eraseAllUserData() => _guard(() async {
    final storage = await _storageService.storage;
    _unwrap(await storage.eraseAll(_files));
  });

  Future<AppUserProfile> _requiredProfile(StorageService storage) async {
    final profiles = _unwrap(await storage.profiles.list());
    if (profiles.isEmpty) throw StateError('The profile is missing.');
    final stored = profiles.first;
    return _profile(stored, await _language(storage, stored.uiLanguage));
  }

  Future<AppLanguage> _language(
    StorageService storage,
    UiLanguage fallback,
  ) async {
    final setting = _unwrap(await storage.settings.get(_languageKey));
    final value = setting?.value.value;
    if (value is String) {
      return AppLanguage.values.byName(value);
    }
    return switch (fallback) {
      UiLanguage.ru => AppLanguage.ru,
      UiLanguage.kk => AppLanguage.kk,
      UiLanguage.uz => AppLanguage.uz,
    };
  }

  Future<int> _settingInt(
    StorageService storage,
    String key,
    int fallback,
  ) async {
    final setting = _unwrap(await storage.settings.get(key));
    return switch (setting?.value.value) {
      final int value => value,
      _ => fallback,
    };
  }

  Future<void> _putSetting(
    StorageService storage,
    String key,
    Object? value,
  ) async {
    _unwrap(
      await storage.settings.put((
        key: key,
        value: JsonValueData.fromJson(value),
      )),
    );
  }

  AppUserProfile _profile(ProfileData value, AppLanguage language) =>
      AppUserProfile(
        id: value.id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          value.createdAt,
          isUtc: true,
        ),
        language: language,
        path: switch (value.path) {
          LearningPath.read => AppLearningPath.learnReading,
          LearningPath.hifz => AppLearningPath.memorize,
          LearningPath.restore => AppLearningPath.restore,
        },
        dailyMinutes: value.dailyMinutes,
        strictBehavior: value.behavior == ReadingBehavior.strict,
        showFirstWord: value.showFirstWord,
      );

  UiLanguage _storedLanguage(AppLanguage language) => switch (language) {
    AppLanguage.ru || AppLanguage.en => UiLanguage.ru,
    AppLanguage.kk => UiLanguage.kk,
    AppLanguage.uz => UiLanguage.uz,
  };

  LearningPath _storedPath(AppLearningPath path) => switch (path) {
    AppLearningPath.learnReading => LearningPath.read,
    AppLearningPath.memorize => LearningPath.hifz,
    AppLearningPath.restore => LearningPath.restore,
  };

  PlanUnitKind _planUnitKind(UnitKind kind) => switch (kind) {
    UnitKind.passage => PlanUnitKind.passage,
    UnitKind.junction => PlanUnitKind.junction,
    UnitKind.hardSpot => PlanUnitKind.hardSpot,
    UnitKind.skill => PlanUnitKind.skill,
  };

  PlanQueue _planQueue(UnitQueue? queue) => switch (queue) {
    UnitQueue.learning => PlanQueue.learning,
    UnitQueue.recent => PlanQueue.recent,
    UnitQueue.old => PlanQueue.old,
    UnitQueue.notStarted || UnitQueue.closed || null => PlanQueue.notStarted,
  };

  AttemptMode _attemptMode(StoredReadingMode mode) => switch (mode) {
    StoredReadingMode.supported => AttemptMode.supported,
    StoredReadingMode.recall => AttemptMode.recall,
    StoredReadingMode.test => AttemptMode.selfCheck,
    StoredReadingMode.self => AttemptMode.selfReport,
  };

  AttemptResult _attemptResult(AttemptOutcome outcome) => switch (outcome) {
    AttemptOutcome.clean => AttemptResult.clean,
    AttemptOutcome.withHints => AttemptResult.selfCorrected,
    AttemptOutcome.corrected => AttemptResult.selfCorrected,
    AttemptOutcome.withErrors => AttemptResult.confirmedError,
    AttemptOutcome.unverified => AttemptResult.unableToVerify,
    AttemptOutcome.disputed => AttemptResult.disputed,
  };

  VerificationMethod _verification(CheckMethod method) => switch (method) {
    CheckMethod.voice => VerificationMethod.voice,
    CheckMethod.self => VerificationMethod.selfCheck,
    CheckMethod.listener => VerificationMethod.listener,
  };

  PlannerRating _plannerRating(AttemptRating rating) => switch (rating) {
    AttemptRating.again => PlannerRating.again,
    AttemptRating.hard => PlannerRating.hard,
    AttemptRating.good => PlannerRating.good,
    AttemptRating.easy => PlannerRating.easy,
  };

  int get _nowMs => _clock.now().toUtc().millisecondsSinceEpoch;
}

Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
  try {
    return Result<T>.ok(await operation());
  } on Exception catch (error) {
    return Result<T>.error(error);
  }
}

T _unwrap<T>(Result<T> result) => switch (result) {
  Ok<T>(:final value) => value,
  Error<T>(:final error) => throw error,
};

String _localDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

int _minutesFor(List<TodayStepData> steps) {
  final seconds = steps.fold<int>(
    0,
    (sum, step) => sum + step.estimatedSeconds,
  );
  return (seconds / Duration.secondsPerMinute).round();
}
