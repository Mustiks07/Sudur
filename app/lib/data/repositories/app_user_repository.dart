import 'dart:convert';
import 'dart:io';

// The explicit constructor names keep this storage adapter easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor
// ignore_for_file: prefer_initializing_formals

import 'package:contracts/contracts.dart';
import 'package:planner/planner.dart';
import 'package:storage/storage.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/canon_index.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/plan_state_codec.dart';
import 'package:sudur/data/services/app_canon_service.dart';
import 'package:sudur/data/services/app_file_service.dart';
import 'package:sudur/data/services/app_planner_service.dart';
import 'package:sudur/data/services/app_storage_service.dart';
import 'package:sudur/data/services/notification_service.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';

/// Creates UUID v4 identifiers without exposing the implementation to data UI.
typedef AppIdFactory = String Function();

/// User, onboarding, daily-plan, and settings persistence boundary.
abstract interface class AppUserRepository {
  /// Loads the single V1 profile.
  Future<Result<AppUserProfile?>> loadProfile();

  /// Loads the resumable onboarding draft.
  Future<Result<OnboardingDraft>> loadOnboardingDraft();

  /// Surah names from the installed content package, by number; empty
  /// before content is installed.
  Future<Result<Map<int, SurahNameData>>> loadSurahNames();

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

  /// Writes one reading: the session, its check events, the attempt and the
  /// new state of the step's plan unit, in one transaction (НФ-21, ПЛ-12).
  Future<Result<RecordedReading>> recordReading(ReadingResult result);

  /// Reminder times, minutes after midnight (11.8); empty when off.
  Future<Result<List<int>>> loadReminders();

  /// Stores reminder times (at most `maxRemindersPerDay`).
  Future<Result<List<int>>> saveReminders(List<int> minutesOfDay);

  /// Memory state of every surah in the plan (13.12, КП-01…04).
  Future<Result<List<SurahProgress>>> loadProgress();

  /// The learning plan of the passage of [stepId] (ЗН-01…04).
  Future<Result<LearnPlan>> learnPlan(String stepId);

  /// Remembers that learning of [unitId] reached [stepIndex] (ЗН-04).
  Future<Result<void>> saveLearnProgress(String unitId, int stepIndex);

  /// Writes a self-check (СП-01…03): the session, the attempt marked
  /// “self-check” and the new unit state; never rated above «хорошо».
  Future<Result<void>> recordSelfCheck(SelfCheckResult result);

  /// «Не согласен» (РБ-03): the stored event [eventId] becomes disputed and
  /// [unitId], if given, needs a new check (it is due now).
  Future<Result<void>> disputeCheck(String eventId, {String? unitId});

  /// Marks [stepId] finished; when every step is finished the day is done.
  Future<Result<TodayDashboardData>> finishTodayStep(String stepId);

  /// Removes one step for today without changing future scheduling.
  Future<Result<TodayDashboardData>> skipTodayStep(String stepId);

  /// Loads settings for the “More” screen.
  Future<Result<MoreSettingsData>> loadMoreSettings();

  /// Updates profile-backed study settings.
  Future<Result<MoreSettingsData>> updateStudySettings({
    required int dailyMinutes,
    required bool strictBehavior,
    required bool showFirstWord,
    required int listenRepeats,
    required int supportedRepeats,
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
    required AppCanonService canon,
    required AppPlannerService planner,
    required Clock clock,
    required AppIdFactory createId,
    required E01Config config,
    NotificationService notifications = const NoNotificationService(),
    ReminderText Function(AppLanguage language, int minutes)? reminderText,
  }) : _storageService = storage,
       _files = files,
       _modelInstaller = modelInstaller,
       _canon = canon,
       _planner = planner,
       _clock = clock,
       _createId = createId,
       _config = config,
       _notifications = notifications,
       _reminderText = reminderText;

  static const _draftKey = 'onboardingDraft';
  static const _languageKey = 'appLanguage';
  static const _selectedSurahsKey = 'selectedSurahs';
  static const _startPointKey = 'startPoint';
  static const _modelDeferredKey = 'modelDeferred';
  static const _listenRepeatsKey = 'learnListenRepeats';
  static const _supportedRepeatsKey = 'learnSupportedRepeats';
  static const _letterKnowledgeKey = 'letterKnowledge';
  static const _nextCardIdKey = 'nextFsrsCardId';
  static const _courseEntrySkill = 'course-entry';
  static const _learnProgressKey = 'learnProgress:';
  static const _remindersKey = 'reminders';

