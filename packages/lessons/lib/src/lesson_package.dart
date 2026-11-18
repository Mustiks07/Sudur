import 'package:lessons/src/localized_text.dart';
import 'package:lessons/src/steps.dart';
import 'package:meta/meta.dart';

/// One lesson: steps, skills, mini-quiz (docs/tz 3.1, 11.2).
@immutable
final class Lesson {
  /// Creates a lesson. [steps] end with at most one [QuizStep].
  const Lesson({
    required this.id,
    required this.title,
    required this.skills,
    required this.steps,
  });

  /// Lesson id, unique across the course (`stage1-letters-01`).
  final String id;

  /// Lesson title.
  final LocalizedText title;

  /// Skills the lesson teaches; they become plan units once it is passed
  /// (УЧ-05).
  final List<String> skills;

  /// Steps in order; the quiz, if any, is the last.
  final List<LessonStep> steps;

  /// The mini-quiz, if the lesson has one.
  QuizStep? get quiz => switch (steps.lastOrNull) {
        final QuizStep q => q,
        _ => null,
      };

  /// Steps taken before the quiz.
  List<LessonStep> get learningSteps =>
      quiz == null ? steps : steps.sublist(0, steps.length - 1);

  /// The step with [id], or `null`.
  LessonStep? step(String id) {
    for (final s in steps) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Index of the step with [id] in [steps], or -1.
  int indexOf(String id) => steps.indexWhere((s) => s.id == id);
}

/// A lesson package: one stage of the course (docs/tz 4.9, 12.3).
@immutable
final class LessonPackage {
  /// Creates a package.
  const LessonPackage({
    required this.format,
    required this.packageId,
    required this.version,
    required this.stage,
    required this.title,
    required this.lessons,
    required this.todoPaths,
  });

  /// Format of the package JSON this engine reads.
  static const int currentFormat = 1;

  /// Format of the file.
  final int format;

  /// Package id (`stage1-letters`).
  final String packageId;

  /// Content version; saved with lesson progress (`content_version`).
  final String version;

  /// Stage number of the course (docs/tz 16.9).
  final int stage;

  /// Stage title.
  final LocalizedText title;

  /// Lessons in course order.
  final List<Lesson> lessons;

  /// JSON paths of texts that are still [todoContent]. A release package has
  /// none (docs/tz 4.9; the check is done by `content_build`).
  final List<String> todoPaths;

  /// Whether the package may ship: no [todoContent] anywhere.
  bool get isReleaseReady => todoPaths.isEmpty;

  /// Every package file referenced by the lessons, for the installer to
  /// check.
  Set<String> get media => {
        for (final l in lessons)
          for (final s in l.steps) ...s.media,
      };

  /// The lesson with [id], or `null`.
  Lesson? lesson(String id) {
    for (final l in lessons) {
      if (l.id == id) return l;
    }
    return null;
  }
}
