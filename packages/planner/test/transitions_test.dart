import 'dart:math';

import 'package:planner/planner.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late SimulatedClock clock;
  late PlannerEngine engine;

  setUp(() {
    clock = SimulatedClock(epoch);
    engine = PlannerEngine(
      params: PlannerParams.defaults,
      clock: clock,
      random: Random(1),
    );
  });

  test('unrated attempt keeps card and due unchanged', () {
    final unit = passage(id: 'u', queue: PlanQueue.recent);

    final updated = engine.applyAttempt(
      unit,
      attempt(
        unitId: 'u',
        mode: AttemptMode.supported,
        verification: VerificationMethod.none,
      ),
    );

    expect(updated.due, unit.due);
    expect(updated.card.lastReview, isNull);
    expect(updated.history, hasLength(1));
  });

  test('one clean self-check learns a passage (ZN-02)', () {
    final unit = passage(id: 'u', queue: PlanQueue.learning);

    final updated = engine.applyAttempt(
      unit,
      attempt(
        unitId: 'u',
        mode: AttemptMode.selfCheck,
        verification: VerificationMethod.selfCheck,
      ),
    );

    expect(updated.queue, PlanQueue.recent);
    expect(updated.recentStartedAt, epoch);
    expect(updated.due, epoch.add(const Duration(days: 1)));
    expect(updated.card.lastReview, epoch);
  });

  test('recent becomes old after 30 days and two strong attempts', () {
    final earlier = attempt(
      unitId: 'u',
      at: epoch.add(const Duration(days: 29)),
    );
    final unit = passage(
      id: 'u',
      queue: PlanQueue.recent,
      recentStartedAt: epoch,
      history: [record(attempt: earlier, rating: PlannerRating.good)],
    );
    final at = epoch.add(const Duration(days: 30));

    final updated = engine.applyAttempt(unit, attempt(unitId: 'u', at: at));

    expect(updated.queue, PlanQueue.old);
    expect(updated.card.stability, isNotNull);
    expect(updated.due.isAfter(at), isTrue);
  });

  test('two consecutive Again ratings in old start relearning', () {
    var unit = passage(id: 'u', queue: PlanQueue.old);
    unit = engine.applyAttempt(
      unit,
      attempt(unitId: 'u', result: AttemptResult.confirmedError),
    );
    expect(unit.queue, PlanQueue.old);
    expect(unit.consecutiveForgot, 1);

    final nextDay = epoch.add(const Duration(days: 1));
    unit = engine.applyAttempt(
      unit,
      attempt(
        unitId: 'u',
        at: nextDay,
        result: AttemptResult.confirmedError,
      ),
    );

    expect(unit.queue, PlanQueue.learning);
    expect(unit.acceleratedLearning, isTrue);
    expect(unit.due, nextDay);
  });

  test('hard spot closes after two clean readings a day apart', () {
    var unit = hardSpot(id: 'h');
    unit = engine.applyAttempt(
      unit,
      attempt(unitId: 'h', wordCount: 3),
    );
    expect(unit.hardSpotStage, HardSpotStage.practicing);
    expect(unit.due, epoch.add(const Duration(days: 3)));

    unit = engine.applyAttempt(
      unit,
      attempt(
        unitId: 'h',
        at: epoch.add(const Duration(days: 1)),
        wordCount: 3,
      ),
    );

    expect(unit.hardSpotStage, HardSpotStage.closed);
  });

  test('course skill graduates to FSRS review', () {
    final updated = engine.applyAttempt(
      skill(id: 's'),
      attempt(unitId: 's', wordCount: 1),
    );

    expect(updated.skillStage, SkillStage.review);
    expect(updated.card.lastReview, epoch);
    expect(updated.due.isAfter(epoch), isTrue);
  });
}
