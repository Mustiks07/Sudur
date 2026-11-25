import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';

// The class names keep the view model easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Where learning is.
enum LearnState {
  /// Loading the plan.
  preparing,

  /// A step is next.
  step,

  /// «Отрывок выучен. Повторим завтра».
  learned,

  /// Could not be prepared.
  error,
}

/// Learning a new passage (docs/tz 13.6, ЗН-01…04).
final class LearnViewModel extends ChangeNotifier {
  /// Creates the view model.
  LearnViewModel(this._repository);

  final AppUserRepository _repository;

  /// Current state.
  LearnState get state => _state;
  LearnState _state = LearnState.preparing;

  /// The plan.
  LearnPlan? get plan => _plan;
  LearnPlan? _plan;

  /// Step of “Today” being learned.
  String? get stepId => _stepId;
  String? _stepId;

  /// Index of the current step.
  int get index => _index;
  var _index = 0;

  /// The current step.
  LearnStep? get current {
    final steps = _plan?.steps ?? const [];
    return _index < steps.length ? steps[_index] : null;
  }

  /// Loads the plan of [stepId]; an unfinished learning continues where it
  /// stopped (ЗН-04).
  Future<void> open(String stepId) async {
    _stepId = stepId;
    switch (await _repository.learnPlan(stepId)) {
      case Ok(:final value):
        _plan = value;
        _index = value.startIndex;
        _state = LearnState.step;
      case Error():
        _state = LearnState.error;
    }
    notifyListeners();
  }

  /// Skips listening (13.6: «Можно пропустить прослушивание»).
  Future<void> skipListening() async {
    final steps = _plan?.steps ?? const <LearnStep>[];
    var next = _index;
    while (next < steps.length && steps[next].kind == LearnStepKind.listen) {
      next++;
    }
    await _moveTo(next);
  }

  /// A reading of the current step ended; [clean] means clean without
  /// hints. «Попробуйте вспомнить» and «Проверьте себя» repeat until clean.
  Future<void> stepFinished({required bool clean}) async {
    final step = current;
    if (step == null || _state != LearnState.step) return;
    final repeat =
        !clean &&
        (step.kind == LearnStepKind.recall || step.kind == LearnStepKind.test);
    if (repeat) {
      // After a failed check, recall comes again before the next check.
      if (step.kind == LearnStepKind.test) await _moveTo(_index - 1);
      return;
    }
    await _moveTo(_index + 1);
  }

  Future<void> _moveTo(int next) async {
    final plan = _plan;
    if (plan == null) return;
    _index = next;
    await _repository.saveLearnProgress(
      plan.unitId,
      next >= plan.steps.length ? 0 : next,
    );
    if (next >= plan.steps.length) _state = LearnState.learned;
    notifyListeners();
  }
}
