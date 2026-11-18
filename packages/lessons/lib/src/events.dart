import 'package:contracts/contracts.dart';
import 'package:lessons/src/answers.dart';
import 'package:meta/meta.dart';

/// What the lesson engine tells the app. The app writes them to the user
/// database and turns them into plan units; the engine stores nothing.
@immutable
sealed class LessonEvent {
  const LessonEvent({required this.lessonId});

  /// The lesson.
  final String lessonId;
}

/// A step was done (docs/tz 4.5, `LessonStepCompleted`).
final class LessonStepCompleted extends LessonEvent {
  /// Creates the event.
  const LessonStepCompleted({
    required super.lessonId,
    required this.stepId,
    required this.result,
    required this.inQuiz,
    required this.at,
  });

  /// The step.
  final String stepId;

  /// Its result.
  final StepResult result;

  /// Asked as a mini-quiz question.
  final bool inQuiz;

  /// When, from the injected clock.
  final DateTime at;
}

/// The recording of a `repeatAndCompare` step is no longer needed: the step
/// ended and the person did not save it (УЧ-06). The app deletes it from
/// memory. The engine never holds the sound itself.
final class RecordingNoLongerNeeded extends LessonEvent {
  /// Creates the event.
  const RecordingNoLongerNeeded({
    required super.lessonId,
    required this.stepId,
  });

  /// The recording step.
  final String stepId;
}

/// The mini-quiz ended (УЧ-04).
final class QuizFinished extends LessonEvent {
  /// Creates the event.
  const QuizFinished({
    required super.lessonId,
    required this.score,
    required this.hardStepIds,
  });

  /// Score and pass mark.
  final QuizScored score;

  /// Steps to repeat if the quiz was not passed, in lesson order.
  final List<String> hardStepIds;
}

/// The lesson is passed.
final class LessonPassed extends LessonEvent {
  /// Creates the event.
  const LessonPassed({
    required super.lessonId,
    required this.quizPercent,
    required this.at,
  });

  /// Quiz percent; `null` for a lesson without a quiz.
  final double? quizPercent;

  /// When, from the injected clock.
  final DateTime at;
}

/// Skills of a lesson passed for the first time are learned (УЧ-05). The app
/// creates plan units of kind `skill` from them (PL01).
final class SkillsLearned extends LessonEvent {
  /// Creates the event.
  const SkillsLearned({
    required super.lessonId,
    required this.skills,
    required this.at,
  });

  /// Skill ids (`letter:ba`).
  final List<String> skills;

  /// When, from the injected clock.
  final DateTime at;
}

/// After supported reading of a short surah: offer to memorize it (УЧ-07).
final class MemorizeSuggested extends LessonEvent {
  /// Creates the event.
  const MemorizeSuggested({
    required super.lessonId,
    required this.from,
    required this.to,
  });

  /// First word.
  final WordKey from;

  /// Last word.
  final WordKey to;
}
