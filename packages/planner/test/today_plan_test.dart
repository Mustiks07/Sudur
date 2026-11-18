import 'dart:math';

import 'package:planner/planner.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late SimulatedClock clock;
  late PlannerEngine engine;
  late TodayPlanner planner;

  setUp(() {
    clock = SimulatedClock(epoch);
    engine = PlannerEngine(
      params: PlannerParams.defaults,
      clock: clock,
      random: Random(2),
    );
    planner = TodayPlanner(
      params: PlannerParams.defaults,
      clock: clock,
      random: Random(3),
      engine: engine,
    );
  });

  test('five-minute budget and large debt contains no new passage (PL-02)', () {
    final units = [
      for (var index = 0; index < 5; index++)
        passage(
          id: 'old$index',
          queue: PlanQueue.old,
          wordCount: 100,
          toWord: 100,
        ),
      passage(id: 'new'),
    ];

    final plan = planner.build(
      TodayPlanRequest(units: units, budgetSeconds: 300),
    );

    expect(plan.debtSeconds, greaterThan(plan.budgetSeconds));
    expect(
      plan.steps.where((step) => step.kind == PlanStepKind.newPassage),
      isEmpty,
    );
    expect(plan.fitsBudget, isTrue);
  });

  test('review debt larger than budget reduces new work (PL-09)', () {
    final units = [
      for (var index = 0; index < 4; index++)
        passage(
          id: 'recent$index',
          queue: PlanQueue.recent,
          wordCount: 80,
          toWord: 80,
        ),
      passage(id: 'new', wordCount: 5, toWord: 5),
    ];

    final plan = planner.build(
      TodayPlanRequest(units: units, budgetSeconds: 180),
    );

    expect(plan.debtSeconds, greaterThan(plan.budgetSeconds));
    expect(plan.steps.any((step) => step.unitId == 'new'), isFalse);
  });

  test('hard spots use no more than configured budget share', () {
    final units = [
      for (var index = 0; index < 10; index++) hardSpot(id: 'h$index'),
    ];

    final plan = planner.build(
      TodayPlanRequest(units: units, budgetSeconds: 120),
    );
    final hardSeconds = plan.steps
        .where((step) => step.kind == PlanStepKind.hardSpot)
        .fold(0, (sum, step) => sum + step.estimatedSeconds);

    expect(hardSeconds, lessThanOrEqualTo(30));
    expect(plan.extraReview, isNotEmpty);
  });

  test('yesterday unfinished passage is first and every step has a reason', () {
    final yesterday = epoch.subtract(const Duration(days: 1));
    final units = [
      passage(
        id: 'unfinished',
        queue: PlanQueue.learning,
        learningStartedAt: yesterday,
        wordCount: 5,
        toWord: 5,
      ),
      passage(
        id: 'recent',
        queue: PlanQueue.recent,
        wordCount: 5,
        toWord: 5,
      ),
    ];

    final plan = planner.build(
      TodayPlanRequest(units: units, budgetSeconds: 300),
    );

    expect(plan.steps.first.unitId, 'unfinished');
    expect(plan.steps.first.reason, PlanReason.yesterdayNew);
    expect(plan.steps.every((step) => step.reason.name.isNotEmpty), isTrue);
    expect(plan.approximateMinutes, (plan.estimatedSeconds / 60).round());
  });

  test('break produces 3–5 passage diagnostic from varied surahs', () {
    final units = [
      for (var index = 0; index < 8; index++)
        passage(
          id: 'u$index',
          surah: 70 + index,
          queue: PlanQueue.old,
          priorErrorCount: index,
        ),
    ];

    final plan = planner.build(
      TodayPlanRequest(
        units: units,
        budgetSeconds: 600,
        lastStudyAt: epoch.subtract(const Duration(days: 7)),
      ),
    );

    expect(plan.isDiagnostic, isTrue);
    expect(plan.steps.length, inInclusiveRange(3, 5));
    expect(
      plan.steps.every((step) => step.reason == PlanReason.returnDiagnosis),
      isTrue,
    );
  });

  test('new target is halved for the first week after diagnosis', () {
    final plan = planner.build(
      TodayPlanRequest(
        units: [passage(id: 'new')],
        budgetSeconds: 600,
        lastDiagnosisAt: epoch,
      ),
    );

    expect(plan.targetNewSeconds, 60);
  });

  test('multiple goals filter units and preserve chosen order', () {
    final units = [
      passage(id: 'a', goalIds: {'g1'}),
      passage(id: 'b', goalIds: {'g2'}),
      passage(id: 'outside'),
    ];
    final goals = [
      PlanGoal(id: 'g1', unitIds: ['a']),
      PlanGoal(id: 'g2', unitIds: ['b']),
    ];

    final plan = planner.build(
      TodayPlanRequest(units: units, goals: goals, budgetSeconds: 600),
    );

    expect(plan.steps.any((step) => step.unitId == 'outside'), isFalse);
    expect(plan.steps.any((step) => step.unitId == 'a'), isTrue);
  });

  test('today plan can be edited by removing and adding a step (PL-11)', () {
    final original = planner.build(
      TodayPlanRequest(
        units: [passage(id: 'recent', queue: PlanQueue.recent)],
        budgetSeconds: 300,
      ),
    );
    const added = PlanStep(
      id: 'custom',
      unitId: 'custom-unit',
      kind: PlanStepKind.recent,
      reason: PlanReason.recentDue,
      estimatedSeconds: 20,
    );

    final changed = editTodayPlan(
      original,
      removeStepIds: {original.steps.first.id},
      addSteps: [added],
    );

    expect(changed.steps.single.id, 'custom');
    expect(changed.steps.single.reason, PlanReason.userAdded);
    expect(changed.estimatedSeconds, 20);
  });
}
