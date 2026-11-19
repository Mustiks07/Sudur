import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/ui/start/view_models/start_view_model.dart';

import '../../../test_helpers/fake_app_user_repository.dart';

void main() {
  test('interrupted start resumes from the persisted step', () async {
    final repository = FakeAppUserRepository()
      ..draft = OnboardingDraft(
        step: OnboardingStep.dailyTime,
        language: AppLanguage.ru,
        path: AppLearningPath.restore,
        familiarSurahs: const {78},
      );
    final viewModel = StartViewModel(repository, const E01Config());

    await viewModel.initialize();

    expect(viewModel.draft.step, OnboardingStep.dailyTime);
    expect(viewModel.draft.familiarSurahs, contains(78));
    expect(viewModel.completed, isFalse);
    viewModel.dispose();
  });

  test('every choice is saved and completion creates a profile', () async {
    final repository = FakeAppUserRepository();
    final viewModel = StartViewModel(repository, const E01Config());
    await viewModel.initialize();

    await viewModel.chooseLanguage(AppLanguage.ru);
    await viewModel.choosePath(AppLearningPath.restore);
    await viewModel.finishSurahs();
    await viewModel.chooseMinutes(10);
    await viewModel.chooseModel(downloadNow: false);
    await viewModel.chooseStartPoint(AppStartPoint.shortSurahs);

    expect(repository.draftSaves, 6);
    expect(repository.completed, isTrue);
    expect(viewModel.completed, isTrue);
    viewModel.dispose();
  });
}
