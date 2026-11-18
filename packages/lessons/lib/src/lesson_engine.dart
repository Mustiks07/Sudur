import 'package:contracts/contracts.dart';
import 'package:lessons/src/answers.dart';
import 'package:lessons/src/events.dart';
import 'package:lessons/src/lesson_package.dart';
import 'package:lessons/src/lesson_params.dart';
import 'package:lessons/src/steps.dart';
import 'package:meta/meta.dart';

/// State of a lesson (docs/tz 11.2):
///
/// ```text
/// locked → available → inProgress(step) → quiz → passed
///                                 quiz ↘ failed → inProgress (hard steps)
/// ```
enum LessonState {
  /// Not open yet.
  locked,

  /// Open, not started.
  available,

  /// Steps are being taken.
  inProgress,

  /// The mini-quiz is being taken.
  quiz,

  /// Passed.
  passed,

  /// The mini-quiz was not passed; hard steps are to be repeated.
  failed,
}

/// Saved progress of a lesson: the `lesson_progress` row of the user
/// database (docs/tz 12.1) without `updated_at`.
@immutable
final class LessonProgress {
  /// Creates the progress.
  const LessonProgress({
    required this.lessonId,
    required this.state,
    required this.stepIndex,
    required this.quizPercent,
    required this.contentVersion,
  });

  /// The lesson.
  final String lessonId;

  /// Its state.
  final LessonState state;

  /// Index into the lesson's steps where to go on.
  final int stepIndex;

  /// Last quiz percent, if any.
  final double? quizPercent;

  /// Version of the lesson package the progress was made on.
  final String contentVersion;

  @override
  bool operator ==(Object other) =>
      other is LessonProgress &&
      other.lessonId == lessonId &&
      other.state == state &&
      other.stepIndex == stepIndex &&
      other.quizPercent == quizPercent &&
      other.contentVersion == contentVersion;

  @override
  int get hashCode =>
      Object.hash(lessonId, state, stepIndex, quizPercent, contentVersion);

  @override
  String toString() =>
      'LessonProgress($lessonId, ${state.name}, step $stepIndex, '
      'quiz $quizPercent, $contentVersion)';
}

/// The engine was asked something the lesson state does not allow.
final class LessonStateException implements Exception {
  /// Creates the error.
  const LessonStateException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'Lesson: $message';
}

/// One run through a lesson. Immutable: every engine call returns a new run.
@immutable
final class LessonRun {
  const LessonRun._({
    required this.lesson,
    required this.state,
    required this.queue,
    required this.position,
    required this.hardStepIds,
    required this.quizRight,
    required this.quizScore,
    required this.wasPassed,
  });

  /// The lesson.
  final Lesson lesson;

  /// Current state: [LessonState.inProgress], [LessonState.quiz],
  /// [LessonState.passed] or [LessonState.failed].
  final LessonState state;

  /// Steps of the current pass: all steps before the quiz, the hard steps
  /// on a repeat, or the quiz questions.
  final List<LessonStep> queue;

  /// Index of the current step in [queue].
  final int position;

  /// Hard steps found so far in this pass; in [LessonState.failed] — the
  /// steps to repeat, in lesson order.
  final List<String> hardStepIds;

  /// Quiz questions answered right so far.
  final int quizRight;

  /// The last quiz score of this run.
  final QuizScored? quizScore;

  /// The lesson had been passed before this run (a replay).
  final bool wasPassed;

  /// The step to take now; `null` when passed or failed.
  LessonStep? get current =>
      (state == LessonState.inProgress || state == LessonState.quiz) &&
              position < queue.length
          ? queue[position]
          : null;

  LessonRun _copy({
    LessonState? state,
    List<LessonStep>? queue,
    int? position,
    List<String>? hardStepIds,
    int? quizRight,
    QuizScored? quizScore,
  }) =>
      LessonRun._(
        lesson: lesson,
        state: state ?? this.state,
        queue: queue ?? this.queue,
        position: position ?? this.position,
        hardStepIds: hardStepIds ?? this.hardStepIds,
        quizRight: quizRight ?? this.quizRight,
        quizScore: quizScore ?? this.quizScore,
        wasPassed: wasPassed,
      );
}

/// A new run and the events of the call that made it.
@immutable
final class LessonTransition {
  /// Creates the transition.
  const LessonTransition(this.run, this.events);

  /// The run after the call.
  final LessonRun run;

  /// Events to write, in order.
  final List<LessonEvent> events;
}

