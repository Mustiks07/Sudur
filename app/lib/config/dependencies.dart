import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/app_config.dart';
import 'package:sudur/config/prototype_real_session.dart';
import 'package:sudur/data/repositories/prototype_repository.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_platform_service.dart';
import 'package:sudur/data/services/prototype_session.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/home/view_models/home_view_model.dart';
import 'package:sudur/ui/reading/view_models/reading_view_model.dart';

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
    const platform = MethodChannelPrototypePlatformService();
    final repository = LocalPrototypeRepository(
      PrototypeAssetInstaller(platform),
      platform,
    );
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<GoRouter>(
          create: (_) => createAppRouter(config),
          dispose: (_, router) => router.dispose(),
        ),
        Provider<PrototypeRepository>.value(value: repository),
        Provider<PrototypeReadingSessionFactory>.value(
          value: RealPrototypeReadingSessionFactory(),
        ),
        ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()),
        ChangeNotifierProvider<ReadingViewModel>(
          create: (context) {
            final viewModel = ReadingViewModel(
              context.read<PrototypeRepository>(),
              context.read<PrototypeReadingSessionFactory>(),
            );
            unawaited(viewModel.initialize());
            return viewModel;
          },
        ),
      ],
      child: child,
    );
  }
}
