import 'package:contracts/contracts.dart';
import 'package:go_router/go_router.dart';
import 'package:sudur/config/app_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/ui/reading/views/reading_screen.dart';
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
      path: '/soon',
      builder: (context, state) => const StepComingSoonScreen(),
    ),
  ],
);

/// Where a step of “Today” is read. Until the reading screen (Q7) exists,
/// steps with words open the prototype with their range; others are not
/// built yet.
String locationOfStep(TodayStepData step) {
  final from = step.from;
  final to = step.to;
  if (from == null || to == null) return '/soon';
  return Uri(
    path: '/prototype',
    queryParameters: {'from': '$from', 'to': '$to', 'step': step.id},
  ).toString();
}

/// A link is outside data: a malformed key opens the whole prototype.
WordKey? _wordKey(String? value) {
  final parts = value?.split(':').map(int.tryParse).toList();
  if (parts case [final int surah, final int ayah, final int word]
      when surah >= 1 && surah <= 114 && ayah >= 1 && word >= 1) {
    return WordKey(surah, ayah, word);
  }
  return null;
}
