import 'package:lessons/src/lesson_engine.dart';
import 'package:lessons/src/lesson_package.dart';

/// Saved states that are learning progress, never computed again.
const Set<LessonState> _learning = {
  LessonState.inProgress,
  LessonState.quiz,
  LessonState.passed,
  LessonState.failed,
};

/// States of all lessons of [package], in course order (docs/tz 11.2).
///
/// Saved learning progress (`inProgress`, `quiz`, `passed`, `failed`) is
/// kept as it is. A lesson without such progress — none saved, or saved as
/// `locked` / `available` — is available when it is the first lesson of an
/// open stage ([stageOpen]), when the previous lesson of the stage is
/// passed, or when the entry exercise (СТ-05) set the start at
/// [placementStart] or further: every lesson up to and including it is
/// open. A lesson once saved as `available` stays open. Otherwise it is
/// locked. A saved `locked` is only a snapshot: it is computed again, so a
/// lesson opens as soon as its predecessor is passed.
///
/// Lessons opened by placement are not passed: their skills come only from
/// passing them. If the start is in a later stage, pass the last lesson of
/// this stage as [placementStart].
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
    final stored = saved[lesson.id]?.state;
    final open = (i == 0 && stageOpen) ||
        previous == LessonState.passed ||
        i <= placement ||
        stored == LessonState.available;
    final state = switch (stored) {
      final LessonState s when _learning.contains(s) => s,
      _ => open ? LessonState.available : LessonState.locked,
    };
    states[lesson.id] = state;
    previous = state;
  }
  return states;
}