  final AppStorageService _storageService;
  final AppFileService _files;
  final PrototypeAssetInstaller _modelInstaller;
  final AppCanonService _canon;
  final AppPlannerService _planner;
  final Clock _clock;
  final AppIdFactory _createId;
  final E01Config _config;
  final NotificationService _notifications;
  final ReminderText Function(AppLanguage language, int minutes)? _reminderText;

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
  Future<Result<Map<int, SurahNameData>>> loadSurahNames() => _guard(() async {
    final path = await _modelInstaller.installedContentPath();
    if (path == null) return const <int, SurahNameData>{};
    final root = jsonDecode(await File(path).readAsString());
    final surahs = root is Map<String, Object?> ? root['surahs'] : null;
    if (surahs is! List<Object?>) {
      throw const FormatException('The content has no surah list.');
    }
    String? text(Map<String, Object?> json, String key) => switch (json[key]) {
      final String value when value.trim().isNotEmpty => value,
      _ => null,
    };
    return {
      for (final entry in surahs)
        if (entry
            case {'number': final int number} &&
                final Map<String, Object?> json)
          number: SurahNameData(
            number: number,
            arabic: text(json, 'nameAr'),
            russian: text(json, 'nameRu'),
            kazakh: text(json, 'nameKk'),
            uzbek: text(json, 'nameUz'),
          ),
    };
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
        final surahs = _plannedSurahs(draft, path);
        // The text is installed (network) before anything is written, so a
        // failure leaves the start where it was.
        final canon = surahs.isEmpty ? null : await _canon.load();
        final storage = await _storageService.storage;
        final completed = await storage.transaction(() async {
          final existing = _unwrap(await storage.profiles.list());
          final id = existing.isEmpty ? _createId() : existing.first.id;
          final createdAt = existing.isEmpty
              ? _nowMs
              : existing.first.createdAt;
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
            _letterKnowledgeKey,
            draft.letterKnowledge?.name,
          );
          await _putSetting(
            storage,
            _modelDeferredKey,
            draft.downloadModelNow == false,
          );
          if (path == AppLearningPath.learnReading) {
            await _ensureCourseUnit(storage, id);
          }
          if (canon != null) {
            for (final (surah, origin) in surahs) {
              await _ensurePassageUnits(storage, canon, id, surah, origin);
            }
          }
          // Last: the start counts as finished only with everything above.
          _unwrap(
            await storage.settings.put((
              key: _draftKey,
              value: JsonValueData.fromJson(
                draft.copyWith(step: OnboardingStep.completed).toJson(),
              ),
            )),
          );
          return profile;
        });
        return _profile(_unwrap(completed), language);
      });

  /// Surahs whose passages become plan units (docs/tz 3.4, 13.1): the
  /// familiar ones, or — when nothing is familiar — the chosen start.
  List<(int, UnitOrigin)> _plannedSurahs(
    OnboardingDraft draft,
    AppLearningPath path,
  ) {
    if (path == AppLearningPath.learnReading) return const [];
    if (draft.familiarSurahs.isNotEmpty) {
      return [
        for (final surah in draft.familiarSurahs.toList()..sort())
          (surah, UnitOrigin.knownBefore),
      ];
    }
    return switch (draft.startPoint) {
      AppStartPoint.firstSurah => [
        (_config.firstSurah, UnitOrigin.defaultOrigin),
      ],
      AppStartPoint.shortSurahs => [
        (_config.firstShortSurah, UnitOrigin.defaultOrigin),
      ],
      null => const [],
    };
  }

  Future<void> _ensurePassageUnits(
    StorageService storage,
    CanonIndex canon,
    String profileId,
    int surah,
    UnitOrigin origin,
  ) async {
    final existing = {
      for (final unit in _unwrap(await storage.units.listForProfile(profileId)))
        if (unit.kind == UnitKind.passage)
          (unit.fromWordIndex, unit.toWordIndex),
    };
    for (final passage in canon.passagesOf(surah)) {
      if (existing.contains((passage.fromWordIndex, passage.toWordIndex))) {
        continue;
      }
      await _putNewUnit(
        storage,
        id: _createId(),
        profileId: profileId,
        kind: UnitKind.passage,
        fromWordIndex: passage.fromWordIndex,
        toWordIndex: passage.toWordIndex,
        skillId: null,
        surah: surah,
        origin: origin,
      );
    }
  }

  Future<void> _ensureCourseUnit(
    StorageService storage,
    String profileId,
  ) async {
    final units = _unwrap(await storage.units.listForProfile(profileId));
    if (units.any((unit) => unit.skillId == _courseEntrySkill)) return;
    await _putNewUnit(
      storage,
      id: _createId(),
      profileId: profileId,
      kind: UnitKind.skill,
      fromWordIndex: null,
      toWordIndex: null,
      skillId: _courseEntrySkill,
      surah: null,
      origin: UnitOrigin.lesson,
    );
  }

  /// Writes a unit with its first state: queue “not started”, due now, and
  /// its FSRS card created once here (the plan never starts it again).
  Future<void> _putNewUnit(
    StorageService storage, {
    required String id,
    required String profileId,
    required UnitKind kind,
    required int? fromWordIndex,
    required int? toWordIndex,
    required String? skillId,
    required int? surah,
    required UnitOrigin origin,
  }) async {
    final now = _clock.now().toUtc();
    _unwrap(
      await storage.units.putUnit((
        id: id,
        profileId: profileId,
        kind: kind,
        fromWordIndex: fromWordIndex,
        toWordIndex: toWordIndex,
        skillId: skillId,
        surah: surah,
        origin: origin,
        parentUnitId: null,
        createdAt: now.millisecondsSinceEpoch,
      )),
    );
    final card = FsrsCardSnapshot.initial(
      cardId: await _nextCardId(storage),
      now: now,
    );
    _unwrap(
      await storage.units.putState((
        unitId: id,
        queue: UnitQueue.notStarted,
        memoryState: JsonObjectData.fromJson(
          PlanMemoryState(
            skillStage: kind == UnitKind.skill ? SkillStage.learning : null,
            hardSpotStage: kind == UnitKind.hardSpot
                ? HardSpotStage.open
                : null,
          ).toJson(),
        ),
        fsrsCard: JsonObjectData.fromJson(encodeFsrsCard(card)),
        dueAt: now.millisecondsSinceEpoch,
        recentSince: null,
        lastAttemptAt: null,
        lastMethod: null,
        updatedAt: now.millisecondsSinceEpoch,
      )),
    );
  }

  /// A new FSRS card id, unique for this user.
  Future<int> _nextCardId(StorageService storage) async {
    final id = await _settingInt(storage, _nextCardIdKey, 1);
    await _putSetting(storage, _nextCardIdKey, id + 1);
    return id;
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
    await _syncReminders(storage);
    return await _withCurrentLimitState(storage, plan);
  });

  @override
  Future<Result<TodayDashboardData>> startToday(String stepId) =>
      _changeToday((plan) {
        if (!plan.steps.any((step) => step.id == stepId) &&
            !plan.extraReview.any((step) => step.id == stepId)) {
          throw const FormatException('The selected step is not in today.');
        }
        return _copyPlan(plan, inProgress: true, currentStepId: stepId);
      });

  @override
  Future<Result<RecordedReading>> recordReading(ReadingResult result) =>
      _guard(() async {
        final canon = await _canon.load();
        final storage = await _storageService.storage;
        final profile = await _requiredProfile(storage);
        final unitId = result.stepId == null
            ? null
            : await _unitOfStep(storage, result.stepId!);
        // stepId is checked in the condition just above.
        final now = _clock.now().toUtc();
        final sessionId = _createId();
        final versions = result.checks.isEmpty
            ? null
            : result.checks.first.versions;
        final storedIds = <String, String>{
          for (final check in result.checks) check.eventId: _createId(),
        };
        final eventIds = storedIds.values.toList();
        final events = <CheckEventData>[
          for (final check in result.checks)
            (
              // Every check has an id in the map built just above.
              id: storedIds[check.eventId]!,
              sessionId: sessionId,
              kind: check.kind,
              state: check.state,
              wordIndexes: WordIndexes.fromJson([
                for (final word in check.words) canon.indexOf(word),
              ]),
              expectedText: check.expectedText,
              heardText: check.heardText,
              jumpFromWordIndex: check.kind == CheckKind.jump
                  ? canon.indexOf(check.words.first)
                  : null,
              jumpToWordIndex: switch (check.jumpTo) {
                final WordKey to => canon.indexOf(to),
                null => null,
              },
              audioStartMs: check.audioStartMs,
              audioEndMs: check.audioEndMs,
              versions: check.versions,
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
            ),
        ];
        final outcome = _outcome(result);
        final storedMode = switch (result.mode) {
          SessionMode.supported => StoredReadingMode.supported,
          SessionMode.recall => StoredReadingMode.recall,
          SessionMode.test => StoredReadingMode.test,
        };
        final hints = result.hints.values.fold(0, (sum, n) => sum + n);
        final written = await storage.transaction(() async {
          _unwrap(
            await storage.sessions.put((
              id: sessionId,
              profileId: profile.id,
              fromWordIndex: canon.indexOf(result.from),
              toWordIndex: canon.indexOf(result.to),
              mode: storedMode,
              behavior: result.behavior == SessionBehavior.strict
                  ? ReadingBehavior.strict
                  : ReadingBehavior.gentle,
              startedAt: result.startedAt.toUtc().millisecondsSinceEpoch,
              endedAt: now.millisecondsSinceEpoch,
              listeningMs: result.duration.inMilliseconds,
              signalOkRatio: null,
              summary: SessionSummary.fromJson({
                'words': result.words.length,
                'unlocked': result.unlocked.length,
                'outcome': outcome.name,
              }),
            )),
          );
          if (unitId == null) {
            for (final event in events) {
              _unwrap(await storage.checkEvents.put(event));
            }
            return;
          }
          final unit = _unwrap(await storage.units.listForProfile(profile.id))
              .firstWhere((u) => u.id == unitId);
          final state = _unwrap(await storage.units.getState(unitId));
          final attempts = _unwrap(await storage.attempts.listForUnit(unitId));
          final before = await _plannerUnit(
            storage,
            canon,
            unit,
            state,
            attempts,
          );
          final attempt = Attempt(
            unitId: unitId,
            at: now,
            mode: _attemptMode(storedMode),
            result: _attemptResult(outcome),
            hints: hints,
            verification: VerificationMethod.voice,
            duration: result.duration,
            wordCount: result.words.isEmpty ? 1 : result.words.length,
          );
          final after = _planner.applyReading(before, attempt);
          final rating = after.history.last.assessment.rating;
          _unwrap(
            await storage.attempts.recordPassage(
              PassageWrite(
                attempt: (
                  id: _createId(),
                  unitId: unitId,
                  sessionId: sessionId,
                  mode: storedMode,
                  outcome: outcome,
                  hints: HintCounts.fromJson({
                    for (final MapEntry(:key, :value) in result.hints.entries)
                      key.name: value,
                  }),
                  errorEventIds: ErrorEventIds.fromJson(eventIds),
                  rating: rating == null ? null : _storedRating(rating),
                  method: CheckMethod.voice,
                  durationMs: result.duration.inMilliseconds,
                  words: result.words.length,
                  modelId: versions?.modelId ?? 'unknown',
                  modelVersion: versions?.modelVersion ?? 'unknown',
                  rulesVersion: versions?.rulesVersion ?? 'unknown',
                  textVersion: versions?.textVersion ?? 'unknown',
                  createdAt: now.millisecondsSinceEpoch,
                ),
                checkEvents: events,
                unitState: (
                  unitId: unitId,
                  queue: _storedQueue(after),
                  memoryState: JsonObjectData.fromJson(
                    PlanMemoryState.of(after).toJson(),
                  ),
                  fsrsCard: JsonObjectData.fromJson(encodeFsrsCard(after.card)),
                  dueAt: after.due.toUtc().millisecondsSinceEpoch,
                  recentSince: after.recentStartedAt?.millisecondsSinceEpoch,
                  lastAttemptAt: now.millisecondsSinceEpoch,
                  lastMethod: CheckMethod.voice,
                  updatedAt: now.millisecondsSinceEpoch,
                ),
              ),
            ),
          );
        });
        _unwrap(written);
        return RecordedReading(
          sessionId: sessionId,
          eventIds: storedIds,
          unitId: unitId,
        );
      });

  @override
  Future<Result<List<int>>> loadReminders() => _guard(() async {
    final storage = await _storageService.storage;
    return await _storedReminders(storage);
  });

  Future<List<int>> _storedReminders(StorageService storage) async {
    final value = _unwrap(await storage.settings.get(_remindersKey))
        ?.value
        .value;
    return switch (value) {
      final List<Object?> list => [...list.whereType<int>()],
      _ => const <int>[],
    };
  }

  @override
  Future<Result<List<int>>> saveReminders(List<int> minutesOfDay) =>
      _guard(() async {
        final valid = [
          for (final m in minutesOfDay)
            if (m >= 0 && m < Duration.minutesPerDay) m,
        ];
        final times = remindersOfDay(
          valid,
          maxPerDay: _config.maxRemindersPerDay,
        );
        final storage = await _storageService.storage;
        await _putSetting(storage, _remindersKey, times);
        await _syncReminders(storage);
        return times;
      });

  /// Schedules the reminders of the next days again (11.8): the stored
  /// times, none today when today's session is done, in the interface
  /// language; none without a profile.
  Future<void> _syncReminders(StorageService storage) async {
    final textOf = _reminderText;
    if (textOf == null) return;
    final profiles = _unwrap(await storage.profiles.list());
    final now = _clock.now();
    var moments = const <DateTime>[];
    var text = const ReminderText(body: '', channel: '');
    if (profiles.isNotEmpty) {
      final stored = profiles.first;
      final saved = _unwrap(await storage.dailyPlans.get(_localDate(now)));
      final todayDone =
          saved != null &&
          _decodeToday(saved.items.toJson()).condition ==
              TodayCondition.completed;
      moments = reminderMoments(
        await _storedReminders(storage),
        now: now,
        todayDone: todayDone,
        days: _config.reminderDaysAhead,
      );
      text = textOf(
        await _language(storage, stored.uiLanguage),
        stored.dailyMinutes,
      );
    }
    // A reminder the phone refuses must not fail the plan or the settings;
    // the next sync tries again.
    await _notifications.scheduleAt(moments, text);
  }

  @override
  Future<Result<List<SurahProgress>>> loadProgress() => _guard(() async {
    final storage = await _storageService.storage;
    final profile = await _requiredProfile(storage);
    final units = _unwrap(await storage.units.listForProfile(profile.id));
    if (units.isEmpty) return const <SurahProgress>[];
    final canon = await _canon.load();
    final now = _clock.now().toUtc();
    final openSpots = <UnitData>[];
    for (final unit in units.where((u) => u.kind == UnitKind.hardSpot)) {
      final state = _unwrap(await storage.units.getState(unit.id));
      final memory = PlanMemoryState.fromJson(state?.memoryState?.value);
      if (state?.queue != UnitQueue.closed &&
          memory.hardSpotStage != HardSpotStage.closed) {
        openSpots.add(unit);
      }
    }
    final bySurah = <int, List<PassageProgress>>{};
    for (final unit in units.where((u) => u.kind == UnitKind.passage)) {
      final from = unit.fromWordIndex;
      final to = unit.toWordIndex;
      final surah = unit.surah;
      if (from == null || to == null || surah == null) continue;
      final state = _unwrap(await storage.units.getState(unit.id));
      final attempts = _unwrap(await storage.attempts.listForUnit(unit.id));
      final spots = openSpots
          .where(
            (s) =>
                s.parentUnitId == unit.id ||
                ((s.fromWordIndex ?? 0) <= to && from <= (s.toWordIndex ?? 0)),
          )
          .length;
      final planned = await _plannerUnit(storage, canon, unit, state, attempts);
      final last = attempts.isEmpty ? null : attempts.last;
      bySurah
          .putIfAbsent(surah, () => [])
          .add(
            PassageProgress(
              unitId: unit.id,
              from: canon.keyOf(from),
              to: canon.keyOf(to),
              status: _memoryStatus(attempts, state, planned, spots, now),
              hints: attempts.fold(
                0,
                (n, a) => n + a.hints.value.values.fold(0, (m, v) => m + v),
              ),
              hardSpots: spots,
              lastCheckAt: last == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      last.createdAt,
                      isUtc: true,
                    ),
              lastMethod: switch (last?.method) {
                CheckMethod.voice => LastCheckMethod.voice,
                CheckMethod.self => LastCheckMethod.self,
                CheckMethod.listener => LastCheckMethod.listener,
                null => null,
              },
            ),
          );
    }
    return [
      for (final MapEntry(:key, :value)
          in (bySurah.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        SurahProgress(
          surah: key,
          passages: value..sort((a, b) => a.from.compareTo(b.from)),
        ),
    ];
  });

  /// КП-01 by the conditions of 11.1.
  MemoryStatus _memoryStatus(
    List<AttemptData> attempts,
    UnitStateData? state,
    PlanUnit planned,
    int hardSpots,
    DateTime now,
  ) {
    if (hardSpots > 0) return MemoryStatus.hardSpot;
    if (attempts.isEmpty) return MemoryStatus.notStarted;
    final checks = attempts
        .where((a) => a.mode != StoredReadingMode.supported)
        .toList();
    if (checks.isEmpty) return MemoryStatus.introduced;
    final due = state?.dueAt;
    final overdue =
        due != null &&
        now
                .difference(
                  DateTime.fromMillisecondsSinceEpoch(due, isUtc: true),
                )
                .inDays >
            _planner.staleAfterDays;
    final retrievability = _planner.retrievability(planned);
    if (overdue ||
        (planned.card.lastReview != null &&
            retrievability < _planner.staleRecallBelow)) {
      return MemoryStatus.stale;
    }
    final last = checks.last;
    if (last.outcome != AttemptOutcome.clean) return MemoryStatus.withHelp;
    final clean = checks.where((a) => a.outcome == AttemptOutcome.clean);
    final apart = clean.any(
      (a) =>
          last.createdAt - a.createdAt >=
          Duration.millisecondsPerDay * _planner.confirmedLaterMinDays,
    );
    return apart ? MemoryStatus.confirmed : MemoryStatus.independent;
  }

  @override
  Future<Result<LearnPlan>> learnPlan(String stepId) => _guard(() async {
    final canon = await _canon.load();
    final storage = await _storageService.storage;
    final profile = await _requiredProfile(storage);
    final unitId = await _unitOfStep(storage, stepId);
    if (unitId == null) throw const FormatException('The step has no passage.');
    final units = _unwrap(await storage.units.listForProfile(profile.id));
    final unit = units.firstWhere((u) => u.id == unitId);
    final from = unit.fromWordIndex;
    final to = unit.toWordIndex;
    if (from == null || to == null) {
      throw const FormatException('No words to learn.');
    }
    final first = canon.keyOf(from);
    final last = canon.keyOf(to);
    final repeats = await _learnRepeats(storage);
    final steps = <LearnStep>[
      for (var i = 0; i < repeats.listen; i++)
        LearnStep(kind: LearnStepKind.listen, from: first, to: last),
      for (var i = 0; i < repeats.supported; i++)
        LearnStep(kind: LearnStepKind.supported, from: first, to: last),
      LearnStep(kind: LearnStepKind.recall, from: first, to: last),
      LearnStep(kind: LearnStepKind.test, from: first, to: last),
    ];
    // ЗН-03: from the second passage of a surah on, the junction with the
    // previous passage, then both in a row.
    final previousStart = units
        .where(
          (u) =>
              u.kind == UnitKind.passage &&
              u.surah == unit.surah &&
              u.toWordIndex == from - 1,
        )
        .firstOrNull
        ?.fromWordIndex;
    if (previousStart != null) {
      final junction = _planner.learnJunctionWords;
      steps
        ..add(
          LearnStep(
            kind: LearnStepKind.junction,
            from: canon.keyOf(_maxInt(from - junction, previousStart)),
            to: canon.keyOf(_minInt(from + junction - 1, to)),
          ),
        )
        ..add(
          LearnStep(
            kind: LearnStepKind.combined,
            from: canon.keyOf(previousStart),
            to: last,
          ),
        );
    }
    final saved = await _settingInt(storage, '$_learnProgressKey$unitId', 0);
    return LearnPlan(
      unitId: unitId,
      from: first,
      to: last,
      steps: steps,
      startIndex: saved.clamp(0, steps.length - 1),
    );
  });

  /// ЗН-01 repetitions set under «Ещё»; the planner parameters by default.
  Future<({int listen, int supported})> _learnRepeats(
    StorageService storage,
  ) async {
    final defaults = _planner.learningRepeats;
    return (
      listen: await _settingInt(storage, _listenRepeatsKey, defaults.listen),
      supported: await _settingInt(
        storage,
        _supportedRepeatsKey,
        defaults.supported,
      ),
    );
  }

  @override
  Future<Result<void>> saveLearnProgress(String unitId, int stepIndex) =>
      _guard(() async {
        final storage = await _storageService.storage;
        await _putSetting(storage, '$_learnProgressKey$unitId', stepIndex);
      });

  @override
  Future<Result<void>> recordSelfCheck(
    SelfCheckResult result,
  ) => _guard(() async {
    final canon = await _canon.load();
    final storage = await _storageService.storage;
    final profile = await _requiredProfile(storage);
    final stepId = result.stepId;
    final unitId = stepId == null ? null : await _unitOfStep(storage, stepId);
    final now = _clock.now().toUtc();
    final sessionId = _createId();
    final (outcome, planned) = switch (result.answer) {
      SelfCheckAnswer.remembered => (
        AttemptOutcome.clean,
        AttemptResult.remembered,
      ),
      SelfCheckAnswer.withDifficulty => (
        AttemptOutcome.withHints,
        AttemptResult.rememberedWithDifficulty,
      ),
      SelfCheckAnswer.forgotten => (
        AttemptOutcome.withErrors,
        AttemptResult.forgotten,
      ),
    };
    final words = canon.indexOf(result.to) - canon.indexOf(result.from) + 1;
    final written = await storage.transaction(() async {
      _unwrap(
        await storage.sessions.put((
          id: sessionId,
          profileId: profile.id,
          fromWordIndex: canon.indexOf(result.from),
          toWordIndex: canon.indexOf(result.to),
          mode: StoredReadingMode.self,
          behavior: ReadingBehavior.gentle,
          startedAt: result.startedAt.toUtc().millisecondsSinceEpoch,
          endedAt: now.millisecondsSinceEpoch,
          listeningMs: 0,
          signalOkRatio: null,
          summary: SessionSummary.fromJson({'selfCheck': result.answer.name}),
        )),
      );
      if (unitId == null) return;
      final unit = _unwrap(await storage.units.listForProfile(profile.id))
          .firstWhere((u) => u.id == unitId);
      final state = _unwrap(await storage.units.getState(unitId));
      final attempts = _unwrap(await storage.attempts.listForUnit(unitId));
      final before = await _plannerUnit(storage, canon, unit, state, attempts);
      final after = _planner.applyReading(
        before,
        Attempt(
          unitId: unitId,
          at: now,
          mode: AttemptMode.selfReport,
          result: planned,
          hints: 0,
          verification: VerificationMethod.selfCheck,
          duration: result.duration,
          wordCount: words,
        ),
      );
      final rating = after.history.last.assessment.rating;
      _unwrap(
        await storage.attempts.recordPassage(
          PassageWrite(
            attempt: (
              id: _createId(),
              unitId: unitId,
              sessionId: sessionId,
              mode: StoredReadingMode.self,
              outcome: outcome,
              hints: HintCounts.fromJson(const <String, int>{}),
              errorEventIds: ErrorEventIds.fromJson(const <String>[]),
              rating: rating == null ? null : _storedRating(rating),
              method: CheckMethod.self,
              durationMs: result.duration.inMilliseconds,
              words: words,
              modelId: 'self-check',
              modelVersion: 'none',
              rulesVersion: 'tz-3.4',
              textVersion: 'canon',
              createdAt: now.millisecondsSinceEpoch,
            ),
            checkEvents: const [],
            unitState: (
              unitId: unitId,
              queue: _storedQueue(after),
              memoryState: JsonObjectData.fromJson(
                PlanMemoryState.of(after).toJson(),
              ),
              fsrsCard: JsonObjectData.fromJson(encodeFsrsCard(after.card)),
              dueAt: after.due.toUtc().millisecondsSinceEpoch,
              recentSince: after.recentStartedAt?.millisecondsSinceEpoch,
              lastAttemptAt: now.millisecondsSinceEpoch,
              lastMethod: CheckMethod.self,
              updatedAt: now.millisecondsSinceEpoch,
            ),
          ),
        ),
      );
    });
    _unwrap(written);
  });

  @override
  Future<Result<void>> disputeCheck(String eventId, {String? unitId}) =>
      _guard(() async {
        final storage = await _storageService.storage;
        final now = _nowMs;
        final done = await storage.transaction(() async {
          final event = _unwrap(await storage.checkEvents.get(eventId));
          if (event == null) throw StateError('No check event $eventId.');
          _unwrap(
            await storage.checkEvents.put((
              id: event.id,
              sessionId: event.sessionId,
              kind: event.kind,
              state: CheckState.disputed,
              wordIndexes: event.wordIndexes,
              expectedText: event.expectedText,
              heardText: event.heardText,
              jumpFromWordIndex: event.jumpFromWordIndex,
              jumpToWordIndex: event.jumpToWordIndex,
              audioStartMs: event.audioStartMs,
              audioEndMs: event.audioEndMs,
              versions: event.versions,
              createdAt: event.createdAt,
              updatedAt: now,
            )),
          );
          if (unitId == null) return;
          final state = _unwrap(await storage.units.getState(unitId));
          if (state == null) return;
          _unwrap(
            await storage.units.putState((
              unitId: state.unitId,
              queue: state.queue == UnitQueue.closed
                  ? UnitQueue.learning
                  : state.queue,
              memoryState: state.memoryState,
              fsrsCard: state.fsrsCard,
              dueAt: now,
              recentSince: state.recentSince,
              lastAttemptAt: state.lastAttemptAt,
              lastMethod: state.lastMethod,
              updatedAt: now,
            )),
          );
        });
        _unwrap(done);
      });

  Future<String?> _unitOfStep(StorageService storage, String stepId) async {
    final saved = _unwrap(
      await storage.dailyPlans.get(_localDate(_clock.now())),
    );
    if (saved == null) return null;
    final plan = _decodeToday(saved.items.toJson());
    for (final step in [...plan.steps, ...plan.extraReview]) {
      if (step.id == stepId) return step.unitId;
    }
    return null;
  }

  /// Outcome of the attempt (docs/tz 3.4): a confirmed mistake beats a
  /// correction, which beats a hint; words that could not be checked or
  /// were not read make it “unverified”.
  AttemptOutcome _outcome(ReadingResult result) {
    bool any(CheckState state) =>
        result.checks.any((c) => c.state == state && _isMistake(c.kind));
    if (any(CheckState.confirmed)) return AttemptOutcome.withErrors;
    if (any(CheckState.corrected)) return AttemptOutcome.corrected;
    if (result.hints.values.any((n) => n > 0)) return AttemptOutcome.withHints;
    final unverified =
        result.unlocked.isNotEmpty ||
        result.words.isEmpty ||
        result.words.any(
          (w) =>
              w.outcome == SessionWordOutcome.unverified ||
              w.outcome == SessionWordOutcome.notRead,
        );
    return unverified ? AttemptOutcome.unverified : AttemptOutcome.clean;
  }

  static bool _isMistake(CheckKind kind) =>
      kind != CheckKind.repetition && kind != CheckKind.hesitation;

  UnitQueue _storedQueue(PlanUnit unit) {
    if (unit.hardSpotStage == HardSpotStage.closed) return UnitQueue.closed;
    return switch (unit.queue) {
      PlanQueue.notStarted => UnitQueue.notStarted,
      PlanQueue.learning => UnitQueue.learning,
      PlanQueue.recent => UnitQueue.recent,
      PlanQueue.old => UnitQueue.old,
    };
  }

  /// A stored self-check outcome as the planner's self-report result.
  AttemptResult _selfResult(AttemptOutcome outcome) => switch (outcome) {
    AttemptOutcome.clean => AttemptResult.remembered,
    AttemptOutcome.withHints => AttemptResult.rememberedWithDifficulty,
    AttemptOutcome.withErrors => AttemptResult.forgotten,
    _ => _attemptResult(outcome),
  };

  AttemptRating _storedRating(PlannerRating rating) => switch (rating) {
    PlannerRating.again => AttemptRating.again,
    PlannerRating.hard => AttemptRating.hard,
    PlannerRating.good => AttemptRating.good,
    PlannerRating.easy => AttemptRating.easy,
  };

  @override
  Future<Result<TodayDashboardData>> finishTodayStep(String stepId) =>
      _changeToday((plan) {
        final inSteps = plan.steps.any((step) => step.id == stepId);
        final inExtra = plan.extraReview.any((step) => step.id == stepId);
        if (!inSteps && !inExtra) {
          throw const FormatException('The finished step is not in today.');
        }
        List<TodayStepData> mark(List<TodayStepData> steps) => [
          for (final step in steps)
            if (step.id == stepId) step.withDone(done: true) else step,
        ];
        final steps = mark(plan.steps);
        final allDone = steps.every((step) => step.done);
        return _copyPlan(
          plan,
          steps: steps,
          extraReview: mark(plan.extraReview),
          condition: allDone ? TodayCondition.completed : plan.condition,
          inProgress: !allDone,
          currentStepId: null,
        );
      });

  @override
  Future<Result<TodayDashboardData>> skipTodayStep(String stepId) =>
      _changeToday((plan) {
        final remaining = plan.steps
            .where((step) => step.id != stepId)
            .toList(growable: false);
        final allDone = remaining.every((step) => step.done);
        return _copyPlan(
          plan,
          approximateMinutes: _minutesFor(remaining),
          steps: remaining,
          condition: allDone ? TodayCondition.completed : plan.condition,
          currentStepId: plan.currentStepId == stepId
              ? null
              : plan.currentStepId,
        );
      });

  TodayDashboardData _copyPlan(
    TodayDashboardData plan, {
    int? approximateMinutes,
    List<TodayStepData>? steps,
    List<TodayStepData>? extraReview,
    TodayCondition? condition,
    bool? inProgress,
    Object? currentStepId = _keep,
  }) => TodayDashboardData(
    date: plan.date,
    approximateMinutes: approximateMinutes ?? plan.approximateMinutes,
    steps: steps ?? plan.steps,
    extraReview: extraReview ?? plan.extraReview,
    condition: condition ?? plan.condition,
    inProgress: inProgress ?? plan.inProgress,
    currentStepId: identical(currentStepId, _keep)
        ? plan.currentStepId
        : currentStepId as String?,
  );

  Future<Result<TodayDashboardData>> _changeToday(
    TodayDashboardData Function(TodayDashboardData plan) change,
  ) => _guard(() async {
    final storage = await _storageService.storage;
    final date = _localDate(_clock.now());
    final saved = _unwrap(await storage.dailyPlans.get(date));
    if (saved == null) throw const FormatException('Today has no plan.');
    final changed = change(_decodeToday(saved.items.toJson()));
    await _saveToday(storage, changed);
    await _syncReminders(storage);
    return await _withCurrentLimitState(storage, changed);
  });

  Future<TodayDashboardData> _createToday(
    StorageService storage,
    AppUserProfile profile,
    String date,
  ) async {
    var storedUnits = _unwrap(await storage.units.listForProfile(profile.id));
    final canon = storedUnits.any((unit) => unit.fromWordIndex != null)
        ? await _canon.load()
        : null;
    if (canon != null &&
        await _addNextSurah(storage, canon, profile, storedUnits)) {
      storedUnits = _unwrap(await storage.units.listForProfile(profile.id));
    }
    final units = <PlanUnit>[];
    for (final unit in storedUnits) {
      final state = _unwrap(await storage.units.getState(unit.id));
      // A closed unit (docs/tz 3.4) is not planned any more.
      if (state?.queue == UnitQueue.closed) continue;
      final attempts = _unwrap(await storage.attempts.listForUnit(unit.id));
      units.add(await _plannerUnit(storage, canon, unit, state, attempts));
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
        .map((step) => _todayStep(step, storedUnits, canon))
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
          .map((step) => _todayStep(step, storedUnits, canon))
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

  /// ЗН-05, СТ-09: when every passage of the chosen start is learned, the
  /// next surah is added — short surahs go from the end of the Quran to
  /// its start (114 → 78); after Al-Fatiha they begin with 114.
  Future<bool> _addNextSurah(
    StorageService storage,
    CanonIndex canon,
    AppUserProfile profile,
    List<UnitData> units,
  ) async {
    if (profile.path == AppLearningPath.learnReading) return false;
    final own = [
      for (final u in units)
        if (u.kind == UnitKind.passage &&
            u.origin == UnitOrigin.defaultOrigin &&
            u.surah != null)
          u,
    ];
    if (own.isEmpty) return false;
    for (final unit in own) {
      final queue = _unwrap(await storage.units.getState(unit.id))?.queue;
      if (queue == null ||
          queue == UnitQueue.notStarted ||
          queue == UnitQueue.learning) {
        return false;
      }
    }
    final started = {...own.map((u) => u.surah).whereType<int>()};
    final shorts = started.where((s) => s >= _config.lastShortSurah);
    final next = shorts.contains(_config.firstShortSurah)
        ? shorts.reduce((a, b) => a < b ? a : b) - 1
        : _config.firstShortSurah;
    if (next < _config.lastShortSurah || started.contains(next)) return false;
    final added = await storage.transaction(() async {
      await _ensurePassageUnits(
        storage,
        canon,
        profile.id,
        next,
        UnitOrigin.defaultOrigin,
      );
    });
    _unwrap(added);
    return true;
  }

  /// The planner's view of a stored unit: its range in the canon, its FSRS
  /// card and stages as stored (docs/tz 3.4, 12.1).
  Future<PlanUnit> _plannerUnit(
    StorageService storage,
    CanonIndex? canon,
    UnitData unit,
    UnitStateData? state,
    List<AttemptData> attempts,
  ) async {
    final now = _clock.now().toUtc();
    final due = state?.dueAt == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(state!.dueAt!, isUtc: true);
    final memory = PlanMemoryState.fromJson(state?.memoryState?.value);
    final card = switch (state?.fsrsCard) {
      final JsonObjectData stored => decodeFsrsCard(stored.value),
      // Written by an earlier version without a card: created once now.
      null => await _storeInitialCard(storage, unit, state, now),
    };
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
            result: attempt.mode == StoredReadingMode.self
                ? _selfResult(attempt.outcome)
                : _attemptResult(attempt.outcome),
            hints: attempt.hints.value.values.fold(
              0,
              (sum, value) => sum + value,
            ),
            verification: _verification(attempt.method),
            duration: Duration(milliseconds: attempt.durationMs),
            wordCount: attempt.words == 0 ? 1 : attempt.words,
          ),
          assessment: switch (attempt.rating) {
            null => const AttemptAssessment(
              noRatingReason: NoRatingReason.notAssessable,
            ),
            final AttemptRating rating => AttemptAssessment(
              rating: _plannerRating(rating),
            ),
          },
        ),
    ];
    return PlanUnit(
      id: unit.id,
      kind: _planUnitKind(unit.kind),
      range: _range(canon, unit),
      queue: _planQueue(state?.queue),
      hardSpotStage: unit.kind == UnitKind.hardSpot
          ? memory.hardSpotStage ?? HardSpotStage.open
          : null,
      skillStage: unit.kind == UnitKind.skill
          ? memory.skillStage ?? SkillStage.learning
          : null,
      card: card,
      due: due,
      recentStartedAt: memory.recentStartedAt,
      learningStartedAt: memory.learningStartedAt,
      recentReviewIndex: memory.recentReviewIndex,
      consecutiveForgot: memory.consecutiveForgot,
      hardSpotCleanAt: memory.hardSpotCleanAt,
      acceleratedLearning: memory.acceleratedLearning,
      history: history,
      knownBefore: unit.origin == UnitOrigin.knownBefore,
      priorErrorCount: attempts
          .where((attempt) => attempt.outcome == AttemptOutcome.withErrors)
          .length,
    );
  }

  /// The words of [unit] as keys of the canon. A skill has no words: the
  /// planner gets the first word of the Quran, which it does not read.
  PassageRange _range(CanonIndex? canon, UnitData unit) {
    final from = unit.fromWordIndex;
    final to = unit.toWordIndex ?? from;
    if (canon == null || from == null || to == null) {
      if (unit.kind != UnitKind.skill) {
        throw FormatException('Unit ${unit.id} has no words.');
      }
      const first = WordKey(1, 1, 1);
      return const PassageRange(from: first, to: first, wordCount: 1);
    }
    return PassageRange(
      from: canon.keyOf(from),
      to: canon.keyOf(to),
      wordCount: to - from + 1,
    );
  }

  Future<FsrsCardSnapshot> _storeInitialCard(
    StorageService storage,
    UnitData unit,
    UnitStateData? state,
    DateTime now,
  ) async {
    final card = FsrsCardSnapshot.initial(
      cardId: await _nextCardId(storage),
      now: now,
    );
    _unwrap(
      await storage.units.putState((
        unitId: unit.id,
        queue: state?.queue ?? UnitQueue.notStarted,
        memoryState: state?.memoryState,
        fsrsCard: JsonObjectData.fromJson(encodeFsrsCard(card)),
        dueAt: state?.dueAt ?? now.millisecondsSinceEpoch,
        recentSince: state?.recentSince,
        lastAttemptAt: state?.lastAttemptAt,
        lastMethod: state?.lastMethod,
        updatedAt: now.millisecondsSinceEpoch,
      )),
    );
    return card;
  }

  TodayStepData _todayStep(
    PlanStep step,
    List<UnitData> units,
    CanonIndex? canon,
  ) {
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
      unitId: unit?.id,
      from: _keyOf(canon, unit?.fromWordIndex),
      to: _keyOf(canon, unit?.toWordIndex ?? unit?.fromWordIndex),
      requiresVoice:
          kind == TodayStepKind.diagnostic ||
          kind == TodayStepKind.passage ||
          kind == TodayStepKind.hardSpot,
    );
  }

  WordKey? _keyOf(CanonIndex? canon, int? wordIndex) =>
      canon == null || wordIndex == null ? null : canon.keyOf(wordIndex);

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
            unitId: step.unitId,
            from: step.from,
            to: step.to,
            requiresVoice: step.requiresVoice,
            selfCheck: step.requiresVoice && (freeLimitReached || modelMissing),
            done: step.done,
          ),
      ],
      extraReview: plan.extraReview,
      condition: condition,
      inProgress: plan.inProgress,
      currentStepId: plan.currentStepId,
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
      'currentStepId': plan.currentStepId,
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
    'unitId': step.unitId,
    'from': step.from?.toString(),
    'to': step.to?.toString(),
    'requiresVoice': step.requiresVoice,
    'done': step.done,
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
              unitId: item['unitId'] as String?,
              from: _wordKeyOrNull(item['from']),
              to: _wordKeyOrNull(item['to']),
              requiresVoice: item['requiresVoice']! as bool,
              // Plans saved before steps could be finished have no `done`.
              done: item['done'] as bool? ?? false,
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
      currentStepId: root['currentStepId'] as String?,
    );
  }

  @override
  Future<Result<MoreSettingsData>> loadMoreSettings() => _guard(() async {
    final storage = await _storageService.storage;
    final profile = await _requiredProfile(storage);
    final repeats = await _learnRepeats(storage);
    return MoreSettingsData(
      profile: profile,
      listenRepeats: repeats.listen,
      supportedRepeats: repeats.supported,
    );
  });

  @override
  Future<Result<MoreSettingsData>> updateStudySettings({
    required int dailyMinutes,
    required bool strictBehavior,
    required bool showFirstWord,
    required int listenRepeats,
    required int supportedRepeats,
  }) => _guard(() async {
    if (dailyMinutes <= 0 || listenRepeats <= 0 || supportedRepeats <= 0) {
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
    await _putSetting(storage, _listenRepeatsKey, listenRepeats);
    await _putSetting(storage, _supportedRepeatsKey, supportedRepeats);
    await _syncReminders(storage);
    return MoreSettingsData(
      profile: _profile(changed, language),
      listenRepeats: listenRepeats,
      supportedRepeats: supportedRepeats,
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
        await _syncReminders(storage);
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
      // “Not installed” is the absence of a row (docs/tz 11.4).
      _unwrap(await storage.downloads.remove(download.packageId));
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
    await _syncReminders(storage);
    return true;
  });

  @override
  Future<Result<void>> eraseAllUserData() => _guard(() async {
    final storage = await _storageService.storage;
    _unwrap(await storage.eraseAll(_files));
    await _syncReminders(storage);
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

  /// Closed units never reach here (see `_createToday`).
  PlanQueue _planQueue(UnitQueue? queue) => switch (queue) {
    UnitQueue.learning => PlanQueue.learning,
    UnitQueue.recent => PlanQueue.recent,
    UnitQueue.old => PlanQueue.old,
    UnitQueue.notStarted || null => PlanQueue.notStarted,
    UnitQueue.closed => throw StateError('A closed unit is not planned.'),
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

const Object _keep = Object();

int _maxInt(int a, int b) => a > b ? a : b;
int _minInt(int a, int b) => a < b ? a : b;

WordKey? _wordKeyOrNull(Object? value) => switch (value) {
  null => null,
  final String key => WordKey.parse(key),
  _ => throw const FormatException('A word key must be a string.'),
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
