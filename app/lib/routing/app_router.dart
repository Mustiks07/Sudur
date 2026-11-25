import 'dart:async';

import 'package:contracts/contracts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/app_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';
import 'package:sudur/data/repositories/exercise_repository.dart';
import 'package:sudur/data/repositories/reading_repository.dart';
import 'package:sudur/data/services/device_service.dart';
import 'package:sudur/data/services/prototype_session.dart';
import 'package:sudur/ui/exercise/view_models/exercise_view_model.dart';
import 'package:sudur/ui/exercise/views/exercise_screen.dart';
import 'package:sudur/ui/read/view_models/read_view_model.dart';
import 'package:sudur/ui/read/views/read_screen.dart';
import 'package:sudur/ui/reading/views/reading_screen.dart';
import 'package:sudur/ui/self_check/view_models/self_check_view_model.dart';
import 'package:sudur/ui/self_check/views/self_check_screen.dart';
import 'package:sudur/ui/start/views/root_screen.dart';
import 'package:sudur/ui/today/views/step_coming_soon_screen.dart';

/// Creates a router owned by the application's dependency scope.
GoRouter createAppRouter(AppConfig config) => GoRouter(
  initialLocation: config == AppConfig.dev ? '/prototype' : '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const RootScreen()),
    GoRoute(
      path: '/prototype',
      builder: (context, state) {
        final query = state.uri.queryParameters;
        return ReadingScreen(
          from: _wordKey(query['from']),
          to: _wordKey(query['to']),
          stepId: query['step'],
        );
      },
    ),
    GoRoute(
      path: '/read',
      builder: (context, state) {
        final query = state.uri.queryParameters;
        final from = _wordKey(query['from']);
        final to = _wordKey(query['to']);
        if (from == null || to == null || to.compareTo(from) < 0) {
          return const StepComingSoonScreen();
        }
        return ChangeNotifierProvider<ReadViewModel>(
          create: (context) {
            final viewModel = ReadViewModel(
              reading: context.read<ReadingRepository>(),
              user: context.read<AppUserRepository>(),
              sessionFactory: context.read<PrototypeReadingSessionFactory>(),
              device: context.read<DeviceService>(),
            );
            unawaited(
              viewModel.open(
                from: from,
                to: to,
                stepId: query['step'],
                mode: ReadMode.values
                    .where((m) => m.name == query['mode'])
                    .firstOrNull,
              ),
            );
            return viewModel;
          },
          child: const ReadScreen(),
        );
      },
    ),
    GoRoute(
      path: '/self',
      builder: (context, state) {
        final query = state.uri.queryParameters;
        final from = _wordKey(query['from']);
        final to = _wordKey(query['to']);
        if (from == null || to == null || to.compareTo(from) < 0) {
          return const StepComingSoonScreen();
        }
        return ChangeNotifierProvider<SelfCheckViewModel>(
          create: (context) {
            final viewModel = SelfCheckViewModel(
              reading: context.read<ReadingRepository>(),
              user: context.read<AppUserRepository>(),
            );
            unawaited(
              viewModel.open(from: from, to: to, stepId: query['step']),
            );
            return viewModel;
          },
          child: const SelfCheckScreen(),
        );
      },
    ),
    GoRoute(
      path: '/exercise',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! (CheckEvent, String?)) {
          return const StepComingSoonScreen();
        }
        return ChangeNotifierProvider<ExerciseViewModel>(
          create: (context) {
            final viewModel = ExerciseViewModel(
              context.read<ExerciseRepository>(),
            );
            unawaited(viewModel.open(extra.$1, parentUnitId: extra.$2));
            return viewModel;
          },
          child: const ExerciseScreen(),
        );
      },
    ),
    GoRoute(
      path: '/soon',
      builder: (context, state) => const StepComingSoonScreen(),
    ),
  ],
);

/// Where a step of “Today” is read: steps with words open the reading
/// screen with their range; others (lessons) are not built yet.
String locationOfStep(TodayStepData step) {
  final from = step.from;
  final to = step.to;
  if (from == null || to == null) return '/soon';
  // Without the model or the free voice checks: self-check (13.2).
  return selfCheckLocation(
    from,
    to,
    stepId: step.id,
    path: step.selfCheck ? '/self' : '/read',
  );
}

/// The self-check (or, with [path], reading) of [from]–[to].
String selfCheckLocation(
  WordKey from,
  WordKey to, {
  String? stepId,
  String path = '/self',
  String? mode,
}) => Uri(
  path: path,
  queryParameters: {
    'from': '$from',
    'to': '$to',
    'step': ?stepId,
    'mode': ?mode,
  },
).toString();

/// A link is outside data: a malformed key opens the whole prototype.
WordKey? _wordKey(String? value) {
  final parts = value?.split(':').map(int.tryParse).toList();
  if (parts case [final int surah, final int ayah, final int word]
      when surah >= 1 && surah <= 114 && ayah >= 1 && word >= 1) {
    return WordKey(surah, ayah, word);
  }
  return null;
}
