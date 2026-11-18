import 'dart:math';

import 'package:planner/planner.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  test('90-day deterministic learner stays feasible and debt stays bounded',
      () {
    final clock = SimulatedClock(epoch);
    final schedulingRandom = Random(11);
    final behaviorRandom = Random(12);
    final engine = PlannerEngine(
      params: PlannerParams.defaults,
      clock: clock,
      random: schedulingRandom,
    );
    final todayPlanner = TodayPlanner(
      params: PlannerParams.defaults,
      clock: clock,
      random: schedulingRandom,
      engine: engine,
    );
    final units = <String, PlanUnit>{
      for (var index = 0; index < 16; index++)
        'u$index': passage(
          id: 'u$index',
          surah: 114 - index,
        ),
    };
    DateTime? lastStudyAt;
    DateTime? lastDiagnosisAt;
    var maximumDebt = 0;

    for (var day = 0; day < 90; day++) {
      final now = epoch.add(Duration(days: day));
      clock.moveTo(now);
      if (behaviorRandom.nextDouble() < 0.2) continue;

      final plan = todayPlanner.build(
        TodayPlanRequest(
          units: units.values.toList(),
          budgetSeconds: 600,
          lastStudyAt: lastStudyAt,
          lastDiagnosisAt: lastDiagnosisAt,
        ),
      );
      expect(plan.fitsBudget, isTrue, reason: 'day $day');
      maximumDebt = max(maximumDebt, plan.debtSeconds);
      if (plan.isDiagnostic) lastDiagnosisAt = now;

      for (final step in plan.steps) {
        final unitId = step.unitId;
        if (unitId == null) continue;
        final unit = units[unitId];
        if (unit == null) continue;
        final learning = unit.queue == PlanQueue.notStarted ||
            unit.queue == PlanQueue.learning;
        final forgot = !learning && behaviorRandom.nextDouble() < 0.08;
        final reading = attempt(
          unitId: unitId,
          at: now,
          mode: learning ? AttemptMode.selfCheck : AttemptMode.recall,
          result: forgot ? AttemptResult.confirmedError : AttemptResult.clean,
          verification: learning
              ? VerificationMethod.selfCheck
              : VerificationMethod.voice,
          wordCount: unit.range.wordCount,
          duration: Duration(seconds: unit.range.wordCount),
        );
        final updated = plan.isDiagnostic && unit.knownBefore
            ? engine.applyRecoveryCheck(unit, reading)
            : engine.applyAttempt(unit, reading);
        units[unitId] = updated;
        if (updated.history.last.assessment.isRated) {
          expect(
            updated.due.isBefore(now),
            isFalse,
            reason: 'due date went to the past on day $day',
          );
        }
      }
      lastStudyAt = now;
    }

    final totalReviewCost = units.length * 10 * 1.3;
    expect(maximumDebt, lessThanOrEqualTo(totalReviewCost.ceil()));
    expect(
      units.values.where((unit) => unit.queue != PlanQueue.notStarted),
      isNotEmpty,
    );
  });
}
