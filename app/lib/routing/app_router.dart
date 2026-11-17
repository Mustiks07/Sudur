import 'package:go_router/go_router.dart';
import 'package:sudur/config/app_config.dart';
import 'package:sudur/ui/home/views/home_screen.dart';
import 'package:sudur/ui/prototype/views/prototype_screen.dart';

/// Creates a router owned by the application's dependency scope.
GoRouter createAppRouter(AppConfig config) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => config == AppConfig.dev
          ? const PrototypeScreen()
          : const HomeScreen(),
    ),
  ],
);