/// Plays lessons of a lesson package (docs/tz 3.1, 11.2).
///
/// Holds only settings; every call takes a [LessonRun] and returns a new one.
/// Time comes from [clock].
@immutable
final class LessonEngine {
  /// Creates the engine. [pronunciationCheck] — whether the automatic check
  /// of `speakAndCheck` exists (trial И-5); without it such steps are
  /// assessed by the person, like `repeatAndCompare` (МС-04).
  const LessonEngine({
    required this.params,
    required this.clock,
    this.pronunciationCheck = false,
  });

  /// Lesson parameters.
  final LessonParams params;

  /// The injected clock.
  final DateTime Function() clock;

  /// Whether the automatic pronunciation check is available.
  final bool pronunciationCheck;

  /// Starts [lesson] from its first step. [state] is its state now (see
  /// `lessonStates`): a locked lesson cannot be started; a passed one is
  /// replayed and stays passed.
  Result<LessonRun> start(Lesson lesson, LessonState state) {
    if (state == LessonState.locked) {
      return Result.error(LessonStateException('${lesson.id} is locked'));
    }
    return Result.ok(
      LessonRun._(
        lesson: lesson,
        state: LessonState.inProgress,
        queue: lesson.learningSteps,
        position: 0,
        hardStepIds: const [],
        quizRight: 0,
        quizScore: null,
        wasPassed: state == LessonState.passed,
      ),
    );
  }

  /// Takes [answer] for the current step of [run].
  Result<LessonTransition> answer(LessonRun run, StepAnswer answer) {
    final step = run.current;
    if (step == null) {
      return Result.error(
        LessonStateException('no step to answer in ${run.state.name}'),
      );
    }
    final StepResult result;
    switch (scoreStep(step, answer, pronunciationCheck: pronunciationCheck)) {
      case Ok(:final value):
        result = value;
      case Error(:final error):
        return Result.error(error);
    }
    final lessonId = run.lesson.id;
    final inQuiz = run.state == LessonState.quiz;
    final events = <LessonEvent>[
      LessonStepCompleted(
        lessonId: lessonId,
        stepId: step.id,
        result: result,
        inQuiz: inQuiz,
        at: clock(),
      ),
      if (step.type.records && !keepsRecording(answer))
        RecordingNoLongerNeeded(lessonId: lessonId, stepId: step.id),
      if (step
          case ReadSupportedStep(offerMemorize: true, :final from, :final to))
        MemorizeSuggested(lessonId: lessonId, from: from, to: to),
    ];
    final hard = [
      ...run.hardStepIds,
      if (result.hard && !run.hardStepIds.contains(step.id)) step.id,
    ];
    final next = run._copy(
      position: run.position + 1,
      hardStepIds: hard,
      quizRight: run.quizRight + (inQuiz && result.correct == true ? 1 : 0),
    );
    if (next.position < next.queue.length) {
      return Result.ok(LessonTransition(next, events));
    }
    return Result.ok(
      inQuiz ? _finishQuiz(next, events) : _finishSteps(next, events),
    );
  }

  /// Starts repeating the hard steps of a failed run; the quiz follows.
  Result<LessonRun> retry(LessonRun run) {
    if (run.state != LessonState.failed) {
      return Result.error(
        LessonStateException('only a failed lesson is repeated, '
            'this one is ${run.state.name}'),
      );
    }
    final hard = [
      for (final s in run.lesson.learningSteps)
        if (run.hardStepIds.contains(s.id)) s,
    ];
    return Result.ok(
      run._copy(
        state: LessonState.inProgress,
        // Hard steps unknown (resumed from saved progress): all steps.
        queue: hard.isEmpty ? run.lesson.learningSteps : hard,
        position: 0,
        hardStepIds: const [],
        quizRight: 0,
      ),
    );
  }

  /// The person leaves the lesson. Returns the events to write: a recording
  /// of the current step is no longer needed (УЧ-06). Save [progress] to go
  /// on later.
  List<LessonEvent> leave(LessonRun run) => [
        if (run.current case final step? when step.type.records)
          RecordingNoLongerNeeded(lessonId: run.lesson.id, stepId: step.id),
      ];

  /// Progress of [run] to save; `null` while a replay of a passed lesson is
  /// not passed again — keep the saved progress then.
  LessonProgress? progress(LessonRun run, {required String contentVersion}) {
    if (run.wasPassed && run.state != LessonState.passed) return null;
    final steps = run.lesson.steps;
    final index = switch (run.state) {
      LessonState.inProgress => switch (run.current) {
          final step? => run.lesson.indexOf(step.id),
          null => steps.length,
        },
      LessonState.quiz || LessonState.failed => steps.length - 1,
      _ => steps.length,
    };
    return LessonProgress(
      lessonId: run.lesson.id,
      state: run.state,
      stepIndex: index,
      quizPercent: run.quizScore?.percent,
      contentVersion: contentVersion,
    );
  }

