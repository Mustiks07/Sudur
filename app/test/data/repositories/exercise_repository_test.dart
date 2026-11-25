import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/planner.dart';
import 'package:storage/storage.dart';
import 'package:sudur/data/repositories/exercise_repository.dart';
import 'package:sudur/data/services/app_storage_service.dart';

import '../../test_helpers/fixture_canon.dart';

const _versions = ReadingVersions(
  modelId: 'm',
  modelVersion: '1',
  rulesVersion: 'r',
  textVersion: 't',
);

CheckEvent _event(
  CheckKind kind,
  WordKey word, {
  CheckState state = CheckState.confirmed,
}) => CheckEvent(
  sessionId: 's',
  atMs: 0,
  eventId: 'e',
  kind: kind,
  state: state,
  words: [word],
  expectedText: 'expected-test',
  heardText: 'heard-test',
  audioStartMs: 0,
  audioEndMs: 0,
  versions: _versions,
);

void main() {
  late StorageService storage;
  late LocalExerciseRepository repository;
  late SimulatedClock clock;
  final index = fixtureCanon();
  var nextId = 0;

  setUp(() {
    storage = StorageService.memory();
    clock = SimulatedClock(DateTime.utc(2026, 11, 25, 8));
    repository = LocalExerciseRepository(
      canon: FixtureCanonService(),
      storage: AppStorageService.fromStorage(storage),
      clock: clock,
      createId: () =>
          '00000000-0000-4000-8000-${(nextId++).toString().padLeft(12, '0')}',
    );
  });

  tearDown(() => storage.close());

  T value<T>(Result<T> result) => switch (result) {
    Ok<T>(:final value) => value,
    Error<T>(:final error) => throw error,
  };

  test(
    'a substitution: the place inside its ayah, then the whole ayah',
    () async {
      final plan = value(
        await repository.plan(
          _event(CheckKind.substitution, const WordKey(78, 3, 2)),
        ),
      );
      expect(plan.kind, ExerciseKind.hardPassage);
      final ayah = index.ayahsOf(78)[2];
      final place = plan.steps.first;
      expect(
        place.from,
        const WordKey(78, 3, 1),
        reason: 'clipped to the ayah',
      );
      expect(index.indexOf(place.to), lessThanOrEqualTo(ayah.lastWordIndex));
      expect(plan.steps.last.mode, ExerciseReadMode.test);
      expect(plan.steps.last.from, const WordKey(78, 3, 1));
      expect(index.indexOf(plan.steps.last.to), ayah.lastWordIndex);
    },
  );

  test(
    'a missed ayah start: the junction of the two ayahs, three times',
    () async {
      final plan = value(
        await repository.plan(
          _event(CheckKind.omission, const WordKey(78, 5, 1)),
        ),
      );
      expect(plan.kind, ExerciseKind.transition);
      expect(plan.steps, hasLength(PlannerParams.defaults.junctionRepeats));
      final junction = plan.steps.first;
      expect(junction.from.ayah, 4);
      expect(junction.to.ayah, 5);
      expect(junction.to.word, PlannerParams.defaults.junctionWords);
    },
  );

  test('could not check: read once more', () async {
    final plan = value(
      await repository.plan(
        _event(
          CheckKind.substitution,
          const WordKey(78, 3, 2),
          state: CheckState.unverified,
        ),
      ),
    );
    expect(plan.kind, ExerciseKind.rereadOrSelfCheck);
    expect(plan.steps, hasLength(1));
  });

  test('not clean: the place becomes a hard spot due tomorrow', () async {
    value(
      await storage.profiles.put((
        id: '00000000-0000-4000-8000-999999999999',
        createdAt: 0,
        uiLanguage: UiLanguage.ru,
        path: LearningPath.hifz,
        dailyMinutes: 10,
        behavior: ReadingBehavior.gentle,
        showFirstWord: true,
      )),
    );
    final plan = value(
      await repository.plan(
        _event(CheckKind.substitution, const WordKey(78, 3, 2)),
      ),
    );

    value(await repository.finish(plan: plan, closed: true));
    expect(
      value(
        await storage.units.listForProfile(
          '00000000-0000-4000-8000-999999999999',
        ),
      ),
      isEmpty,
    );

    value(await repository.finish(plan: plan, closed: false));
    value(await repository.finish(plan: plan, closed: false));
    final units = value(
      await storage.units.listForProfile(
        '00000000-0000-4000-8000-999999999999',
      ),
    );
    expect(units.single.kind, UnitKind.hardSpot, reason: 'one spot, not two');
    expect(units.single.origin, UnitOrigin.error);
    final state = value(await storage.units.getState(units.single.id))!;
    // Written just above.
    expect(
      state.dueAt,
      clock.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
    );
  });
}
