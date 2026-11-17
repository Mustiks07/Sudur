import 'package:flutter/widgets.dart';
import 'package:sudur/app.dart';
import 'package:sudur/config/app_config.dart';
import 'package:sudur/config/dependencies.dart';

/// Starts Sudur with dependencies for [config].
void bootstrap(AppConfig config) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppDependencies(config: config, child: const SudurApp()));
}
