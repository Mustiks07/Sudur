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

  /// Builds a plan using the pure-Dart package and specification parameters.
  TodayPlan build(TodayPlanRequest request) => TodayPlanner(
    params: _params,
    clock: _clock,
    random: _random,
    engine: _engine,
  ).build(request);
}
