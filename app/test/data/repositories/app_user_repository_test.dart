import 'dart:math';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/planner.dart';
import 'package:storage/storage.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/canon_index.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';
import 'package:sudur/data/repositories/plan_state_codec.dart';
import 'package:sudur/data/services/app_file_service.dart';
import 'package:sudur/data/services/app_planner_service.dart';
import 'package:sudur/data/services/app_storage_service.dart';
import 'package:sudur/data/services/notification_service.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_platform_service.dart';

import '../../test_helpers/fixture_canon.dart';

void main() {
  late StorageService storage;
  late SimulatedClock clock;
  late FixtureCanonService canon;
  late StorageAppUserRepository repository;
  late CanonIndex index;
  var nextId = 0;
  String? Function(int)? brokenId;

  setUpAll(() => index = fixtureCanon());

  setUp(() {
    storage = StorageService.memory();
    clock = SimulatedClock(DateTime.utc(2026, 11, 19, 8));
    canon = FixtureCanonService();
    nextId = 0;
    brokenId = null;
    const platform = _FakePlatform();
    repository = StorageAppUserRepository(
      storage: AppStorageService.fromStorage(storage),
      files: const AppFileService(platform),
      modelInstaller: PrototypeAssetInstaller(platform),
      canon: canon,
      planner: AppPlannerService(clock: clock, random: Random(1)),
      clock: clock,
      createId: () {
        final n = nextId++;
        return brokenId?.call(n) ??
            '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
      },
      config: const E01Config(),
    );
  });

  tearDown(() => storage.close());

  OnboardingDraft draft({
    AppLearningPath path = AppLearningPath.restore,
    Set<int> familiar = const {78},
    AppStartPoint? startPoint,
    LetterKnowledge? letters,
  }) => OnboardingDraft(
    step: OnboardingStep.completed,
    language: AppLanguage.en,
    path: path,
    familiarSurahs: familiar,
    dailyMinutes: 10,
    downloadModelNow: false,
    startPoint: startPoint,
    letterKnowledge: letters,
  );

  Future<List<UnitData>> units() async {
    final profile = _value(await storage.profiles.list()).single;
    final list = _value(await storage.units.listForProfile(profile.id));
    return list;
  }

  test('profile, draft, and daily plan survive repository reloads', () async {
    final start = draft();
    expect(await repository.saveOnboardingDraft(start), isA<Ok<void>>());
    expect(
      await repository.completeOnboarding(start),
      isA<Ok<AppUserProfile>>(),
    );
    final first = _value(await repository.loadToday());
    final second = _value(await repository.loadToday());

    expect(second.date, first.date);
    expect(
      second.steps.map((step) => step.id),
      first.steps.map((step) => step.id),
    );
    expect(_value(await repository.loadProfile())?.language, AppLanguage.en);
    expect(
      _value(await repository.loadOnboardingDraft()).familiarSurahs,
      contains(78),
    );
  });

  test(
    'familiar surah 78 becomes its default passages (review of #29)',
    () async {
      _value(await repository.completeOnboarding(draft()));

      final created = await units();
      final passages = index.passagesOf(78);
      expect(created, hasLength(passages.length));
      expect(
        created.map((u) => (u.fromWordIndex, u.toWordIndex)),
        unorderedEquals(passages.map((p) => (p.fromWordIndex, p.toWordIndex))),
      );
      for (final unit in created) {
        expect(unit.kind, UnitKind.passage);
        expect(unit.origin, UnitOrigin.knownBefore);
        expect(unit.surah, 78);
        final state = _value(await storage.units.getState(unit.id));
        expect(state?.queue, UnitQueue.notStarted);
        expect(state?.fsrsCard, isNotNull, reason: 'the card is created once');
      }
      final cardIds = {
        for (final unit in created)
          decodeFsrsCard(
            _value(await storage.units.getState(unit.id))!.fsrsCard!.value,
          ).cardId,
      };
      expect(cardIds, hasLength(created.length), reason: 'card ids are unique');

      final today = _value(await repository.loadToday());
      expect(today.steps.where((s) => s.surah == 78), isNotEmpty);
    },
  );

  test('completing twice does not add the passages again', () async {
    _value(await repository.completeOnboarding(draft()));
    _value(await repository.completeOnboarding(draft()));
    expect(await units(), hasLength(index.passagesOf(78).length));
  });

  test('nothing familiar: the chosen start surah is planned', () async {
    _value(
      await repository.completeOnboarding(
        draft(
          path: AppLearningPath.memorize,
          familiar: const {},
          startPoint: AppStartPoint.firstSurah,
        ),
      ),
    );
    final created = await units();
    expect(created, hasLength(index.passagesOf(1).length));
    expect(created.every((u) => u.surah == 1), isTrue);
    expect(created.every((u) => u.origin == UnitOrigin.defaultOrigin), isTrue);

    final today = _value(await repository.loadToday());
    expect(today.steps, isNotEmpty);
  });

  test('the course keeps the letter answer and gets its entry skill', () async {
    _value(
      await repository.completeOnboarding(
        draft(
          path: AppLearningPath.learnReading,
          familiar: const {},
          letters: LetterKnowledge.aLittle,
        ),
      ),
    );
    final created = await units();
    expect(created.single.kind, UnitKind.skill);
    expect(canon.loads, 0, reason: 'the course needs no text');
    expect(
      _value(await storage.settings.get('letterKnowledge'))?.value.value,
      'aLittle',
    );
  });

  test(
    'no text (offline): nothing is written, the start can be retried',
    () async {
      canon.fail = true;
      final result = await repository.completeOnboarding(draft());
      expect(result, isA<Error<AppUserProfile>>());
      expect(_value(await storage.profiles.list()), isEmpty);
      expect(
        _value(await repository.loadOnboardingDraft()).step,
        isNot(OnboardingStep.completed),
      );

      canon.fail = false;
      expect(
        await repository.completeOnboarding(draft()),
        isA<Ok<AppUserProfile>>(),
      );
    },
  );

  test('a failure in the middle leaves no profile, unit or setting', () async {
    // The fourth id is not a UUID: the unit write fails after the profile
    // and the first units were written.
    brokenId = (n) => n == 3 ? 'broken' : null;
    final result = await repository.completeOnboarding(draft());
    expect(result, isA<Error<AppUserProfile>>());
    expect(_value(await storage.profiles.list()), isEmpty);
    expect(_value(await storage.settings.list()), isEmpty);
  });

  test('the FSRS card is not started again on another day', () async {
    _value(await repository.completeOnboarding(draft()));
    final unit = (await units()).first;
    final before = _value(await storage.units.getState(unit.id))!.fsrsCard;

    _value(await repository.loadToday());
    clock.advance(const Duration(days: 3));
    _value(await repository.loadToday());

    expect(_value(await storage.units.getState(unit.id))!.fsrsCard, before);
  });

  test('a unit stored without a card gets one once', () async {
    _value(await repository.completeOnboarding(draft()));
    final unit = (await units()).first;
    final state = _value(await storage.units.getState(unit.id))!;
    _value(
      await storage.units.putState((
        unitId: state.unitId,
        queue: state.queue,
        memoryState: null,
        fsrsCard: null,
        dueAt: state.dueAt,
        recentSince: null,
        lastAttemptAt: null,
        lastMethod: null,
        updatedAt: state.updatedAt,
      )),
    );

    _value(await repository.loadToday());
    final first = _value(await storage.units.getState(unit.id))!.fsrsCard;
    clock.advance(const Duration(days: 1));
    _value(await repository.loadToday());

    expect(first, isNotNull);
    expect(_value(await storage.units.getState(unit.id))!.fsrsCard, first);
  });

  test('a closed unit is not planned and stays closed', () async {
    _value(await repository.completeOnboarding(draft()));
    for (final unit in await units()) {
      final state = _value(await storage.units.getState(unit.id))!;
      _value(
        await storage.units.putState((
          unitId: state.unitId,
          queue: UnitQueue.closed,
          memoryState: state.memoryState,
          fsrsCard: state.fsrsCard,
          dueAt: state.dueAt,
          recentSince: null,
          lastAttemptAt: null,
          lastMethod: null,
          updatedAt: state.updatedAt,
        )),
      );
    }

    final today = _value(await repository.loadToday());

    expect(today.steps.where((s) => s.surah == 78), isEmpty);
    for (final unit in await units()) {
      expect(
        _value(await storage.units.getState(unit.id))!.queue,
        UnitQueue.closed,
      );
    }
  });

  test(
    'steps carry their words; started and finished steps are saved',
    () async {
      _value(await repository.completeOnboarding(draft()));
      final today = _value(await repository.loadToday());
      final reading = today.steps.where((s) => s.surah == 78).toList();
      expect(reading, isNotEmpty);
      for (final step in reading) {
        expect(step.from?.surah, 78);
        expect(step.to?.surah, 78);
        expect(step.from!.compareTo(step.to!), lessThanOrEqualTo(0));
        // Both checked just above.
      }

      final first = today.steps.first;
      _value(await repository.startToday(first.id));
      expect(_value(await repository.loadToday()).currentStepId, first.id);

      for (final step in today.steps) {
        _value(await repository.finishTodayStep(step.id));
      }
      final done = _value(await repository.loadToday());
      expect(done.steps.every((s) => s.done), isTrue);
      expect(done.condition, TodayCondition.completed);
      expect(done.nextStep, isNull);
      expect(done.inProgress, isFalse);
    },
  );

  test('surah names: none before content is installed', () async {
    expect(_value(await repository.loadSurahNames()), isEmpty);
  });

  ReadingResult reading(
    TodayStepData step, {
    SessionMode mode = SessionMode.test,
    List<CheckEvent> checks = const [],
    Map<HintKind, int> hints = const {},
  }) {
    final words = index.passagesOf(78).first;
    return ReadingResult(
      stepId: step.id,
      from: step.from!,
      to: step.to!,
      // A step of surah 78 carries its words (tested above).
      mode: mode,
      behavior: SessionBehavior.gentle,
      startedAt: clock.now(),
      duration: const Duration(seconds: 30),
      words: [
        for (var i = words.fromWordIndex; i <= words.toWordIndex; i++)
          SessionWordResult(
            wordKey: index.keyOf(i),
            outcome: SessionWordOutcome.read,
          ),
      ],
      hints: hints,
      checks: checks,
      unlocked: const {},
    );
  }

  CheckEvent confirmed(WordKey word) => CheckEvent(
    sessionId: 'session',
    atMs: 10,
    eventId: 'e1',
    kind: CheckKind.substitution,
    state: CheckState.confirmed,
    words: [word],
    expectedText: 'expected-test',
    heardText: 'heard-test',
    audioStartMs: 0,
    audioEndMs: 100,
    versions: const ReadingVersions(
      modelId: 'model',
      modelVersion: '1',
      rulesVersion: 'r',
      textVersion: 't',
    ),
  );

  test('a clean check of a known passage moves its unit to recent', () async {
    _value(await repository.completeOnboarding(draft()));
    final step = _value(await repository.loadToday()).steps
        .firstWhere((s) => s.unitId != null);

    _value(await repository.recordReading(reading(step)));

    final attempts = _value(await storage.attempts.listForUnit(step.unitId!));
    // The step was chosen by its unit id.
    expect(attempts.single.outcome, AttemptOutcome.clean);
    expect(attempts.single.method, CheckMethod.voice);
    final state = _value(await storage.units.getState(step.unitId!))!;
    expect(state.queue, UnitQueue.recent);
    expect(state.lastAttemptAt, isNotNull);
    final profile = _value(await storage.profiles.list()).single;
    expect(
      _value(await storage.sessions.listForProfile(profile.id)),
      hasLength(1),
    );
  });

  test('a confirmed mistake is stored with what was heard', () async {
    _value(await repository.completeOnboarding(draft()));
    final step = _value(await repository.loadToday()).steps
        .firstWhere((s) => s.unitId != null);

    _value(
      await repository.recordReading(
        reading(step, checks: [confirmed(step.from!)]),
      ),
    );

    final attempt = _value(await storage.attempts.listForUnit(step.unitId!))
        .single;
    expect(attempt.outcome, AttemptOutcome.withErrors);
    expect(attempt.errorEventIds.value, hasLength(1));
    final events = _value(
      await storage.checkEvents.listForSession(attempt.sessionId),
    );
    expect(events.single.heardText, 'heard-test');
    expect(events.single.wordIndexes.value, [index.indexOf(step.from!)]);
    expect(
      _value(await storage.units.getState(step.unitId!))!.queue,
      UnitQueue.learning,
      reason: 'a failed recovery check goes back to learning',
    );
  });

  test('I disagree: the event is disputed and the unit is due again', () async {
    _value(await repository.completeOnboarding(draft()));
    final step = _value(await repository.loadToday()).steps
        .firstWhere((s) => s.unitId != null);
    final recorded = _value(
      await repository.recordReading(
        reading(step, checks: [confirmed(step.from!)]),
      ),
    );
    final stored = recorded.eventIds['e1']!;
    // The reading above had event e1.
    clock.advance(const Duration(hours: 1));

    _value(await repository.disputeCheck(stored, unitId: recorded.unitId));

    final event = _value(await storage.checkEvents.get(stored))!;
    // Just written above.
    expect(event.state, CheckState.disputed);
    expect(event.heardText, 'heard-test');
    final state = _value(await storage.units.getState(step.unitId!))!;
    expect(state.dueAt, clock.now().millisecondsSinceEpoch);
  });

  for (final (answer, rating) in [
    (SelfCheckAnswer.remembered, AttemptRating.good),
    (SelfCheckAnswer.withDifficulty, AttemptRating.hard),
    (SelfCheckAnswer.forgotten, AttemptRating.again),
  ]) {
    test(
      'self-check ${answer.name} is rated ${rating.name} (3.4, СП-02)',
      () async {
        _value(await repository.completeOnboarding(draft()));
        final step = _value(await repository.loadToday()).steps
            .firstWhere((s) => s.unitId != null);

        _value(
          await repository.recordSelfCheck(
            SelfCheckResult(
              stepId: step.id,
              from: step.from!,
              to: step.to!,
              // A step of surah 78 carries its words.
              answer: answer,
              startedAt: clock.now(),
              duration: const Duration(seconds: 20),
            ),
          ),
        );

        final attempt = _value(await storage.attempts.listForUnit(step.unitId!))
            .single;
        expect(attempt.mode, StoredReadingMode.self);
        expect(attempt.method, CheckMethod.self);
        expect(attempt.rating, rating);
        expect(
          _value(await storage.units.getState(step.unitId!))!.lastMethod,
          CheckMethod.self,
        );
      },
    );
  }

  test('reading with support gives no rating', () async {
    _value(await repository.completeOnboarding(draft()));
    final step = _value(await repository.loadToday()).steps
        .firstWhere((s) => s.unitId != null);

    _value(
      await repository.recordReading(
        reading(step, mode: SessionMode.supported),
      ),
    );

    final attempt = _value(await storage.attempts.listForUnit(step.unitId!))
        .single;
    expect(attempt.mode, StoredReadingMode.supported);
    expect(attempt.rating, isNull);
  });

  test('ЗН-01, ЗН-03: steps of a new passage; the second one adds the '
      'junction and both in a row; progress is kept (ЗН-04)', () async {
    _value(
      await repository.completeOnboarding(
        draft(
          path: AppLearningPath.memorize,
          familiar: const {},
          startPoint: AppStartPoint.firstSurah,
        ),
      ),
    );
    final today = _value(await repository.loadToday());
    final step = today.steps.firstWhere((s) => s.unitId != null);
    final plan = _value(await repository.learnPlan(step.id));
    expect(plan.steps.map((s) => s.kind), [
      LearnStepKind.listen,
      LearnStepKind.listen,
      LearnStepKind.listen,
      LearnStepKind.supported,
      LearnStepKind.supported,
      LearnStepKind.recall,
      LearnStepKind.test,
      if (plan.from !=
          index.keyOf(index.passagesOf(1).first.fromWordIndex)) ...[
        LearnStepKind.junction,
        LearnStepKind.combined,
      ],
    ]);

    _value(await repository.saveLearnProgress(plan.unitId, 5));
    expect(_value(await repository.learnPlan(step.id)).startIndex, 5);
  });

  test('«Ещё»: listening and reading with the text are two settings that '
      'the steps of a new passage follow', () async {
    _value(
      await repository.completeOnboarding(
        draft(
          path: AppLearningPath.memorize,
          familiar: const {},
          startPoint: AppStartPoint.firstSurah,
        ),
      ),
    );
    final defaults = _value(await repository.loadMoreSettings());
    expect((defaults.listenRepeats, defaults.supportedRepeats), (3, 2));
    _value(
      await repository.updateStudySettings(
        dailyMinutes: 10,
        strictBehavior: false,
        showFirstWord: true,
        listenRepeats: 1,
        supportedRepeats: 4,
      ),
    );
    final stored = _value(await repository.loadMoreSettings());
    expect((stored.listenRepeats, stored.supportedRepeats), (1, 4));
    final today = _value(await repository.loadToday());
    final step = today.steps.firstWhere((s) => s.unitId != null);
    final kinds = _value(await repository.learnPlan(step.id)).steps
        .map((s) => s.kind)
        .toList();
    expect(kinds.where((k) => k == LearnStepKind.listen), hasLength(1));
    expect(kinds.where((k) => k == LearnStepKind.supported), hasLength(4));
  });

  test(
    'ЗН-05: after the last short surah is learned, the next one comes',
    () async {
      _value(
        await repository.completeOnboarding(
          draft(
            path: AppLearningPath.memorize,
            familiar: const {},
            startPoint: AppStartPoint.shortSurahs,
          ),
        ),
      );
      for (final unit in await units()) {
        final state = _value(await storage.units.getState(unit.id))!;
        _value(
          await storage.units.putState((
            unitId: state.unitId,
            queue: UnitQueue.recent,
            memoryState: state.memoryState,
            fsrsCard: state.fsrsCard,
            dueAt: state.dueAt,
            recentSince: state.updatedAt,
            lastAttemptAt: state.updatedAt,
            lastMethod: CheckMethod.voice,
            updatedAt: state.updatedAt,
          )),
        );
      }

      _value(await repository.loadToday());

      expect((await units()).map((u) => u.surah).toSet(), {114, 113});
    },
  );

  test(
    'КП-01: memory states of passages follow the conditions of 11.1',
    () async {
      _value(await repository.completeOnboarding(draft()));
      var progress = _value(await repository.loadProgress());
      expect(progress.single.surah, 78);
      expect(
        progress.single.passages.every(
          (p) => p.status == MemoryStatus.notStarted,
        ),
        isTrue,
      );
      final today = _value(await repository.loadToday());
      final step = today.steps.firstWhere((s) => s.unitId != null);
      MemoryStatus status() => progress.single.passages
          .firstWhere((p) => p.unitId == step.unitId)
          .status;

      _value(
        await repository.recordReading(
          reading(step, mode: SessionMode.supported),
        ),
      );
      progress = _value(await repository.loadProgress());
      expect(status(), MemoryStatus.introduced);

      _value(
        await repository.recordReading(
          reading(step, hints: const {HintKind.word: 1}),
        ),
      );
      progress = _value(await repository.loadProgress());
      expect(status(), MemoryStatus.withHelp);

      _value(await repository.recordReading(reading(step)));
      progress = _value(await repository.loadProgress());
      expect(status(), MemoryStatus.independent);
      expect(
        progress.single.passages
            .firstWhere((p) => p.unitId == step.unitId)
            .lastMethod,
        LastCheckMethod.voice,
      );

      clock.advance(const Duration(days: 2));
      // A second clean check two days later, written as stored data: which
      // day the plan offers it again is the planner's business.
      final unitId = step.unitId;
      if (unitId == null) fail('the step has a unit');
      final last = _value(await storage.attempts.listForUnit(unitId)).last;
      _value(
        await storage.attempts.add((
          id: '00000000-0000-4000-8000-777777777777',
          unitId: last.unitId,
          sessionId: last.sessionId,
          mode: last.mode,
          outcome: AttemptOutcome.clean,
          hints: last.hints,
          errorEventIds: last.errorEventIds,
          rating: last.rating,
          method: last.method,
          durationMs: last.durationMs,
          words: last.words,
          modelId: last.modelId,
          modelVersion: last.modelVersion,
          rulesVersion: last.rulesVersion,
          textVersion: last.textVersion,
          createdAt: clock.now().millisecondsSinceEpoch,
        )),
      );
      progress = _value(await repository.loadProgress());
      expect(status(), MemoryStatus.confirmed);

      clock.advance(const Duration(days: 60));
      progress = _value(await repository.loadProgress());
      expect(status(), MemoryStatus.stale);
    },
  );

  test('reminders: at most two, in order, minutes of a day only', () async {
    _value(await repository.completeOnboarding(draft()));
    expect(_value(await repository.saveReminders([1200, 300, 600, -5])), [
      300,
      600,
    ]);
    expect(_value(await repository.loadReminders()), [300, 600]);
  });

  test('11.8: reminders are scheduled for the next days in the interface '
      'language, and none today once today is done', () async {
    final notifications = _RecordingNotifications();
    const platform = _FakePlatform();
    final withReminders = StorageAppUserRepository(
      storage: AppStorageService.fromStorage(storage),
      files: const AppFileService(platform),
      modelInstaller: PrototypeAssetInstaller(platform),
      canon: canon,
      planner: AppPlannerService(clock: clock, random: Random(1)),
      clock: clock,
      createId: () =>
          '00000000-0000-4000-8000-${(nextId++).toString().padLeft(12, '0')}',
      config: const E01Config(),
      notifications: notifications,
      reminderText: (language, minutes) =>
          ReminderText(body: '${language.name} $minutes', channel: 'c'),
    );
    _value(await withReminders.completeOnboarding(draft()));
    final now = clock.now().toLocal();
    final early = now.hour * 60 + now.minute - 60;
    final late = now.hour * 60 + now.minute + 60;
    _value(await withReminders.saveReminders([late, early]));
    expect(notifications.text?.body, 'en 10');
    expect(notifications.at, hasLength(2 * 14 - 1));
    expect(notifications.at.first.day, now.day);

    final today = _value(await withReminders.loadToday());
    for (final step in today.steps) {
      _value(await withReminders.finishTodayStep(step.id));
    }
    expect(notifications.at, hasLength(2 * 13));
    expect(notifications.at.every((m) => m.day != now.day), isTrue);

    _value(await withReminders.saveReminders(const []));
    expect(notifications.at, isEmpty);
  });

  test('reminder moments: only ahead, none today when done', () {
    final now = DateTime(2026, 11, 19, 12);
    expect(
      reminderMoments([60, 13 * 60], now: now, todayDone: false, days: 2),
      [
        DateTime(2026, 11, 19, 13),
        DateTime(2026, 11, 20, 1),
        DateTime(2026, 11, 20, 13),
      ],
    );
    expect(reminderMoments([13 * 60], now: now, todayDone: true, days: 2), [
      DateTime(2026, 11, 20, 13),
    ]);
  });

  test('planner state survives its JSON', () {
    final at = DateTime.utc(2026, 11, 20, 9);
    const memory = PlanMemoryState(
      hardSpotStage: HardSpotStage.practicing,
      recentReviewIndex: 2,
      consecutiveForgot: 1,
      acceleratedLearning: true,
    );
    final back = PlanMemoryState.fromJson(memory.toJson());
    expect(back.hardSpotStage, HardSpotStage.practicing);
    expect(back.recentReviewIndex, 2);
    expect(back.consecutiveForgot, 1);
    expect(back.acceleratedLearning, isTrue);

    final card = FsrsCardSnapshot(
      cardId: 7,
      stage: FsrsStage.review,
      due: at,
      stability: 3.5,
      difficulty: 6,
      lastReview: at,
    );
    final cardBack = decodeFsrsCard(encodeFsrsCard(card));
    expect(cardBack.cardId, 7);
    expect(cardBack.stage, FsrsStage.review);
    expect(cardBack.stability, 3.5);
    expect(cardBack.due, at);
    expect(cardBack.lastReview, at);
  });
}

T _value<T>(Result<T> result) => switch (result) {
  Ok<T>(:final value) => value,
  Error<T>(:final error) => throw error,
};

final class _FakePlatform implements PrototypePlatformService {
  const new();

  @override
  Future<String> applicationDirectory() async => '/tmp/sudur-e01-test';

  @override
  Future<String?> pickUserDataArchive() async => null;

  @override
  Future<String?> pickWavFile() async => null;

  @override
  Future<void> shareFile(String path) async {}
}

final class _RecordingNotifications implements NotificationService {
  List<DateTime> at = const [];
  ReminderText? text;

  @override
  Future<Result<bool>> requestPermission() async => const Result.ok(true);

  @override
  Future<Result<void>> scheduleAt(List<DateTime> at, ReminderText text) async {
    this.at = at;
    this.text = text;
    return const Result.ok(null);
  }
}
