// Plan DTO fields and enum values mirror the product specification.
// ignore_for_file: public_member_api_docs

import 'dart:math';

import 'package:planner/src/clock.dart';
import 'package:planner/src/grading.dart';
import 'package:planner/src/learning.dart';
import 'package:planner/src/models.dart';
import 'package:planner/src/params.dart';
import 'package:planner/src/planner_engine.dart';

/// Kind of one step in today's session.
enum PlanStepKind {
  diagnostic,
  unfinishedNew,
  hardSpot,
  recent,
  old,
  newPassage,
  lesson,
  skill,
}

/// User-visible reason for including a step.
enum PlanReason {
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

/// One immutable step in today's plan.
final class PlanStep {
  /// Creates a plan step.
  const PlanStep({
    required this.id,
    required this.kind,
    required this.reason,
    required this.estimatedSeconds,
    this.unitId,
  }) : assert(
          estimatedSeconds >= 0,
          'estimatedSeconds must not be negative.',
        );

  final String id;
  final String? unitId;
  final PlanStepKind kind;
  final PlanReason reason;
  final int estimatedSeconds;

  /// Returns the same step marked as a manual addition.
  PlanStep asUserAdded() => PlanStep(
        id: id,
        unitId: unitId,
        kind: kind,
        reason: PlanReason.userAdded,
        estimatedSeconds: estimatedSeconds,
      );
}

/// Result of the step 0–7 plan-building algorithm.
final class TodayPlan {
  /// Creates a today's plan.
  TodayPlan({
    required List<PlanStep> steps,
    required List<PlanStep> extraReview,
    required this.budgetSeconds,
    required this.estimatedSeconds,
    required this.approximateMinutes,
    required this.debtSeconds,
    required this.isDiagnostic,
    required this.targetNewSeconds,
    required this.targetRecentSeconds,
    required this.targetOldSeconds,
  })  : steps = List.unmodifiable(steps),
        extraReview = List.unmodifiable(extraReview);

  final List<PlanStep> steps;
  final List<PlanStep> extraReview;
  final int budgetSeconds;
  final int estimatedSeconds;
  final int approximateMinutes;
  final int debtSeconds;
  final bool isDiagnostic;

  /// Initial target shares from PL-03, before priority spillover.
  final int targetNewSeconds;
  final int targetRecentSeconds;
  final int targetOldSeconds;

  /// Whether every automatically selected step fits the requested budget.
  bool get fitsBudget => estimatedSeconds <= budgetSeconds;
}

/// Inputs required to build today's session without accessing storage.
final class TodayPlanRequest {
  /// Creates a request.
  TodayPlanRequest({
    required List<PlanUnit> units,
    required this.budgetSeconds,
    List<PlanGoal> goals = const [],
    List<CourseLesson> lessons = const [],
    this.lastStudyAt,
    this.lastDiagnosisAt,
  })  : units = List.unmodifiable(units),
        goals = List.unmodifiable(goals),
        lessons = List.unmodifiable(lessons),
        assert(budgetSeconds >= 0, 'budgetSeconds must not be negative.');

  final List<PlanUnit> units;
  final int budgetSeconds;
  final List<PlanGoal> goals;
  final List<CourseLesson> lessons;
  final DateTime? lastStudyAt;
  final DateTime? lastDiagnosisAt;
}

/// Pure planner for today's budget and break diagnostics.
final class TodayPlanner {
  /// Creates a planner with explicit time and randomness.
  const TodayPlanner({
    required this.params,
    required this.clock,
    required this.random,
    required this.engine,
  });

  final PlannerParams params;
  final Clock clock;
  final Random random;
  final PlannerEngine engine;

