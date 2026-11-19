import 'dart:math';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/planner.dart';
import 'package:storage/storage.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';
import 'package:sudur/data/services/app_file_service.dart';
import 'package:sudur/data/services/app_planner_service.dart';
import 'package:sudur/data/services/app_storage_service.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_platform_service.dart';

void main() {
  test('profile, draft, and daily plan survive repository reloads', () async {
    final storage = StorageService.memory();
    addTearDown(storage.close);
    final clock = SimulatedClock(DateTime.utc(2026, 11, 19, 8));
    var nextId = 0;
    const platform = _FakePlatform();
    final repository = StorageAppUserRepository(
      storage: AppStorageService.fromStorage(storage),
      files: const AppFileService(platform),
      modelInstaller: PrototypeAssetInstaller(platform),
      planner: AppPlannerService(clock: clock, random: Random(1)),
      clock: clock,
      createId: () =>
          '00000000-0000-4000-8000-${(nextId++).toString().padLeft(12, '0')}',
      config: const E01Config(),
    );
    final draft = OnboardingDraft(
      step: OnboardingStep.completed,
      language: AppLanguage.en,
      path: AppLearningPath.restore,
      familiarSurahs: const {78},
      dailyMinutes: 10,
      downloadModelNow: false,
      startPoint: AppStartPoint.shortSurahs,
    );

    expect(await repository.saveOnboardingDraft(draft), isA<Ok<void>>());
    expect(
      await repository.completeOnboarding(draft),
      isA<Ok<AppUserProfile>>(),
    );
    final first = _value(await repository.loadToday());
    final second = _value(await repository.loadToday());

    expect(second.date, first.date);
    expect(
      second.steps.map((step) => step.id),
      first.steps.map((step) => step.id),
    );
    expect(_value(await repository.loadProfile())?.language, AppLanguage.en);
    expect(
      _value(await repository.loadOnboardingDraft()).familiarSurahs,
      contains(78),
    );
  });
}

T _value<T>(Result<T> result) => switch (result) {
  Ok<T>(:final value) => value,
  Error<T>(:final error) => throw error,
};

final class _FakePlatform implements PrototypePlatformService {
  const new();

  @override
  Future<String> applicationDirectory() async => '/tmp/sudur-e01-test';

  @override
  Future<String?> pickUserDataArchive() async => null;

  @override
  Future<String?> pickWavFile() async => null;

  @override
  Future<void> shareFile(String path) async {}
}
