import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:lessons/lessons.dart';

/// The placeholder lesson package of `packages/testing` (no real content).
const String fixturePath = '../testing/fixtures/lessons_test_stage1.json';

String fixtureSource() => File(fixturePath).readAsStringSync();

Map<String, Object?> fixtureJson() =>
    jsonDecode(fixtureSource()) as Map<String, Object?>;

LessonPackage fixture() => switch (parseLessonPackage(fixtureSource())) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };

/// The right answer to [step].
StepAnswer right(LessonStep step) => switch (step) {
      ExplainStep() || ListenStep() => const Acknowledged(),
      RepeatAndCompareStep() ||
      SpeakAndCheckStep() =>
        const SelfAssessment(gotIt: true),
      HearAndChooseStep(:final answer) => Choice(answer),
      SeeAndChooseStep(:final answer) => Choice(answer),
      PairDiscriminateStep(:final answer) => Choice(answer),
      FindFormStep(:final answer) => Choice(answer),
      BuildSyllableStep(:final target, :final pieces) =>
        PieceOrder(buildOrder(target, pieces)),
      ReadSupportedStep() => const SupportedReadingFinished(),
      FindRuleStep(:final answerWords) => RuleWords(answerWords.toSet()),
      QuizStep() => throw ArgumentError('the quiz has no answer'),
    };

/// A wrong answer to a question [step].
StepAnswer wrong(LessonStep step) => switch (step) {
      HearAndChooseStep(:final options, :final answer) =>
        Choice(options.firstWhere((o) => o != answer)),
      SeeAndChooseStep(:final optionsAudio, :final answer) =>
        Choice(optionsAudio.firstWhere((o) => o != answer)),
      PairDiscriminateStep(:final pair, :final answer) =>
        Choice(pair.$1 == answer ? pair.$2 : pair.$1),
      FindFormStep(:final options, :final answer) =>
        Choice(options.firstWhere((o) => o != answer)),
      BuildSyllableStep(:final target, :final pieces) =>
        PieceOrder(buildOrder(target, pieces).reversed.toList()),
      FindRuleStep() => const RuleWords({}),
      _ => throw ArgumentError('${step.id} has no wrong answer'),
    };

/// Indexes of [pieces] that build [target] (greedy is enough for fixtures).
List<int> buildOrder(String target, List<String> pieces) {
  final order = <int>[];
  var at = 0;
  while (at < target.length) {
    final i = pieces.indexWhere((p) => target.startsWith(p, at));
    order.add(i);
    at += pieces[i].length;
  }
  return order;
}

final DateTime fixedNow = DateTime.utc(2026, 11, 17, 12);

LessonEngine engine({bool pronunciationCheck = false}) => LessonEngine(
      params: LessonParams.defaults,
      clock: () => fixedNow,
      pronunciationCheck: pronunciationCheck,
    );

T ok<T>(Result<T> r) => switch (r) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };

/// Answers the current steps with [answer] until the run leaves its state.
({LessonRun run, List<LessonEvent> events}) answerAll(
  LessonEngine e,
  LessonRun run,
  StepAnswer Function(LessonStep step) answer,
) {
  final events = <LessonEvent>[];
  var r = run;
  final state = r.state;
  while (r.state == state && r.current != null) {
    // Non-null: checked by the loop condition.
    final t = ok(e.answer(r, answer(r.current!)));
    events.addAll(t.events);
    r = t.run;
  }
  return (run: r, events: events);
}
