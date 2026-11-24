import 'dart:math';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/planner.dart';
import 'package:storage/storage.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/canon_index.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';
import 'package:sudur/data/repositories/plan_state_codec.dart';
import 'package:sudur/data/services/app_file_service.dart';
import 'package:sudur/data/services/app_planner_service.dart';
import 'package:sudur/data/services/app_storage_service.dart';
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
