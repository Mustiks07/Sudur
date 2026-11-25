import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';
import 'package:sudur/data/repositories/reading_repository.dart';

// The class names keep the view model easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor
// ignore_for_file: prefer_initializing_formals

/// Steps of a self-check (docs/tz 13.7).
enum SelfCheckStep {
  /// Preparing the passage.
  preparing,

  /// «Прочитайте про себя …» with the text hidden.
  recall,

  /// The text is open: «Как получилось?».
  rate,

  /// Written.
  done,

  /// The passage could not be prepared.
  error,
}

/// Self-check without a microphone (СП-01…03): available always, with no
/// model and no microphone permission.
final class SelfCheckViewModel extends ChangeNotifier {
  /// Creates the view model.
  SelfCheckViewModel({
    required ReadingRepository reading,
    required AppUserRepository user,
    DateTime Function()? now,
  }) : _reading = reading,
       _user = user,
       _now = now ?? DateTime.now;

  final ReadingRepository _reading;
  final AppUserRepository _user;
  final DateTime Function() _now;
  String? _stepId;
  DateTime? _startedAt;

  /// Current step.
  SelfCheckStep get step => _step;
  SelfCheckStep _step = SelfCheckStep.preparing;

  /// The passage.
  ReadingPassage? get passage => _passage;
  ReadingPassage? _passage;

  /// Prepares [from]–[to]; [stepId] is the step of “Today”.
  Future<void> open({
    required WordKey from,
    required WordKey to,
    String? stepId,
  }) async {
    _stepId = stepId;
    _step = SelfCheckStep.preparing;
    notifyListeners();
    switch (await _reading.prepare(from: from, to: to)) {
      case Ok(:final value):
        _passage = value;
        _startedAt = _now();
        _step = SelfCheckStep.recall;
      case Error():
        _step = SelfCheckStep.error;
    }
    notifyListeners();
  }

  /// «Готово»: the text opens.
  void reveal() {
    if (_step != SelfCheckStep.recall) return;
    _step = SelfCheckStep.rate;
    notifyListeners();
  }

  /// «Вспомнил / С трудом / Не вспомнил»: written into the plan.
  Future<void> rate(SelfCheckAnswer answer) async {
    final passage = _passage;
    if (_step != SelfCheckStep.rate || passage == null) return;
    final startedAt = _startedAt ?? _now();
    final written = await _user.recordSelfCheck(
      SelfCheckResult(
        stepId: _stepId,
        from: passage.from,
        to: passage.to,
        answer: answer,
        startedAt: startedAt,
        duration: _now().difference(startedAt),
      ),
    );
    _step = written is Ok<void> ? SelfCheckStep.done : SelfCheckStep.error;
    notifyListeners();
  }
}
