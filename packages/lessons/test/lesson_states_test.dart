import 'package:lessons/lessons.dart';
import 'package:test/test.dart';

import 'helpers.dart';

LessonProgress progress(String id, LessonState state) => LessonProgress(
      lessonId: id,
      state: state,
      stepIndex: 0,
      quizPercent: null,
      contentVersion: '1',
    );

void main() {
  test('review: stored locked lesson unlocks after predecessor passed', () {
    final p = fixture();
    final states = lessonStates(
      p,
      {
        'test-stage1-01': progress('test-stage1-01', LessonState.passed),
        'test-stage1-02': progress('test-stage1-02', LessonState.locked),
      },
      stageOpen: true,
    );
    expect(states['test-stage1-02'], LessonState.available);
  });

  late LessonPackage p;
  setUpAll(() => p = fixture());

  test('open stage, nothing done: first available, next locked', () {
    expect(lessonStates(p, {}, stageOpen: true).values, [
      LessonState.available,
      LessonState.locked,
    ]);
  });

  test('closed stage: everything locked', () {
    expect(
      lessonStates(p, {}, stageOpen: false).values,
      everyElement(LessonState.locked),
    );
  });

  test('previous lesson passed: the next one opens', () {
    final states = lessonStates(
      p,
      {'test-stage1-01': progress('test-stage1-01', LessonState.passed)},
      stageOpen: true,
    );
    expect(states.values, [LessonState.passed, LessonState.available]);
  });

  test('previous lesson failed or in progress: the next stays locked', () {
    for (final s in [LessonState.failed, LessonState.inProgress]) {
      final states = lessonStates(
        p,
        {'test-stage1-01': progress('test-stage1-01', s)},
        stageOpen: true,
      );
      expect(states.values, [s, LessonState.locked]);
    }
  });

  test('entry exercise set the start further: lessons up to it open', () {
    final states = lessonStates(
      p,
      {},
      stageOpen: false,
      placementStart: 'test-stage1-02',
    );
    expect(states.values, everyElement(LessonState.available));
  });

  test('stored locked lesson opens by the entry exercise too', () {
    final states = lessonStates(
      p,
      {
        'test-stage1-01': progress('test-stage1-01', LessonState.locked),
        'test-stage1-02': progress('test-stage1-02', LessonState.locked),
      },
      stageOpen: false,
      placementStart: 'test-stage1-02',
    );
    expect(states.values, everyElement(LessonState.available));
  });

  test('stored locked stays locked while nothing opens it', () {
    final states = lessonStates(
      p,
      {
        'test-stage1-01': progress('test-stage1-01', LessonState.failed),
        'test-stage1-02': progress('test-stage1-02', LessonState.locked),
      },
      stageOpen: true,
    );
    expect(states.values, [LessonState.failed, LessonState.locked]);
  });

  test('learning progress is never overwritten by unlock rules', () {
    final states = lessonStates(
      p,
      {
        'test-stage1-01': progress('test-stage1-01', LessonState.quiz),
        'test-stage1-02': progress('test-stage1-02', LessonState.inProgress),
      },
      stageOpen: false,
    );
    expect(states.values, [LessonState.quiz, LessonState.inProgress]);
  });

  test('a lesson once stored as available stays open', () {
    final states = lessonStates(
      p,
      {'test-stage1-02': progress('test-stage1-02', LessonState.available)},
      stageOpen: true,
    );
    expect(states['test-stage1-02'], LessonState.available);
  });

  test('placement in another stage is ignored here', () {
    final states = lessonStates(
      p,
      {},
      stageOpen: true,
      placementStart: 'stage5-01',
    );
    expect(states.values, [LessonState.available, LessonState.locked]);
  });
}
