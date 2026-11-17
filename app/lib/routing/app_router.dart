import 'package:go_router/go_router.dart';
import 'package:sudur/ui/home/views/home_screen.dart';

/// Creates a router owned by the application's dependency scope.
GoRouter createAppRouter() => GoRouter(
  routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
);