  /// Runs steps 0–7 from docs/tz 11.1.
  TodayPlan build(TodayPlanRequest request) {
    final now = clock.now().toUtc();
    final units = _unitsForActiveGoals(request.units, request.goals);
    final speed = _personalSpeed(units);
    if (_needsDiagnosis(request, now)) {
      return _diagnosticPlan(request, units, speed, now);
    }

    final afterBreak = request.lastDiagnosisAt != null &&
        !request.lastDiagnosisAt!.isAfter(now) &&
        now.difference(request.lastDiagnosisAt!.toUtc()).inDays <
            params.afterBreakDays;
    final effectiveNewShare =
        params.newShare * (afterBreak ? params.afterBreakNewFactor : 1);
    final repeatTarget =
        ((1 - effectiveNewShare) * request.budgetSeconds).round();
    final selected = <PlanStep>[];
    final selectedUnits = <String>{};
    var total = 0;

    bool addUnit(
      PlanUnit unit,
      PlanStepKind kind,
      PlanReason reason, {
      required int limit,
      required double multiplier,
    }) {
      if (selectedUnits.contains(unit.id)) return false;
      final cost = _unitCost(unit, speed, multiplier);
      if (total + cost > limit || total + cost > request.budgetSeconds) {
        return false;
      }
      selected.add(
        PlanStep(
          id: 'unit:${unit.id}',
          unitId: unit.id,
          kind: kind,
          reason: reason,
          estimatedSeconds: cost,
        ),
      );
      selectedUnits.add(unit.id);
      total += cost;
      return true;
    }

    final yesterdayNew = units
        .where((unit) => unit.queue == PlanQueue.learning)
        .where((unit) => _wasActiveYesterday(unit, now, params))
        .toList()
      ..sort(_byDue);
    for (final unit in yesterdayNew) {
      addUnit(
        unit,
        PlanStepKind.unfinishedNew,
        PlanReason.yesterdayNew,
        limit: request.budgetSeconds,
        multiplier: params.newLearningMultiplier,
      );
    }

    final hardLimit = (request.budgetSeconds * params.hardSpotMaxShare).round();
    final hard = units
        .where(
          (unit) =>
              unit.kind == PlanUnitKind.hardSpot &&
              unit.hardSpotStage != HardSpotStage.closed &&
              !_after(unit.due, now),
        )
        .toList()
      ..sort(_byDue);
    var hardSeconds = 0;
    for (final unit in hard) {
      final cost = _unitCost(unit, speed, params.hardSpotMultiplier);
      if (hardSeconds + cost > hardLimit) continue;
      if (addUnit(
        unit,
        PlanStepKind.hardSpot,
        PlanReason.yesterdayError,
        limit: request.budgetSeconds,
        multiplier: params.hardSpotMultiplier,
      )) {
        hardSeconds += cost;
      }
    }

    final recent = units
        .where(
          (unit) =>
              unit.kind != PlanUnitKind.hardSpot &&
              unit.kind != PlanUnitKind.skill &&
              unit.queue == PlanQueue.recent &&
              !_after(unit.due, now),
        )
        .toList()
      ..sort(_byDue);
    for (final unit in recent) {
      if (total >= repeatTarget) break;
      addUnit(
        unit,
        PlanStepKind.recent,
        PlanReason.recentDue,
        limit: repeatTarget,
        multiplier: params.recallMultiplier,
      );
    }

    final old = units
        .where(
          (unit) =>
              unit.kind != PlanUnitKind.skill &&
              unit.queue == PlanQueue.old &&
              !_after(unit.due, now),
        )
        .toList()
      ..sort(
        (left, right) => engine
            .retrievability(left, at: now)
            .compareTo(engine.retrievability(right, at: now)),
      );
    for (final unit in old) {
      if (total >= repeatTarget) break;
      addUnit(
        unit,
        PlanStepKind.old,
        PlanReason.longUnchecked,
        limit: repeatTarget,
        multiplier: params.recallMultiplier,
      );
    }

    final dueReview = <PlanUnit>[...hard, ...recent, ...old];
    final debtSeconds = dueReview
        .where((unit) => !selectedUnits.contains(unit.id))
        .map((unit) => _costForKind(unit, speed))
        .fold(0, (sum, cost) => sum + cost);
    final remaining = request.budgetSeconds - total;
    final minimumNewRoom = (effectiveNewShare * request.budgetSeconds).round();
    final debtLimit = (params.debtLimitFactor * request.budgetSeconds).round();
    if (remaining >= minimumNewRoom && debtSeconds <= debtLimit) {
      final newUnits = orderNewUnits(
        units
            .where(
              (unit) =>
                  unit.kind == PlanUnitKind.passage &&
                  (unit.queue == PlanQueue.notStarted ||
                      unit.queue == PlanQueue.learning),
            )
            .where((unit) => !selectedUnits.contains(unit.id))
            .toList(),
        request.goals,
      );
      for (final unit in newUnits) {
        if (addUnit(
          unit,
          PlanStepKind.newPassage,
          PlanReason.newMaterial,
          limit: request.budgetSeconds,
          multiplier: params.newLearningMultiplier,
        )) {
          break;
        }
      }
    }

    for (final lesson in request.lessons) {
      final cost = lesson.duration.inSeconds;
      if (total + cost > request.budgetSeconds) continue;
      selected.add(
        PlanStep(
          id: 'lesson:${lesson.id}',
          kind: PlanStepKind.lesson,
          reason: PlanReason.courseLesson,
          estimatedSeconds: cost,
        ),
      );
      total += cost;
    }
    final skills = units
        .where(
          (unit) =>
              unit.kind == PlanUnitKind.skill &&
              !_after(unit.due, now) &&
              !selectedUnits.contains(unit.id),
        )
        .toList()
      ..sort(_byDue);
    for (final unit in skills) {
      addUnit(
        unit,
        PlanStepKind.skill,
        PlanReason.skillDue,
        limit: request.budgetSeconds,
        multiplier: params.recallMultiplier,
      );
    }

    final extra = units
        .where(
          (unit) =>
              (unit.queue == PlanQueue.recent ||
                  unit.queue == PlanQueue.old ||
                  unit.kind == PlanUnitKind.hardSpot ||
                  unit.kind == PlanUnitKind.skill) &&
              !selectedUnits.contains(unit.id),
        )
        .toList()
      ..sort(_byDue);
    return TodayPlan(
      steps: List.unmodifiable(selected),
      extraReview: List.unmodifiable(
        extra.map(
          (unit) => PlanStep(
            id: 'extra:${unit.id}',
            unitId: unit.id,
            kind: _stepKind(unit),
            reason: _reason(unit),
            estimatedSeconds: _costForKind(unit, speed),
          ),
        ),
      ),
      budgetSeconds: request.budgetSeconds,
      estimatedSeconds: total,
      approximateMinutes: _minutes(total),
      debtSeconds: debtSeconds,
      isDiagnostic: false,
      targetNewSeconds: (request.budgetSeconds * effectiveNewShare).round(),
      targetRecentSeconds: (request.budgetSeconds * params.recentShare).round(),
      targetOldSeconds: (request.budgetSeconds * params.oldShare).round(),
    );
  }

