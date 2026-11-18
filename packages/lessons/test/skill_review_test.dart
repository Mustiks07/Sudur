import 'dart:math';

import 'package:contracts/contracts.dart';
import 'package:lessons/lessons.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late LessonPackage p;
  setUpAll(() => p = fixture());

  SkillReviewer reviewer([int seed = 1]) =>
      SkillReviewer(params: LessonParams.defaults, random: Random(seed));

  test('grade: all right good, one mistake hard, more again (11.2)', () {
    expect(gradeSkillReview(0), SkillGrade.good);
    expect(gradeSkillReview(1), SkillGrade.hard);
    expect(gradeSkillReview(2), SkillGrade.again);
    expect(gradeSkillReview(3), SkillGrade.again);
  });

  test('asks 3 marked questions of the review types', () {
    final run = ok(reviewer().start('letter:ba', [p]));
    expect(
      run.questions,
      hasLength(LessonParams.defaults.skillReviewQuestions),
    );
    for (final q in run.questions) {
      expect(q.type.isSkillReviewQuestion, isTrue);
      expect(q.skills, contains('letter:ba'));
    }
    // findForm and buildSyllable are marked letter:ba but are not review
    // types.
    expect(
      run.questions.map((q) => q.id),
      everyElement(isIn(['hear-ba', 'see-ba', 'pair-alif-ba'])),
    );
  });

  test('the pick depends only on the injected random', () {
    List<String> ids(int seed) => ok(reviewer(seed).start('letter:ba', [p]))
        .questions
        .map((q) => q.id)
        .toList();
    expect(ids(7), ids(7));
  });

  test('fewer marked questions than needed: not enough content, no grade', () {
    // rule:placeholder marks one review question; letter:alif one too.
    for (final skill in ['rule:placeholder', 'letter:alif']) {
      final r = reviewer().start(skill, [p]);
      final error = (r as Error).error as NotEnoughReviewQuestions;
      expect(error.skill, skill);
      expect(error.found, 1);
      expect(error.needed, LessonParams.defaults.skillReviewQuestions);
      expect(error.toString(), contains('Not enough lesson content'));
    }
  });

  test('no marked question: not enough content', () {
    final r = reviewer().start('letter:zay', [p]);
    expect(
      ((r as Error).error as NotEnoughReviewQuestions).found,
      0,
    );
  });

  test('a smaller review size from config is honoured', () {
    final two = SkillReviewer(
      params: const LessonParams(quizPassPercent: 80, skillReviewQuestions: 1),
      random: Random(1),
    );
    expect(ok(two.start('rule:placeholder', [p])).questions, hasLength(1));
  });

  for (final (mistakes, grade) in [
    (0, SkillGrade.good),
    (1, SkillGrade.hard),
    (2, SkillGrade.again),
  ]) {
    test('$mistakes mistakes: $grade', () {
      final reviewer0 = reviewer();
      var run = ok(reviewer0.start('letter:ba', [p]));
      var n = 0;
      for (var q = run.current; q != null; q = run.current) {
        expect(run.grade, isNull);
        run = ok(reviewer0.answer(run, n++ < mistakes ? wrong(q) : right(q)));
      }
      expect(run.grade, grade);
      expect(run.mistakes, mistakes);
    });
  }

  test('an answer after the end is refused', () {
    final reviewer0 = reviewer();
    var run = ok(reviewer0.start('letter:ba', [p]));
    for (var q = run.current; q != null; q = run.current) {
      run = ok(reviewer0.answer(run, right(q)));
    }
    final r = reviewer0.answer(run, const Acknowledged());
    expect((r as Error).error, isA<SkillReviewOver>());
  });
}
