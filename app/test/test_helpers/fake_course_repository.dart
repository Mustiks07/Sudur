import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:lessons/lessons.dart';
import 'package:sudur/data/repositories/course_repository.dart';

/// The test lesson package of K01 (`TODO_CONTENT` only).
LessonPackage fixtureLessons() => switch (parseLessonPackage(
  File('../packages/testing/fixtures/lessons_test_stage1.json')
      .readAsStringSync(),
)) {
  Ok(:final value) => value,
  Error(:final error) => throw error,
};

/// Course repository over the fixture package; remembers what was written.
final class FakeCourseRepository implements CourseRepository {
  /// Progress written, by lesson.
  final Map<String, LessonProgress> progress = {};

  /// Skills of passed lessons.
  final List<String> skills = [];

  @override
  Future<Result<CourseData>> load() async {
    final package = fixtureLessons();
    return Result.ok(
      CourseData(
        packages: [package],
        states: lessonStates(package, progress, stageOpen: true),
      ),
    );
  }

  @override
  Future<Result<void>> record(
    List<LessonEvent> events,
    LessonProgress? progress,
  ) async {
    if (progress != null) this.progress[progress.lessonId] = progress;
    for (final event in events.whereType<SkillsLearned>()) {
      skills.addAll(event.skills);
    }
    return const Result.ok(null);
  }
}
