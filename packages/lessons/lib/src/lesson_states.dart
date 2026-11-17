import 'package:lessons/src/lesson_engine.dart';
import 'package:lessons/src/lesson_package.dart';

/// States of all lessons of [package], in course order (docs/tz 11.2).
///
/// A lesson with saved progress keeps its state. Otherwise it is available
/// when it is the first lesson of an open stage ([stageOpen]), when the
/// previous lesson of the stage is passed, or when the entry exercise
/// (СТ-05) set the start at [placementStart] or further: every lesson up to
/// and including it is open. Lessons opened by placement are not passed:
/// their skills come only from passing them. If the start is in a later
/// stage, pass the last lesson of this stage as [placementStart].
Map<String, LessonState> lessonStates(
  LessonPackage package,
  Map<String, LessonProgress> saved, {
  required bool stageOpen,
  String? placementStart,
}) {
  final placement = placementStart == null
      ? -1
      : package.lessons.indexWhere((l) => l.id == placementStart);
  final states = <String, LessonState>{};
  LessonState? previous;
  for (final (i, lesson) in package.lessons.indexed) {
    final state = saved[lesson.id]?.state ??
        (((i == 0 && stageOpen) ||
                previous == LessonState.passed ||
                i <= placement)
            ? LessonState.available
            : LessonState.locked);
    states[lesson.id] = state;
    previous = state;
  }
  return states;
}
