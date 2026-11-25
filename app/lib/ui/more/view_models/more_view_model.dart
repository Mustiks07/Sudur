import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';

// UI state fields are deliberately public for ListenableBuilder consumers.
// ignore_for_file: public_member_api_docs, unnecessary_this
// ignore_for_file: unnecessary_type_name_in_constructor

/// State and commands for settings, downloads, and user data.
final class MoreViewModel extends ChangeNotifier {
  /// Creates the ViewModel.
  MoreViewModel(this._repository);

  final AppUserRepository _repository;

  MoreSettingsData? settings;
  List<AppDownloadData> downloads = const [];
  bool loading = false;
  String? error;
  String? notice;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    final settingsResult = await _repository.loadMoreSettings();
    final downloadsResult = await _repository.listDownloads();
    switch (settingsResult) {
      case Ok(:final value):
        settings = value;
      case Error(:final error):
        this.error = error.toString();
    }
    switch (downloadsResult) {
      case Ok(:final value):
        downloads = value;
      case Error(:final error):
        this.error = error.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> updateStudySettings({
    required int dailyMinutes,
    required bool strictBehavior,
    required bool showFirstWord,
    required int listenRepeats,
    required int supportedRepeats,
  }) async {
    final result = await _repository.updateStudySettings(
      dailyMinutes: dailyMinutes,
      strictBehavior: strictBehavior,
      showFirstWord: showFirstWord,
      listenRepeats: listenRepeats,
      supportedRepeats: supportedRepeats,
    );
    if (result case Ok(:final value)) settings = value;
    if (result case Error(:final error)) this.error = error.toString();
    notifyListeners();
  }

  Future<void> updateLanguage(AppLanguage language) async {
    final result = await _repository.updateLanguage(language);
    if (result case Ok(value: final profile)) {
      final current = settings;
      if (current != null) {
        settings = MoreSettingsData(
          profile: profile,
          listenRepeats: current.listenRepeats,
          supportedRepeats: current.supportedRepeats,
        );
      }
    }
    if (result case Error(:final error)) this.error = error.toString();
    notifyListeners();
  }

  Future<void> deleteModels() async {
    final result = await _repository.deleteModels();
    if (result case Error(:final error)) this.error = error.toString();
    await initialize();
  }

  Future<void> exportData() => _action(_repository.exportUserData());

  Future<void> importData() async {
    final result = await _repository.importUserData();
    if (result case Ok(value: true)) await initialize();
    if (result case Error(:final error)) this.error = error.toString();
    notifyListeners();
  }

  Future<void> eraseAll() => _action(_repository.eraseAllUserData());

  Future<void> _action(Future<Result<void>> operation) async {
    final result = await operation;
    if (result case Error(:final error)) this.error = error.toString();
    notifyListeners();
  }
}
