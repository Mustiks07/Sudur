import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:lessons/lessons.dart';
import 'package:sudur/data/repositories/course_repository.dart';

// The class names keep the view models easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

/// The course path (docs/tz 13.9).
final class CourseViewModel extends ChangeNotifier {
  /// Creates the view model.
  CourseViewModel(this._repository);

  final CourseRepository _repository;

  /// The course; `null` while loading or after an error.
  CourseData? get data => _data;
  CourseData? _data;

  /// Whether loading failed.
  bool get failed => _failed;
  var _failed = false;

  /// Loads the installed stages and the progress.
  Future<void> load() async {
    switch (await _repository.load()) {
      case Ok(:final value):
        _data = value;
        _failed = false;
      case Error():
        _failed = true;
    }
    notifyListeners();
  }
}

/// One lesson played by [LessonEngine] (docs/tz 13.10).
final class LessonViewModel extends ChangeNotifier {
  /// Creates the view model.
  LessonViewModel(this._repository, this._engine);

  final CourseRepository _repository;
  final LessonEngine _engine;
  String _contentVersion = '';

  /// The run; `null` before the start or after an error.
  LessonRun? get run => _run;
  LessonRun? _run;

  /// Result of the last answered step: feedback without penalty (13.10).
  StepResult? get lastResult => _lastResult;
  StepResult? _lastResult;

  /// Whether the lesson could not be started.
  bool get failed => _failed;
  var _failed = false;

  /// Starts [lessonId] of [course].
  Future<void> start(CourseData course, String lessonId) async {
    final lesson = course.lesson(lessonId);
    final state = course.states[lessonId];
    if (lesson == null || state == null) {
      _failed = true;
      notifyListeners();
      return;
    }
    _contentVersion = course.packages
        .firstWhere((p) => p.lessons.contains(lesson))
        .version;
    switch (_engine.start(lesson, state)) {
      case Ok(:final value):
        _run = value;
      case Error():
        _failed = true;
    }
    notifyListeners();
  }

  /// Answers the current step; progress and skills are written (11.2).
  Future<void> answer(StepAnswer answer) async {
    final run = _run;
    if (run == null) return;
    switch (_engine.answer(run, answer)) {
      case Ok(:final value):
        _run = value.run;
        _lastResult = value.events
            .whereType<LessonStepCompleted>()
            .lastOrNull
            ?.result;
        await _repository.record(
          value.events,
          _engine.progress(value.run, contentVersion: _contentVersion),
        );
      case Error():
        _failed = true;
    }
    notifyListeners();
  }

  /// «Повторим трудное» after a failed mini-check (13.10).
  void retry() {
    final run = _run;
    if (run == null) return;
    if (_engine.retry(run) case Ok(:final value)) {
      _run = value;
      _lastResult = null;
      notifyListeners();
    }
  }
}