  /// Goes on with [lesson] from [saved] progress. If the package version
  /// changed, an unfinished lesson starts over. A failed lesson resumes as
  /// failed; which steps were hard is not saved, so its repeat takes all
  /// steps.
  Result<LessonRun> resume(
    Lesson lesson,
    LessonProgress saved, {
    required String contentVersion,
  }) {
    if (saved.lessonId != lesson.id) {
      return Result.error(
        LessonStateException('progress of ${saved.lessonId} for ${lesson.id}'),
      );
    }
    final sameContent = saved.contentVersion == contentVersion;
    LessonRun run(LessonState state, List<LessonStep> queue, int position) =>
        LessonRun._(
          lesson: lesson,
          state: state,
          queue: queue,
          position: position,
          hardStepIds: const [],
          quizRight: 0,
          quizScore: null,
          wasPassed: saved.state == LessonState.passed,
        );
    final learning = lesson.learningSteps;
    final quiz = lesson.quiz;
    return switch (saved.state) {
      LessonState.locked || LessonState.available => Result.error(
          LessonStateException('${lesson.id} has no progress to resume'),
        ),
      LessonState.passed => Result.ok(run(LessonState.passed, const [], 0)),
      LessonState.inProgress when !sameContent =>
        Result.ok(run(LessonState.inProgress, learning, 0)),
      LessonState.inProgress
          when saved.stepIndex >= 0 && saved.stepIndex < learning.length =>
        Result.ok(run(LessonState.inProgress, learning, saved.stepIndex)),
      LessonState.inProgress || LessonState.quiz => Result.ok(
          sameContent && quiz != null
              ? run(LessonState.quiz, _questions(lesson, quiz), 0)
              : run(LessonState.inProgress, learning, 0),
        ),
      LessonState.failed => Result.ok(
          sameContent && quiz != null
              ? run(LessonState.failed, const [], 0)
              : run(LessonState.inProgress, learning, 0),
        ),
    };
  }

  LessonTransition _finishSteps(LessonRun run, List<LessonEvent> events) {
    final quiz = run.lesson.quiz;
    if (quiz == null) return _pass(run, events, null);
    return LessonTransition(
      run._copy(
        state: LessonState.quiz,
        queue: _questions(run.lesson, quiz),
        position: 0,
        quizRight: 0,
      ),
      events,
    );
  }

  LessonTransition _finishQuiz(LessonRun run, List<LessonEvent> events) {
    // The quiz is the last step when a run is in the quiz state.
    final quiz = run.lesson.quiz;
    final score = QuizScored(
      right: run.quizRight,
      total: run.queue.length,
      passPercent: quiz?.passPercent ?? params.quizPassPercent,
    );
    final hard = [
      for (final s in run.lesson.steps)
        if (run.hardStepIds.contains(s.id)) s.id,
    ];
    final withQuiz = [
      ...events,
      if (quiz != null)
        LessonStepCompleted(
          lessonId: run.lesson.id,
          stepId: quiz.id,
          result: score,
          inQuiz: true,
          at: clock(),
        ),
      QuizFinished(
        lessonId: run.lesson.id,
        score: score,
        hardStepIds: score.passed ? const [] : hard,
      ),
    ];
    final scored = run._copy(quizScore: score);
    if (score.passed) return _pass(scored, withQuiz, score.percent);
    return LessonTransition(
      scored._copy(
        state: LessonState.failed,
        queue: const [],
        position: 0,
        hardStepIds: hard,
      ),
      withQuiz,
    );
  }

  LessonTransition _pass(
    LessonRun run,
    List<LessonEvent> events,
    double? percent,
  ) {
    final at = clock();
    return LessonTransition(
      run._copy(state: LessonState.passed, queue: const [], position: 0),
      [
        ...events,
        LessonPassed(lessonId: run.lesson.id, quizPercent: percent, at: at),
        if (!run.wasPassed)
          SkillsLearned(
            lessonId: run.lesson.id,
            skills: run.lesson.skills,
            at: at,
          ),
      ],
    );
  }

  static List<LessonStep> _questions(Lesson lesson, QuizStep quiz) => [
        for (final id in quiz.stepIds)
          if (lesson.step(id) case final step?) step,
      ];
}