  TodayPlan _diagnosticPlan(
    TodayPlanRequest request,
    List<PlanUnit> units,
    double speed,
    DateTime now,
  ) {
    final candidates = units
        .where((unit) => unit.kind == PlanUnitKind.passage)
        .where(
          (unit) =>
              unit.queue == PlanQueue.old || unit.queue == PlanQueue.recent,
        )
        .toList();
    final diagnosticSpan =
        params.diagnosticMaxSize - params.diagnosticMinSize + 1;
    final requested = params.diagnosticMinSize + random.nextInt(diagnosticSpan);
    final wanted = min(requested, candidates.length);
    final picked = <PlanUnit>[];
    final usedSurahs = <int>{};
    var total = 0;
    while (picked.length < wanted && candidates.isNotEmpty) {
      final differentSurah = candidates
          .where((unit) => !usedSurahs.contains(unit.range.surah))
          .toList();
      final pool = differentSurah.isEmpty ? candidates : differentSurah;
      final chosen = _weightedDiagnosticChoice(pool, now);
      candidates.remove(chosen);
      final cost = _unitCost(chosen, speed, params.recallMultiplier);
      if (total + cost > request.budgetSeconds) continue;
      picked.add(chosen);
      usedSurahs.add(chosen.range.surah);
      total += cost;
    }
    return TodayPlan(
      steps: List.unmodifiable(
        picked.map(
          (unit) => PlanStep(
            id: 'diagnostic:${unit.id}',
            unitId: unit.id,
            kind: PlanStepKind.diagnostic,
            reason: PlanReason.returnDiagnosis,
            estimatedSeconds: _unitCost(unit, speed, params.recallMultiplier),
          ),
        ),
      ),
      extraReview: const [],
      budgetSeconds: request.budgetSeconds,
      estimatedSeconds: total,
      approximateMinutes: _minutes(total),
      debtSeconds: 0,
      isDiagnostic: true,
      targetNewSeconds: 0,
      targetRecentSeconds: 0,
      targetOldSeconds: 0,
    );
  }

  PlanUnit _weightedDiagnosticChoice(List<PlanUnit> units, DateTime now) {
    final weighted = <(PlanUnit, double)>[];
    var total = 0.0;
    for (final unit in units) {
      final last = unit.lastAttempt?.at ?? unit.card.lastReview ?? unit.due;
      final staleDays = max(0, now.difference(last.toUtc()).inDays);
      final weight = params.diagnosticBaseWeight +
          staleDays * params.diagnosticStalenessWeight +
          unit.priorErrorCount * params.diagnosticErrorWeight;
      weighted.add((unit, weight));
      total += weight;
    }
    var point = random.nextDouble() * total;
    for (final entry in weighted) {
      point -= entry.$2;
      if (point <= 0) return entry.$1;
    }
    return weighted.last.$1;
  }

