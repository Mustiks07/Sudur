import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';
import 'package:sudur/data/services/notification_service.dart';

// The class names keep the view models easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

/// «Прогресс» (docs/tz 13.12): memory state of every surah in the plan.
final class ProgressViewModel extends ChangeNotifier {
  /// Creates the view model.
  ProgressViewModel(this._repository);

  final AppUserRepository _repository;

  /// Surahs in the plan; `null` while loading.
  List<SurahProgress>? get surahs => _surahs;
  List<SurahProgress>? _surahs;

  /// Whether loading failed.
  bool get failed => _failed;
  var _failed = false;

  /// The surah [number], if it is in the plan.
  SurahProgress? surah(int number) =>
      _surahs?.where((s) => s.surah == number).firstOrNull;

  /// Loads the progress.
  Future<void> load() async {
    switch (await _repository.loadProgress()) {
      case Ok(:final value):
        _surahs = value;
        _failed = false;
      case Error():
        _failed = true;
    }
    notifyListeners();
  }
}

/// Reminder settings (docs/tz 11.8, 13.14).
final class RemindersViewModel extends ChangeNotifier {
  /// Creates the view model.
  RemindersViewModel(this._repository, this._notifications, this._config);

  final AppUserRepository _repository;
  final NotificationService _notifications;
  final E01Config _config;

  /// Reminder times, minutes after midnight.
  List<int> get times => _times;
  List<int> _times = const [];

  /// Whether another time can be added (at most `maxRemindersPerDay`).
  bool get canAdd => _times.length < _config.maxRemindersPerDay;

  /// Loads the times.
  Future<void> load() async {
    if (await _repository.loadReminders() case Ok(:final value)) {
      _times = value;
      notifyListeners();
    }
  }

  /// Adds a time.
  Future<void> add(int minuteOfDay, String text) =>
      _save([..._times, minuteOfDay], text);

  /// Removes a time; with none left reminders are off.
  Future<void> remove(int minuteOfDay, String text) =>
      _save([..._times.where((t) => t != minuteOfDay)], text);

  Future<void> _save(List<int> times, String text) async {
    if (await _repository.saveReminders(times) case Ok(:final value)) {
      _times = value;
      await _notifications.scheduleDaily(value, text);
      notifyListeners();
    }
  }
}
