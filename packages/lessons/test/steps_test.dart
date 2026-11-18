import 'package:contracts/contracts.dart';
import 'package:lessons/lessons.dart';
import 'package:test/test.dart';

import 'helpers.dart';

StepResult score(LessonStep s, StepAnswer a, {bool check = false}) =>
    ok(scoreStep(s, a, pronunciationCheck: check));

void main() {
  late LessonPackage p;
  setUpAll(() => p = fixture());

  LessonStep s(String id) => p.lessons
      .expand((l) => l.steps)
      .firstWhere((x) => x.id == id); // Fixture ids.

  test('explain: viewed', () {
    expect(score(s('explain-ba'), const Acknowledged()), isA<Viewed>());
    expect(s('explain-ba').media, ['img/ba.png', 'aud/ba.ogg']);
  });

  test('listen: listened', () {
    expect(score(s('listen-ba'), const Acknowledged()), isA<Listened>());
  });

  test('repeatAndCompare: self-assessment; "не совсем" is a hard step', () {
    final got = score(s('repeat-ba'), const SelfAssessment(gotIt: true));
    final notQuite = score(s('repeat-ba'), const SelfAssessment(gotIt: false));
    expect((got as SelfAssessed).gotIt, isTrue);
    expect(got.correct, isNull);
    expect(got.hard, isFalse);
    expect(notQuite.hard, isTrue);
  });

  for (final id in [
    'hear-ba',
    'see-ba',
    'pair-alif-ba',
    'form-ba',
    'build-ba-fatha',
    'rule-78',
  ]) {
    test('$id: right and wrong', () {
      final step = s(id);
      expect(step.type.isQuestion, isTrue);
      expect(score(step, right(step)).correct, isTrue);
      expect(score(step, wrong(step)).correct, isFalse);
      expect(score(step, wrong(step)).hard, isTrue);
    });
  }

  test('a choice that is not an option is an error', () {
    final r = scoreStep(s('hear-ba'), const Choice('nothing'));
    expect((r as Error).error, isA<AnswerMismatch>());
  });

  test('an answer of another kind is an error, not a crash', () {
    final r = scoreStep(s('hear-ba'), const Acknowledged());
    expect((r as Error).error.toString(), contains('expects a Choice'));
  });

  test('buildSyllable: distractor pieces make it wrong; bad indexes error', () {
    final step = s('build-ba-fatha') as BuildSyllableStep; // Fixture type.
    expect(score(step, const PieceOrder([0, 1])).correct, isFalse);
    expect(score(step, const PieceOrder([0])).correct, isFalse);
    expect(scoreStep(step, const PieceOrder([0, 0])), isA<Error<StepResult>>());
    expect(scoreStep(step, const PieceOrder([9])), isA<Error<StepResult>>());
  });

  test('findRule: share found; right only with all and nothing extra', () {
    final step = s('rule-78');
    const rule = WordKey(78, 2, 2);
    const other = WordKey(78, 2, 1);
    final all = score(step, RuleWords({rule})) as RuleFound;
    expect(all.foundShare, 1);
    expect(all.correct, isTrue);
    final extra = score(step, RuleWords({rule, other})) as RuleFound;
    expect(extra.foundShare, 1);
    expect(extra.wrong, 1);
    expect(extra.correct, isFalse);
    final none = score(step, RuleWords({other})) as RuleFound;
    expect(none.foundShare, 0);
    expect(
      scoreStep(step, RuleWords({const WordKey(1, 1, 1)})),
      isA<Error<StepResult>>(),
    );
  });

  test('readSupported: the supported session took place', () {
    expect(
      score(s('read-78'), const SupportedReadingFinished()),
      isA<SupportedReadingDone>(),
    );
  });

  test('speakAndCheck without the check (И-5 not passed): self-assessment', () {
    final step = s('speak-ba');
    expect(
      score(step, const SelfAssessment(gotIt: true)),
      isA<SelfAssessed>(),
    );
    expect(
      scoreStep(step, const PronunciationChecked(PronunciationVerdict.correct)),
      isA<Error<StepResult>>(),
    );
  });

  test('speakAndCheck with the check: the verdict', () {
    final step = s('speak-ba');
    final r = score(
      step,
      const PronunciationChecked(PronunciationVerdict.unclear),
      check: true,
    );
    expect((r as PronunciationResult).verdict, PronunciationVerdict.unclear);
    expect(r.hard, isTrue);
    expect(
      scoreStep(
        step,
        const SelfAssessment(gotIt: true),
        pronunciationCheck: true,
      ),
      isA<Error<StepResult>>(),
    );
  });

  test('the quiz is not scored as a step', () {
    expect(
      scoreStep(s('quiz'), const Acknowledged()),
      isA<Error<StepResult>>(),
    );
  });

  test('quiz score: pass mark compared exactly', () {
    const four = QuizScored(right: 4, total: 5, passPercent: 80);
    const three = QuizScored(right: 3, total: 5, passPercent: 80);
    expect(four.percent, 80);
    expect(four.passed, isTrue);
    expect(three.passed, isFalse);
  });
}
