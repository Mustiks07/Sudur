import 'dart:math';

import 'package:contracts/contracts.dart';
import 'package:planner/planner.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late PlannerEngine engine;

  setUp(() {
    engine = PlannerEngine(
      params: PlannerParams.defaults,
      clock: SimulatedClock(epoch),
      random: Random(4),
    );
  });

  test('planner models defensively copy input collections', () {
    final goalIds = <String>{'goal'};
    final history = <AttemptRecord>[];
    final unit = passage(id: 'immutable', goalIds: goalIds, history: history);
    final orderedIds = <String>['immutable'];
    final goal = PlanGoal(id: 'goal', unitIds: orderedIds);
    final request = TodayPlanRequest(
      units: [unit],
      goals: [goal],
      budgetSeconds: 60,
    );

    goalIds.add('other');
    history.add(record(attempt: attempt(unitId: 'immutable')));
    orderedIds.add('other');

    expect(unit.goalIds, {'goal'});
    expect(unit.history, isEmpty);
    expect(goal.unitIds, ['immutable']);
    expect(() => request.units.add(unit), throwsUnsupportedError);
  });

  test('learning sequence uses configured repetitions', () {
    final unit = passage(id: 'u', queue: PlanQueue.learning);

    final sequence = learningSequence(unit, PlannerParams.defaults);

    expect(
      sequence.where((step) => step.kind == LearningActionKind.listen),
      hasLength(3),
    );
    expect(
      sequence.where((step) => step.kind == LearningActionKind.supportedRead),
      hasLength(2),
    );
    expect(sequence[sequence.length - 2].kind, LearningActionKind.tryRecall);
    expect(sequence.last.kind, LearningActionKind.selfCheck);
  });

  test('accelerated recovery starts directly with recall', () {
    final unit = passage(
      id: 'u',
      queue: PlanQueue.learning,
      acceleratedLearning: true,
    );

    final sequence = learningSequence(unit, PlannerParams.defaults);

    expect(sequence.map((step) => step.kind), [
      LearningActionKind.tryRecall,
      LearningActionKind.selfCheck,
    ]);
  });

  test('second passage adds junction and combined reading', () {
    final actions = afterLearningSequence(
      passage(id: 'u', previousUnitId: 'previous'),
    );

    expect(actions.map((step) => step.kind), [
      LearningActionKind.junction,
      LearningActionKind.combinedPassages,
    ]);
  });

  test('default new order starts from the end of the Quran', () {
    final ordered = orderNewUnits(
      [
        passage(id: 's78'),
        passage(id: 's114', surah: 114),
        passage(id: 's112', surah: 112),
      ],
      const [],
    );

    expect(ordered.map((unit) => unit.id), ['s114', 's112', 's78']);
  });

  test('simple recovery samples 2–3 passages', () {
    final units = [
      for (var index = 0; index < 8; index++) passage(id: 'u$index'),
    ];

    final sample = engine.recoverySample(units);

    expect(sample.length, inInclusiveRange(2, 3));
    expect(sample.map((unit) => unit.id).toSet().length, sample.length);
  });

  test('recovery clean goes recent; error uses accelerated learning', () {
    final known = engine.markKnownBefore(passage(id: 'u'));
    final clean = engine.applyRecoveryCheck(
      known,
      attempt(
        unitId: 'u',
        mode: AttemptMode.selfCheck,
        verification: VerificationMethod.selfCheck,
      ),
    );
    final failed = engine.applyRecoveryCheck(
      engine.markKnownBefore(passage(id: 'v')),
      attempt(
        unitId: 'v',
        mode: AttemptMode.selfCheck,
        result: AttemptResult.confirmedError,
        verification: VerificationMethod.selfCheck,
      ),
    );

    expect(clean.queue, PlanQueue.recent);
    expect(failed.queue, PlanQueue.learning);
    expect(failed.acceleratedLearning, isTrue);
  });

  group('memory map', () {
    test('listening and supported attempts derive their states', () {
      final listening = passage(
        id: 'l',
        history: [
          record(
            attempt: attempt(unitId: 'l', mode: AttemptMode.listening),
          ),
        ],
      );
      final supported = passage(
        id: 's',
        history: [
          record(
            attempt: attempt(unitId: 's', mode: AttemptMode.supported),
          ),
        ],
      );

      expect(_memory(listening), MemoryState.acquainted);
      expect(_memory(supported), MemoryState.supported);
    });

    test('two clean interval attempts derive confirmedLater', () {
      final unit = passage(
        id: 'u',
        history: [
          record(attempt: attempt(unitId: 'u', at: epoch)),
          record(
            attempt: attempt(
              unitId: 'u',
              at: epoch.add(const Duration(days: 1)),
            ),
          ),
        ],
      );

      expect(_memory(unit), MemoryState.confirmedLater);
    });

    test('open hard spot overrides other memory states', () {
      final unit = passage(id: 'u').copyWith(hasOpenHardSpot: true);

      expect(_memory(unit), MemoryState.hasHardSpot);
    });

    test('overdue reviewed unit is long unchecked', () {
      final reviewed = FsrsCardSnapshot(
        cardId: 1,
        stage: FsrsStage.review,
        due: epoch,
        stability: 1,
        difficulty: 5,
        lastReview: epoch.subtract(const Duration(days: 10)),
      );
      final unit = passage(id: 'u', card: reviewed, due: epoch);

      expect(
        memoryStateFor(
          unit,
          now: epoch.add(const Duration(days: 8)),
          retrievability: 0.9,
          params: PlannerParams.defaults,
        ),
        MemoryState.longUnchecked,
      );
    });
  });

  test('range over 2.5 passages creates two attempts (PL-12)', () {
    final units = [
      passage(id: 'u1', toWord: 3, wordCount: 3),
      passage(id: 'u2', ayah: 2, toWord: 3, wordCount: 3),
      passage(id: 'u3', ayah: 3, toWord: 4, wordCount: 4),
    ];
    const session = PassageRange(
      from: WordKey(78, 1, 1),
      to: WordKey(78, 3, 2),
      wordCount: 8,
    );

    final attempts = attemptsForCompletedUnits(
      sessionRange: session,
      units: units,
      at: epoch,
      mode: AttemptMode.recall,
      result: AttemptResult.clean,
      hints: 0,
      verification: VerificationMethod.voice,
      duration: const Duration(seconds: 80),
    );

    expect(attempts.map((attempt) => attempt.unitId), ['u1', 'u2']);
    expect(attempts.every((attempt) => attempt.wordCount == 3), isTrue);
  });
}

MemoryState _memory(PlanUnit unit) => memoryStateFor(
      unit,
      now: epoch,
      retrievability: 1,
      params: PlannerParams.defaults,
    );
