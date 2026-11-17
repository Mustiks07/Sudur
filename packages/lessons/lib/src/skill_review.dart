import 'dart:math';

import 'package:contracts/contracts.dart';
import 'package:lessons/src/answers.dart';
import 'package:lessons/src/lesson_package.dart';
import 'package:lessons/src/lesson_params.dart';
import 'package:lessons/src/steps.dart';
import 'package:meta/meta.dart';

/// FSRS grade of a skill review (docs/tz 11.2): all right — «Хорошо», one
/// mistake — «Трудно», more — «Забыл». The app maps it to the planner's
/// rating.
enum SkillGrade {
  /// «Хорошо».
  good,

  /// «Трудно».
  hard,

  /// «Забыл».
  again,
}

/// The grade for [mistakes] in one review: the rule of docs/tz 11.2.
SkillGrade gradeSkillReview(int mistakes) => switch (mistakes) {
      <= 0 => SkillGrade.good,
      1 => SkillGrade.hard,
      _ => SkillGrade.again,
    };

/// No question of the review types is marked with the skill.
final class NoReviewQuestions implements Exception {
  /// Creates the error.
  const NoReviewQuestions(this.skill);

  /// The skill.
  final String skill;

  @override
  String toString() => 'No review questions for $skill';
}

/// One review of a skill: questions, answers so far.
@immutable
final class SkillReviewRun {
  const SkillReviewRun._(
    this.skill,
    this.questions,
    this.position,
    this.mistakes,
  );

  /// The skill.
  final String skill;

  /// Questions to ask, in order.
  final List<LessonStep> questions;

  /// Index of the current question.
  final int position;

  /// Wrong answers so far.
  final int mistakes;

  /// The question to ask now; `null` when the review is over.
  LessonStep? get current =>
      position < questions.length ? questions[position] : null;

  /// The grade once the review is over.
  SkillGrade? get grade => current == null ? gradeSkillReview(mistakes) : null;
}

/// Reviews a learned skill (УЧ-05, docs/tz 11.2): asks up to
/// `skillReviewQuestions` steps of the types `hearAndChoose`, `seeAndChoose`,
/// `pairDiscriminate`, `findRule` marked with the skill, picked at random.
@immutable
final class SkillReviewer {
  /// Creates the reviewer.
  const SkillReviewer({required this.params, required this.random});

  /// Lesson parameters.
  final LessonParams params;

  /// The injected source of randomness.
  final Random random;

  /// Picks questions for [skill] from [packages]. With fewer marked
  /// questions than needed, asks all of them.
  Result<SkillReviewRun> start(String skill, Iterable<LessonPackage> packages) {
    final pool = [
      for (final p in packages)
        for (final l in p.lessons)
          for (final s in l.steps)
            if (s.type.isSkillReviewQuestion && s.skills.contains(skill)) s,
    ];
    if (pool.isEmpty) return Result.error(NoReviewQuestions(skill));
    pool.shuffle(random);
    return Result.ok(
      SkillReviewRun._(
        skill,
        List.unmodifiable(pool.take(params.skillReviewQuestions)),
        0,
        0,
      ),
    );
  }

  /// Takes [answer] for the current question.
  Result<SkillReviewRun> answer(SkillReviewRun run, StepAnswer answer) {
    final step = run.current;
    if (step == null) {
      return Result.error(NoReviewQuestions(run.skill));
    }
    return switch (scoreStep(step, answer)) {
      Ok(:final value) => Result.ok(
          SkillReviewRun._(
            run.skill,
            run.questions,
            run.position + 1,
            run.mistakes + (value.correct == true ? 0 : 1),
          ),
        ),
      Error(:final error) => Result.error(error),
    };
  }
}
