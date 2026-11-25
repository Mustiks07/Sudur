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

  test('back follows the route the user took (review of #29)', () async {
    final repository = FakeAppUserRepository();
    final viewModel = StartViewModel(repository, const E01Config());
    await viewModel.initialize();
    await viewModel.chooseLanguage(AppLanguage.ru);
    await viewModel.choosePath(AppLearningPath.learnReading);
    expect(viewModel.draft.step, OnboardingStep.dailyTime);

    // The course skips familiar surahs: back goes to the path.
    await viewModel.back();
    expect(viewModel.draft.step, OnboardingStep.path);

    await viewModel.choosePath(AppLearningPath.learnReading);
    await viewModel.chooseMinutes(10);
    expect(viewModel.draft.step, OnboardingStep.letters);
    await viewModel.back();
    expect(viewModel.draft.step, OnboardingStep.dailyTime);
    viewModel.dispose();
  });

  test('with familiar surahs the start point is not asked', () async {
    final repository = FakeAppUserRepository();
    final viewModel = StartViewModel(repository, const E01Config());
    await viewModel.initialize();
    await viewModel.chooseLanguage(AppLanguage.ru);
    await viewModel.choosePath(AppLearningPath.memorize);
    await viewModel.toggleSurah(78);
    await viewModel.finishSurahs();
    await viewModel.chooseMinutes(10);
    await viewModel.chooseModel(downloadNow: false);

    expect(repository.completed, isTrue);
    expect(viewModel.completed, isTrue);
    viewModel.dispose();
  });

  test('surahs are found by number and by names from the content', () async {
    final repository = FakeAppUserRepository()
      // Names as a content package would have them; test values, not text.
      ..surahNames = const {
        78: SurahNameData(number: 78, russian: 'Test-Name-78'),
        79: SurahNameData(number: 79, arabic: 'test-arabic-79'),
      };
    final viewModel = StartViewModel(repository, const E01Config());
    await viewModel.initialize();
    await viewModel.chooseLanguage(AppLanguage.ru);

    viewModel.searchSurah('78');
    expect(viewModel.visibleSurahs, [78]);
    viewModel.searchSurah('name-78');
    expect(viewModel.visibleSurahs, [78]);
    viewModel.searchSurah('ARABIC');
    expect(viewModel.visibleSurahs, [79]);
    viewModel.searchSurah('');
    expect(viewModel.visibleSurahs, hasLength(114));
    expect(viewModel.surahName(78), 'Test-Name-78');
    expect(viewModel.surahName(79), 'test-arabic-79');
    expect(viewModel.surahName(1), isNull);
    viewModel.dispose();
  });
}
