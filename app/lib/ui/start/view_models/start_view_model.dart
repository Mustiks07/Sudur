import 'dart:async';

import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';

// UI state fields are deliberately public for ListenableBuilder consumers.
// ignore_for_file: public_member_api_docs, simplify_variable_pattern
// ignore_for_file: unnecessary_type_name_in_constructor
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: prefer_const_declarations

/// State and commands for the resumable first-run flow.
final class StartViewModel extends ChangeNotifier {
  /// Creates the ViewModel.
  StartViewModel(this._repository, this._config);

  final AppUserRepository _repository;
  final E01Config _config;
  Timer? _skeletonTimer;

  OnboardingDraft draft = OnboardingDraft();
  bool loading = true;
  bool showSkeleton = false;
  bool downloading = false;
  bool completed = false;
  String? error;
  double downloadProgress = 0;
  String surahQuery = '';

  /// Loads a profile or the exact interrupted first-run step.
  Future<void> initialize() async {
    loading = true;
    completed = false;
    error = null;
    _skeletonTimer = Timer(_config.skeletonDelay, () {
      showSkeleton = true;
      notifyListeners();
    });
    final profile = await _repository.loadProfile();
    if (profile case Ok(value: final value) when value != null) {
      completed = true;
    } else if (profile case Error(:final error)) {
      this.error = error.toString();
    } else {
      final saved = await _repository.loadOnboardingDraft();
      switch (saved) {
        case Ok(:final value):
          draft = value;
        case Error(:final error):
          this.error = error.toString();
      }
    }
    _skeletonTimer?.cancel();
    loading = false;
    showSkeleton = false;
    notifyListeners();
  }

  /// Filters surah numbers without inventing names outside content data.
  Iterable<int> get visibleSurahs {
    final number = int.tryParse(surahQuery.trim());
    if (surahQuery.trim().isEmpty)
      return Iterable<int>.generate(114, (i) => i + 1);
    return number == null || number < 1 || number > 114
        ? const <int>[]
        : <int>[number];
  }

  Future<void> chooseLanguage(AppLanguage value) =>
      _advance(draft.copyWith(language: value, step: OnboardingStep.path));

  Future<void> choosePath(AppLearningPath value) => _advance(
    draft.copyWith(
      path: value,
      step: value == AppLearningPath.learnReading
          ? OnboardingStep.dailyTime
          : OnboardingStep.familiarSurahs,
    ),
  );

  void searchSurah(String value) {
    surahQuery = value;
    notifyListeners();
  }

  Future<void> toggleSurah(int surah) {
    final selected = draft.familiarSurahs.toSet();
    selected.contains(surah) ? selected.remove(surah) : selected.add(surah);
    return _save(draft.copyWith(familiarSurahs: selected));
  }

  Future<void> finishSurahs() =>
      _advance(draft.copyWith(step: OnboardingStep.dailyTime));

  Future<void> chooseMinutes(int value) {
    if (value <= 0) return Future<void>.value();
    return _advance(
      draft.copyWith(
        dailyMinutes: value,
        step: draft.path == AppLearningPath.learnReading
            ? OnboardingStep.letters
            : OnboardingStep.model,
      ),
    );
  }

  Future<void> chooseModel({required bool downloadNow}) async {
    if (downloadNow) {
      downloading = true;
      error = null;
      notifyListeners();
      final result = await _repository.downloadModel(
        onProgress: (progress) {
          downloadProgress = progress.fraction;
          notifyListeners();
        },
      );
      downloading = false;
      if (result case Error(:final error)) {
        this.error = error.toString();
        notifyListeners();
        return;
      }
    }
    await _advance(
      draft.copyWith(
        downloadModelNow: downloadNow,
        step: OnboardingStep.startPoint,
      ),
    );
  }

  Future<void> chooseStartPoint(AppStartPoint value) {
    final next = draft.path == AppLearningPath.learnReading
        ? OnboardingStep.letters
        : OnboardingStep.completed;
    return _advance(
      draft.copyWith(startPoint: value, step: next),
      finish: next == OnboardingStep.completed,
    );
  }

  Future<void> chooseLetters(LetterKnowledge value) => _advance(
    draft.copyWith(letterKnowledge: value, step: OnboardingStep.completed),
    finish: true,
  );

  /// Returns to the preceding persisted step.
  Future<void> back() {
    final steps = OnboardingStep.values;
    final index = steps.indexOf(draft.step);
    if (index <= 0) return Future<void>.value();
    return _save(draft.copyWith(step: steps[index - 1]));
  }

  Future<void> _advance(OnboardingDraft value, {bool finish = false}) async {
    await _save(value);
    if (!finish || error != null) return;
    final result = await _repository.completeOnboarding(value);
    switch (result) {
      case Ok():
        completed = true;
      case Error(:final error):
        this.error = error.toString();
    }
    notifyListeners();
  }

  Future<void> _save(OnboardingDraft value) async {
    error = null;
    final result = await _repository.saveOnboardingDraft(value);
    switch (result) {
      case Ok():
        draft = value;
      case Error(:final error):
        this.error = error.toString();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    super.dispose();
  }
}
