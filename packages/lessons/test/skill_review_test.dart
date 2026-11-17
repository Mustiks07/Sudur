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
    List<String> ids(int seed) => ok(reviewer(seed).start('letter:alif', [p]))
        .questions
        .map((q) => q.id)
        .toList();
    expect(ids(7), ids(7));
  });

  test('fewer marked questions than 3: all of them', () {
    final run = ok(reviewer().start('rule:placeholder', [p]));
    expect(run.questions.map((q) => q.id), ['rule-78']);
  });

  test('no marked question: an error, not an empty review', () {
    final r = reviewer().start('letter:zay', [p]);
    expect((r as Error).error, isA<NoReviewQuestions>());
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
    var run = ok(reviewer0.start('rule:placeholder', [p]));
    run = ok(reviewer0.answer(run, right(run.current!))); // One question.
    expect(
      reviewer0.answer(run, const Acknowledged()),
      isA<Error<SkillReviewRun>>(),
    );
  });
}
