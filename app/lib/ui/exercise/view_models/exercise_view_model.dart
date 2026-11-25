import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:sudur/data/repositories/exercise_repository.dart';

// The class names keep the view model easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Where an exercise is.
enum ExerciseState {
  /// Building the steps.
  preparing,

  /// A step is next.
  step,

  /// The place is fixed (УП-07).
  closed,

  /// Not clean: back to it tomorrow.
  again,

  /// Could not be prepared.
  error,
}

/// An exercise after a mistake (docs/tz 13.5, УП-01…07): every step is the
/// same reading (13.3) on a small range, in the mode of the step.
final class ExerciseViewModel extends ChangeNotifier {
  /// Creates the view model.
  ExerciseViewModel(this._repository);

  final ExerciseRepository _repository;
  String? _parentUnitId;

  /// Current state.
  ExerciseState get state => _state;
  ExerciseState _state = ExerciseState.preparing;

  /// The exercise.
  ExercisePlanData? get plan => _plan;
  ExercisePlanData? _plan;

  /// Index of the next step.
  int get index => _index;
  var _index = 0;

  /// The next step.
  ExerciseStepData? get current {
    final steps = _plan?.steps ?? const [];
    return _index < steps.length ? steps[_index] : null;
  }

  /// Builds the exercise for [check]; [parentUnitId] is the unit it came
  /// from.
  Future<void> open(CheckEvent check, {String? parentUnitId}) async {
    _parentUnitId = parentUnitId;
    switch (await _repository.plan(check)) {
      case Ok(:final value) when value.steps.isNotEmpty:
        _plan = value;
        _state = ExerciseState.step;
      case Ok() || Error():
        _state = ExerciseState.error;
    }
    notifyListeners();
  }

  /// The reading of the current step ended; [clean] is its result. After the
  /// last step the exercise is closed when it was clean (УП-07).
  Future<void> stepFinished({required bool clean}) async {
    final plan = _plan;
    if (plan == null || _state != ExerciseState.step) return;
    final last = _index == plan.steps.length - 1;
    if (!last) {
      _index++;
      notifyListeners();
      return;
    }
    await _repository.finish(
      plan: plan,
      closed: clean,
      parentUnitId: _parentUnitId,
    );
    _state = clean ? ExerciseState.closed : ExerciseState.again;
    notifyListeners();
  }
}
