import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:planner/planner.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/app_config.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/config/prototype_real_session.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';
import 'package:sudur/data/repositories/prototype_repository.dart';
import 'package:sudur/data/services/app_file_service.dart';
import 'package:sudur/data/services/app_planner_service.dart';
import 'package:sudur/data/services/app_storage_service.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_platform_service.dart';
import 'package:sudur/data/services/prototype_session.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/home/view_models/home_view_model.dart';
import 'package:sudur/ui/more/view_models/more_view_model.dart';
import 'package:sudur/ui/reading/view_models/reading_view_model.dart';
import 'package:sudur/ui/start/view_models/start_view_model.dart';
import 'package:sudur/ui/today/view_models/today_view_model.dart';

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
    const e01Config = E01Config();
    const clock = SystemClock();
    final random = Random.secure();
    final storage = AppStorageService(platform);
    const files = AppFileService(platform);
    final installer = PrototypeAssetInstaller(platform);
    final repository = LocalPrototypeRepository(installer, platform);
    final userRepository = StorageAppUserRepository(
      storage: storage,
      files: files,
      modelInstaller: installer,
      planner: AppPlannerService(clock: clock, random: random),
      clock: clock,
      createId: () => _uuid(random),
      config: e01Config,
    );
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<E01Config>.value(value: e01Config),
        Provider<GoRouter>(
          create: (_) => createAppRouter(config),
          dispose: (_, router) => router.dispose(),
        ),
        Provider<PrototypeRepository>.value(value: repository),
        Provider<AppStorageService>(
          create: (_) => storage,
          dispose: (_, value) => unawaited(value.dispose()),
        ),
        Provider<AppUserRepository>.value(value: userRepository),
        Provider<PrototypeReadingSessionFactory>.value(
          value: RealPrototypeReadingSessionFactory(),
        ),
        ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()),
        ChangeNotifierProvider<StartViewModel>(
          create: (_) {
            final viewModel = StartViewModel(userRepository, e01Config);
            unawaited(viewModel.initialize());
            return viewModel;
          },
        ),
        ChangeNotifierProvider<TodayViewModel>(
          create: (_) => TodayViewModel(userRepository, e01Config),
        ),
        ChangeNotifierProvider<MoreViewModel>(
          create: (_) => MoreViewModel(userRepository),
        ),
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

String _uuid(Random random) {
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final value = bytes.map(hex).join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}
