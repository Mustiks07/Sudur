import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/app_config.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/home/view_models/home_view_model.dart';

/// Builds and owns application-level dependencies.
class AppDependencies extends StatelessWidget {
  /// Creates the application dependency scope.
  const new({required this.config, required this.child, super.key});

  /// Configuration selected by the entry point.
  final AppConfig config;

  /// Application widget below the dependency scope.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<GoRouter>(
          create: (_) => createAppRouter(),
          dispose: (_, router) => router.dispose(),
        ),
        ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()),
      ],
      child: child,
    );
  }
}