  bool _needsDiagnosis(TodayPlanRequest request, DateTime now) {
    final lastStudy = request.lastStudyAt;
    if (lastStudy == null ||
        now.difference(lastStudy.toUtc()).inDays < params.breakDays) {
      return false;
    }
    final diagnosis = request.lastDiagnosisAt;
    return diagnosis == null || diagnosis.toUtc().isBefore(lastStudy.toUtc());
  }

  List<PlanUnit> _unitsForActiveGoals(
    List<PlanUnit> units,
    List<PlanGoal> goals,
  ) {
    final active = goals.where((goal) => goal.active).toList();
    if (active.isEmpty) return List.unmodifiable(units);
    final ids = {for (final goal in active) ...goal.unitIds};
    return List.unmodifiable(units.where((unit) => ids.contains(unit.id)));
  }

  double _personalSpeed(List<PlanUnit> units) {
    final history = units.expand((unit) => unit.history).toList()
      ..sort((left, right) => left.attempt.at.compareTo(right.attempt.at));
    return personalSecondsPerWord(history, params) ??
        params.defaultSecondsPerWord;
  }

  int _unitCost(PlanUnit unit, double speed, double multiplier) =>
      (unit.range.wordCount * speed * multiplier).ceil();

  int _costForKind(PlanUnit unit, double speed) => _unitCost(
        unit,
        speed,
        unit.kind == PlanUnitKind.hardSpot
            ? params.hardSpotMultiplier
            : params.recallMultiplier,
      );
}

/// Applies PL-11 manual removals and additions to an already built plan.
TodayPlan editTodayPlan(
  TodayPlan plan, {
  Set<String> removeStepIds = const {},
  List<PlanStep> addSteps = const [],
}) {
  final steps =
      plan.steps.where((step) => !removeStepIds.contains(step.id)).toList();
  final ids = steps.map((step) => step.id).toSet();
  for (final step in addSteps) {
    if (ids.add(step.id)) steps.add(step.asUserAdded());
  }
  final seconds = steps.fold(0, (sum, step) => sum + step.estimatedSeconds);
  return TodayPlan(
    steps: List.unmodifiable(steps),
    extraReview: plan.extraReview,
    budgetSeconds: plan.budgetSeconds,
    estimatedSeconds: seconds,
    approximateMinutes: _minutes(seconds),
    debtSeconds: plan.debtSeconds,
    isDiagnostic: plan.isDiagnostic,
    targetNewSeconds: plan.targetNewSeconds,
    targetRecentSeconds: plan.targetRecentSeconds,
    targetOldSeconds: plan.targetOldSeconds,
  );
}

bool _wasActiveYesterday(PlanUnit unit, DateTime now, PlannerParams params) {
  final activeAt = unit.lastAttempt?.at ?? unit.learningStartedAt;
  if (activeAt == null) return false;
  final today = DateTime.utc(now.year, now.month, now.day);
  final activeDay = DateTime.utc(
    activeAt.toUtc().year,
    activeAt.toUtc().month,
    activeAt.toUtc().day,
  );
  return today.difference(activeDay).inDays == params.unfinishedLookbackDays;
}

bool _after(DateTime left, DateTime right) => left.toUtc().isAfter(right);

int _byDue(PlanUnit left, PlanUnit right) => left.due.compareTo(right.due);

int _minutes(int seconds) => (seconds / Duration.secondsPerMinute).round();

PlanStepKind _stepKind(PlanUnit unit) => switch (unit.kind) {
      PlanUnitKind.hardSpot => PlanStepKind.hardSpot,
      PlanUnitKind.skill => PlanStepKind.skill,
      PlanUnitKind.passage ||
      PlanUnitKind.junction =>
        unit.queue == PlanQueue.old ? PlanStepKind.old : PlanStepKind.recent,
    };

PlanReason _reason(PlanUnit unit) => switch (unit.kind) {
      PlanUnitKind.hardSpot => PlanReason.yesterdayError,
      PlanUnitKind.skill => PlanReason.skillDue,
      PlanUnitKind.passage ||
      PlanUnitKind.junction =>
        unit.queue == PlanQueue.old
            ? PlanReason.longUnchecked
            : PlanReason.recentDue,
    };
