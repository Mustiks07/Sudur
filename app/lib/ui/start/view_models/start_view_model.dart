import 'dart:async';

import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';

// UI state fields are deliberately public for ListenableBuilder consumers.
// ignore_for_file: public_member_api_docs, simplify_variable_pattern
// ignore_for_file: unnecessary_type_name_in_constructor

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

  /// Surah names from the content package; numbers only where it has none.
  Map<int, SurahNameData> surahNames = const {};

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
      // Names only help the search: without them the list shows numbers.
      if (await _repository.loadSurahNames() case Ok(:final value)) {
        surahNames = value;
      }
    }
    _skeletonTimer?.cancel();
    loading = false;
    showSkeleton = false;
    notifyListeners();
  }

  /// Surahs matching the search: by number, or by any name the content
  /// package has (names are never written in code).
  Iterable<int> get visibleSurahs {
    final query = surahQuery.trim().toLowerCase();
    final all = Iterable<int>.generate(114, (i) => i + 1);
    if (query.isEmpty) return all;
    final number = int.tryParse(query);
    if (number != null) return all.where((surah) => surah == number);
    return all.where(
      (surah) => (surahNames[surah]?.all ?? const <String>[]).any(
        (name) => name.toLowerCase().contains(query),
      ),
    );
  }

  /// Name of [surah] for the list, or `null` if the content has none.
  String? surahName(int surah) =>
      surahNames[surah]?.nameIn(draft.language ?? AppLanguage.ru);

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
      draft.copyWith(downloadModelNow: downloadNow, step: _afterModel),
      finish: _afterModel == OnboardingStep.completed,
    );
  }

  /// “Where to start” is asked only when nothing is familiar (13.1).
  OnboardingStep get _afterModel => draft.familiarSurahs.isEmpty
      ? OnboardingStep.startPoint
      : OnboardingStep.completed;

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

  /// Returns to the step shown before this one on the user's own route
  /// (docs/tz 13.1: back is possible on every step).
  Future<void> back() {
    final route = _route(draft);
    final index = route.indexOf(draft.step);
    if (index <= 0) return Future<void>.value();
    return _save(draft.copyWith(step: route[index - 1]));
  }

  /// Steps of the start in the order the user sees them for their choices.
  static List<OnboardingStep> _route(OnboardingDraft draft) => [
    OnboardingStep.language,
    OnboardingStep.path,
    if (draft.path == AppLearningPath.learnReading) ...[
      OnboardingStep.dailyTime,
      OnboardingStep.letters,
    ] else ...[
      OnboardingStep.familiarSurahs,
      OnboardingStep.dailyTime,
      OnboardingStep.model,
      if (draft.familiarSurahs.isEmpty) OnboardingStep.startPoint,
    ],
    OnboardingStep.completed,
  ];

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
