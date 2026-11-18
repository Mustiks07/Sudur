import 'package:contracts/contracts.dart';
import 'package:lessons/lessons.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late LessonPackage p;
  late Lesson letters; // 9 steps + quiz of 5 questions, pass mark from config.
  late Lesson rules; // readSupported, findRule; quiz of 2 at 100 %.
  final e = engine();

  setUpAll(() {
    p = fixture();
    letters = p.lessons[0];
    rules = p.lessons[1];
  });

  test('a locked lesson cannot be started', () {
    expect(e.start(letters, LessonState.locked), isA<Error<LessonRun>>());
  });

  test('all right: steps, quiz, passed; skills learned (УЧ-05)', () {
    var run = ok(e.start(letters, LessonState.available));
    expect(run.state, LessonState.inProgress);
    expect(run.current?.id, 'explain-ba');

    final steps = answerAll(e, run, right);
    run = steps.run;
    expect(run.state, LessonState.quiz);
    expect(run.queue.map((s) => s.id), letters.quiz!.stepIds); // Fixture.
    final completed = steps.events.whereType<LessonStepCompleted>();
    expect(completed.map((c) => c.stepId), [
      for (final s in letters.learningSteps) s.id,
    ]);
    expect(completed.every((c) => !c.inQuiz && c.at == fixedNow), isTrue);

    final quiz = answerAll(e, run, right);
    run = quiz.run;
    expect(run.state, LessonState.passed);
    expect(run.current, isNull);
    final finished = quiz.events.whereType<QuizFinished>().single;
    expect(finished.score.percent, 100);
    expect(finished.score.passPercent, LessonParams.defaults.quizPassPercent);
    final quizStep = quiz.events
        .whereType<LessonStepCompleted>()
        .singleWhere((c) => c.stepId == 'quiz');
    expect((quizStep.result as QuizScored).passed, isTrue);
    expect(quiz.events.whereType<LessonPassed>().single.quizPercent, 100);
    final learned = quiz.events.whereType<SkillsLearned>().single;
    expect(learned.skills, ['letter:alif', 'letter:ba']);
    expect(learned.at, fixedNow);
  });

  group('quiz pass mark (УЧ-04, quizPassPercent)', () {
    ({LessonRun run, List<LessonEvent> events}) quizWith(int wrongAnswers) {
      final atQuiz = answerAll(
        e,
        ok(e.start(letters, LessonState.available)),
        right,
      ).run;
      var n = 0;
      return answerAll(
        e,
        atQuiz,
        (s) => n++ < wrongAnswers ? wrong(s) : right(s),
      );
    }

    test('4 of 5 = 80 %: passed', () {
      final r = quizWith(1);
      expect(r.run.state, LessonState.passed);
      expect(r.events.whereType<QuizFinished>().single.score.percent, 80);
    });

    test('3 of 5 = 60 %: failed, hard steps listed, no skills', () {
      final r = quizWith(2);
      expect(r.run.state, LessonState.failed);
      final finished = r.events.whereType<QuizFinished>().single;
      expect(finished.score.percent, 60);
      expect(finished.hardStepIds, ['hear-ba', 'see-ba']);
      expect(r.run.hardStepIds, ['hear-ba', 'see-ba']);
      expect(r.events.whereType<SkillsLearned>(), isEmpty);
      expect(r.events.whereType<LessonPassed>(), isEmpty);
    });

    test('a lower pass mark from config lets 60 % pass', () {
      final lenient = LessonEngine(
        params:
            const LessonParams(quizPassPercent: 60, skillReviewQuestions: 3),
        clock: () => fixedNow,
      );
      final atQuiz = answerAll(
        lenient,
        ok(lenient.start(letters, LessonState.available)),
        right,
      ).run;
      var n = 0;
      final r =
          answerAll(lenient, atQuiz, (s) => n++ < 2 ? wrong(s) : right(s));
      expect(r.run.state, LessonState.passed);
    });

    test("the package's own pass mark wins over config", () {
      // Lesson 2 asks 2 questions at 100 %: one mistake fails.
      final atQuiz = answerAll(
        e,
        ok(e.start(rules, LessonState.available)),
        right,
      ).run;
      var n = 0;
      final r = answerAll(e, atQuiz, (s) => n++ < 1 ? wrong(s) : right(s));
      expect(r.run.state, LessonState.failed);
      expect(
        r.events.whereType<QuizFinished>().single.score.passPercent,
        100,
      );
    });
  });

  test('failure → repeat hard steps → quiz again → passed', () {
    // Wrong in the steps on hear-ba, then wrong in the quiz on see-ba and
    // pair-alif-ba: 3 of 5 — failed.
    var run = answerAll(
      e,
      ok(e.start(letters, LessonState.available)),
      (s) => s.id == 'hear-ba' ? wrong(s) : right(s),
    ).run;
    final failed = answerAll(
      e,
      run,
      (s) => s.id == 'see-ba' || s.id == 'pair-alif-ba' ? wrong(s) : right(s),
    );
    run = failed.run;
    expect(run.state, LessonState.failed);
    expect(run.hardStepIds, ['hear-ba', 'see-ba', 'pair-alif-ba']);
    expect(e.answer(run, const Acknowledged()), isA<Error<LessonTransition>>());

    run = ok(e.retry(run));
    expect(run.state, LessonState.inProgress);
    expect(run.queue.map((s) => s.id), ['hear-ba', 'see-ba', 'pair-alif-ba']);

    run = answerAll(e, run, right).run;
    expect(run.state, LessonState.quiz);
    final passed = answerAll(e, run, right);
    expect(passed.run.state, LessonState.passed);
    expect(passed.events.whereType<SkillsLearned>(), hasLength(1));
  });

  test('retry is only for a failed lesson', () {
    final run = ok(e.start(letters, LessonState.available));
    expect(e.retry(run), isA<Error<LessonRun>>());
  });

  test('a self-assessed "не совсем" goes to the repeat', () {
    var run = answerAll(
      e,
      ok(e.start(letters, LessonState.available)),
      (s) =>
          s.id == 'repeat-ba' ? const SelfAssessment(gotIt: false) : right(s),
    ).run;
    run = answerAll(e, run, wrong).run;
    expect(run.state, LessonState.failed);
    expect(run.hardStepIds.first, 'repeat-ba');
    expect(ok(e.retry(run)).queue.first.id, 'repeat-ba');
  });

  group('recording of "Повтори и сравни" (УЧ-06)', () {
    LessonRun atStep(String id) {
      var run = ok(e.start(letters, LessonState.available));
      while (run.current?.id != id) {
        run = ok(e.answer(run, right(run.current!))).run; // Loop condition.
      }
      return run;
    }

    test('not saved: no longer needed when the step ends', () {
      final t = ok(
        e.answer(atStep('repeat-ba'), const SelfAssessment(gotIt: true)),
      );
      expect(
        t.events.whereType<RecordingNoLongerNeeded>().single.stepId,
        'repeat-ba',
      );
    });

    test('saved by the person: kept', () {
      final t = ok(
        e.answer(
          atStep('repeat-ba'),
          const SelfAssessment(gotIt: true, saveRecording: true),
        ),
      );
      expect(t.events.whereType<RecordingNoLongerNeeded>(), isEmpty);
    });

    test('leaving the lesson on the step: no longer needed', () {
      final events = e.leave(atStep('repeat-ba'));
      expect(events.whereType<RecordingNoLongerNeeded>(), hasLength(1));
      expect(e.leave(atStep('listen-ba')), isEmpty);
    });

    test('speakAndCheck records too', () {
      final t = ok(
        e.answer(atStep('speak-ba'), const SelfAssessment(gotIt: true)),
      );
      expect(t.events.whereType<RecordingNoLongerNeeded>(), hasLength(1));
    });
  });

  test('speakAndCheck with the automatic check takes its verdict', () {
    final checked = engine(pronunciationCheck: true);
    var run = ok(checked.start(letters, LessonState.available));
    while (run.current?.id != 'speak-ba') {
      run = ok(checked.answer(run, right(run.current!))).run; // Loop condition.
    }
    final t = ok(
      checked.answer(
        run,
        const PronunciationChecked(PronunciationVerdict.incorrect),
      ),
    );
    final done = t.events.whereType<LessonStepCompleted>().single;
    expect(done.result, isA<PronunciationResult>());
    expect(t.run.hardStepIds, contains('speak-ba'));
  });

  test('supported reading of a short surah offers memorizing (УЧ-07)', () {
    final r = answerAll(e, ok(e.start(rules, LessonState.available)), right);
    final offer = r.events.whereType<MemorizeSuggested>().single;
    expect(offer.from, const WordKey(78, 1, 1));
    expect(offer.to, const WordKey(78, 3, 4));
  });

  test('a lesson without a quiz is passed after its steps', () {
    final lesson = Lesson(
      id: 'no-quiz',
      title: letters.title,
      skills: const ['letter:ba'],
      steps: [letters.steps.first],
    );
    final r = answerAll(e, ok(e.start(lesson, LessonState.available)), right);
    expect(r.run.state, LessonState.passed);
    expect(r.events.whereType<LessonPassed>().single.quizPercent, isNull);
    expect(r.events.whereType<SkillsLearned>(), hasLength(1));
  });

  test('replaying a passed lesson does not learn skills again', () {
    var run = ok(e.start(letters, LessonState.passed));
    expect(e.progress(run, contentVersion: p.version), isNull);
    run = answerAll(e, run, right).run;
    final r = answerAll(e, run, right);
    expect(r.run.state, LessonState.passed);
    expect(r.events.whereType<LessonPassed>(), hasLength(1));
    expect(r.events.whereType<SkillsLearned>(), isEmpty);
  });

  group('progress and resume', () {
    test('progress points at the current step', () {
      var run = ok(e.start(letters, LessonState.available));
      for (var i = 0; i < 3; i++) {
        run = ok(e.answer(run, right(run.current!))).run; // Not finished.
      }
      final saved = e.progress(run, contentVersion: p.version);
      expect(
        saved,
        LessonProgress(
          lessonId: letters.id,
          state: LessonState.inProgress,
          stepIndex: 3,
          quizPercent: null,
          contentVersion: p.version,
        ),
      );
      // Non-null: a first run, not a replay.
      final resumed = ok(e.resume(letters, saved!, contentVersion: p.version));
      expect(resumed.current?.id, letters.steps[3].id);
    });

    test('a new package version starts an unfinished lesson over', () {
      final saved = LessonProgress(
        lessonId: letters.id,
        state: LessonState.inProgress,
        stepIndex: 5,
        quizPercent: null,
        contentVersion: 'old',
      );
      final run = ok(e.resume(letters, saved, contentVersion: p.version));
      expect(run.current?.id, letters.steps.first.id);
    });

    test('quiz resumes at the first question', () {
      final atQuiz = answerAll(
        e,
        ok(e.start(letters, LessonState.available)),
        right,
      ).run;
      final saved =
          e.progress(atQuiz, contentVersion: p.version)!; // Not a replay.
      expect(saved.state, LessonState.quiz);
      final run = ok(e.resume(letters, saved, contentVersion: p.version));
      expect(run.state, LessonState.quiz);
      expect(run.current?.id, letters.quiz!.stepIds.first); // Fixture.
    });

    test('failed resumes as failed; its repeat takes all steps', () {
      final failed = answerAll(
        e,
        answerAll(e, ok(e.start(letters, LessonState.available)), right).run,
        wrong,
      ).run;
      final saved =
          e.progress(failed, contentVersion: p.version)!; // Not a replay.
      expect(saved.state, LessonState.failed);
      expect(saved.quizPercent, 0);
      final run = ok(e.resume(letters, saved, contentVersion: p.version));
      expect(run.state, LessonState.failed);
      expect(ok(e.retry(run)).queue, letters.learningSteps);
    });

    test('passed progress keeps quiz percent and is not resumed into steps',
        () {
      final passed = answerAll(
        e,
        answerAll(e, ok(e.start(letters, LessonState.available)), right).run,
        right,
      ).run;
      final saved =
          e.progress(passed, contentVersion: p.version)!; // Not a replay.
      expect(saved.state, LessonState.passed);
      expect(saved.quizPercent, 100);
      expect(saved.stepIndex, letters.steps.length);
      final run = ok(e.resume(letters, saved, contentVersion: p.version));
      expect(run.state, LessonState.passed);
      expect(run.current, isNull);
    });

    test('progress of another lesson or of nothing is refused', () {
      final saved = LessonProgress(
        lessonId: rules.id,
        state: LessonState.inProgress,
        stepIndex: 0,
        quizPercent: null,
        contentVersion: p.version,
      );
      expect(
        e.resume(letters, saved, contentVersion: p.version),
        isA<Error<LessonRun>>(),
      );
      final available = LessonProgress(
        lessonId: letters.id,
        state: LessonState.available,
        stepIndex: 0,
        quizPercent: null,
        contentVersion: p.version,
      );
      expect(
        e.resume(letters, available, contentVersion: p.version),
        isA<Error<LessonRun>>(),
      );
    });
  });
}
