import 'package:go_router/go_router.dart';
import 'package:sudur/config/app_config.dart';
import 'package:sudur/ui/home/views/home_screen.dart';
import 'package:sudur/ui/reading/views/reading_screen.dart';

/// Creates a router owned by the application's dependency scope.
GoRouter createAppRouter(AppConfig config) => GoRouter(
  initialLocation: config == AppConfig.dev ? '/prototype' : '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/prototype',
      builder: (context, state) => const ReadingScreen(),
    ),
  ],
);
