import 'dart:math';

// Keep the constructor spelling consistent with the rest of the application.
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:planner/planner.dart';

/// Small app-facing wrapper that supplies all planner dependencies explicitly.
final class AppPlannerService {
  /// Creates a planner wrapper.
  AppPlannerService({
    required Clock clock,
    required Random random,
    PlannerParams? params,
  }) : _clock = clock,
       _params = params ?? PlannerParams.defaults,
       _engine = PlannerEngine(
         params: params ?? PlannerParams.defaults,
         clock: clock,
         random: random,
       ),
       _random = random;

  final Clock _clock;
  final PlannerParams _params;
  final PlannerEngine _engine;
  final Random _random;

  /// [unit] after one reading [attempt] (docs/tz 3.4): the first check of a
  /// passage known before goes through the recovery check; a passage not
  /// started yet starts learning first.
  PlanUnit applyReading(PlanUnit unit, Attempt attempt) {
    if (unit.queue == PlanQueue.notStarted &&
        unit.knownBefore &&
        unit.kind == PlanUnitKind.passage) {
      return _engine.applyRecoveryCheck(unit, attempt);
    }
    final started = unit.queue == PlanQueue.notStarted
        ? _engine.startLearning(unit)
        : unit;
    return _engine.applyAttempt(started, attempt);
  }

  /// Repetitions of ЗН-01: listening and reading with support.
  ({int listen, int supported}) get learningRepeats => (
    listen: _params.learnListenRepeats,
    supported: _params.learnSupportedRepeats,
  );

  /// Current FSRS probability of remembering [unit].
  double retrievability(PlanUnit unit) => _engine.retrievability(unit);

  /// Words on each side of the junction of two passages (ЗН-03).
  int get learnJunctionWords => _params.learnJunctionWords;

  /// КП-01 «давно не проверяли»: days overdue (12.4 `staleAfterDays`).
  int get staleAfterDays => _params.staleAfterDays;

  /// КП-01 «давно не проверяли»: recall below this (12.4 `staleRecallBelow`).
  double get staleRecallBelow => _params.staleRecallBelow;

  /// КП-01 «помню»: a later clean check at least this many days after the
  /// first one (12.4 `confirmedLaterMinDays`).
  int get confirmedLaterMinDays => _params.confirmedLaterMinDays;

  /// Builds a plan using the pure-Dart package and specification parameters.
  TodayPlan build(TodayPlanRequest request) => TodayPlanner(
    params: _params,
    clock: _clock,
    random: _random,
    engine: _engine,
  ).build(request);
}
