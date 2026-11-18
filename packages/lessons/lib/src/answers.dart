import 'package:contracts/contracts.dart';
import 'package:lessons/src/steps.dart';
import 'package:meta/meta.dart';

/// What the person did on a step.
@immutable
sealed class StepAnswer {
  const StepAnswer();
}

/// `explain` was read, `listen` was heard.
final class Acknowledged extends StepAnswer {
  /// Creates the answer.
  const Acknowledged();
}

/// Self-assessment of `repeatAndCompare` (and `speakAndCheck` without the
/// automatic check): «получилось / не совсем».
final class SelfAssessment extends StepAnswer {
  /// Creates the answer.
  const SelfAssessment({required this.gotIt, this.saveRecording = false});

  /// «Получилось».
  final bool gotIt;

  /// The person chose to keep the recording (УЧ-06). Otherwise it is no
  /// longer needed once the step ends.
  final bool saveRecording;
}

/// A chosen option: a letter, a form, a pair member, or a sound file of
/// `seeAndChoose`.
final class Choice extends StepAnswer {
  /// Creates the answer.
  const Choice(this.value);

  /// The chosen option, exactly as in the package.
  final String value;
}

/// `buildSyllable`: indexes of the pieces in the order they were put.
final class PieceOrder extends StepAnswer {
  /// Creates the answer.
  const PieceOrder(this.pieces);

  /// Indexes into `pieces`.
  final List<int> pieces;
}

/// `readSupported`: the supported reading session ended.
final class SupportedReadingFinished extends StepAnswer {
  /// Creates the answer.
  const SupportedReadingFinished();
}

/// `findRule`: the words the person tapped.
final class RuleWords extends StepAnswer {
  /// Creates the answer.
  const RuleWords(this.words);

  /// Tapped words.
  final Set<WordKey> words;
}

/// Verdict of the automatic pronunciation check (stub until trial И-5).
enum PronunciationVerdict {
  /// Said right.
  correct,

  /// Said wrong.
  incorrect,

  /// Could not tell.
  unclear,
}

/// `speakAndCheck` with the automatic check available.
final class PronunciationChecked extends StepAnswer {
  /// Creates the answer.
  const PronunciationChecked(this.verdict, {this.saveRecording = false});

  /// What the check said.
  final PronunciationVerdict verdict;

  /// The person chose to keep the recording (УЧ-06).
  final bool saveRecording;
}

/// Result of a step (docs/tz 11.2, column «Результат»).
@immutable
sealed class StepResult {
  const StepResult();

  /// For a question: whether it was answered right; `null` for steps
  /// without a right answer.
  bool? get correct => null;

  /// Whether the step goes to the list of hard steps to repeat.
  bool get hard => correct == false;
}

/// `explain`: «Просмотрено».
final class Viewed extends StepResult {
  /// Creates the result.
  const Viewed();
}

/// `listen`: «Прослушано».
final class Listened extends StepResult {
  /// Creates the result.
  const Listened();
}

/// `repeatAndCompare`: «получилось / не совсем».
final class SelfAssessed extends StepResult {
  /// Creates the result.
  const SelfAssessed({required this.gotIt});

  /// «Получилось».
  final bool gotIt;

  @override
  bool get hard => !gotIt;
}

/// Choice and build questions: «Верно / неверно».
final class Answered extends StepResult {
  /// Creates the result.
  const Answered({required bool correct}) : _correct = correct;

  final bool _correct;

  @override
  bool get correct => _correct;
}

/// `readSupported`: the session in supported mode took place.
final class SupportedReadingDone extends StepResult {
  /// Creates the result.
  const SupportedReadingDone();
}

/// `findRule`: «Доля найденных».
final class RuleFound extends StepResult {
  /// Creates the result.
  const RuleFound({
    required this.found,
    required this.total,
    required this.wrong,
  });

  /// Rule words tapped.
  final int found;

  /// Rule words in the range.
  final int total;

  /// Tapped words without the rule.
  final int wrong;

  /// Share of rule words found, 0..1.
  double get foundShare => found / total;

  /// As a question it is right only when every rule word and nothing else
  /// was tapped: otherwise tapping all words would pass.
  @override
  bool get correct => found == total && wrong == 0;
}

/// `speakAndCheck` checked automatically.
final class PronunciationResult extends StepResult {
  /// Creates the result.
  const PronunciationResult(this.verdict);

  /// What the check said.
  final PronunciationVerdict verdict;

  @override
  bool get hard => verdict != PronunciationVerdict.correct;
}

/// The mini-quiz: «Процент».
final class QuizScored extends StepResult {
  /// Creates the result.
  const QuizScored({
    required this.right,
    required this.total,
    required this.passPercent,
  });

  /// Questions answered right.
  final int right;

  /// Questions asked.
  final int total;

  /// The pass mark used.
  final double passPercent;

  /// Percent of right answers.
  double get percent => right * 100 / total;

  /// Whether the lesson is passed (УЧ-04). Compared without division, so
  /// 4 of 5 at 80 % passes exactly.
  bool get passed => right * 100 >= passPercent * total;
}

/// An answer that does not fit the step.
final class AnswerMismatch implements Exception {
  /// Creates the error.
  const AnswerMismatch(this.stepId, this.message);

  /// The step.
  final String stepId;

  /// What is wrong.
  final String message;

  @override
  String toString() => 'Step $stepId: $message';
}

/// Scores [answer] on [step]. [pronunciationCheck] tells whether the
/// automatic check of `speakAndCheck` is available (trial И-5).
///
/// A quiz is scored by the engine, not here.
Result<StepResult> scoreStep(
  LessonStep step,
  StepAnswer answer, {
  bool pronunciationCheck = false,
}) {
  Result<StepResult> mismatch(String expected) => Result.error(
        AnswerMismatch(
          step.id,
          '${step.type.jsonName} expects $expected, got ${answer.runtimeType}',
        ),
      );
  Result<StepResult> choose(List<String> options, String right) =>
      switch (answer) {
        Choice(:final value) when options.contains(value) =>
          Result.ok(Answered(correct: value == right)),
        Choice(:final value) => Result.error(
            AnswerMismatch(step.id, '"$value" is not one of the choices'),
          ),
        _ => mismatch('a Choice'),
      };

  return switch (step) {
    ExplainStep() => answer is Acknowledged
        ? const Result.ok(Viewed())
        : mismatch('Acknowledged'),
    ListenStep() => answer is Acknowledged
        ? const Result.ok(Listened())
        : mismatch('Acknowledged'),
    RepeatAndCompareStep() => switch (answer) {
        SelfAssessment(:final gotIt) => Result.ok(SelfAssessed(gotIt: gotIt)),
        _ => mismatch('a SelfAssessment'),
      },
    HearAndChooseStep(:final options, answer: final right) =>
      choose(options, right),
    SeeAndChooseStep(:final optionsAudio, answer: final right) =>
      choose(optionsAudio, right),
    PairDiscriminateStep(:final pair, answer: final right) =>
      choose([pair.$1, pair.$2], right),
    FindFormStep(:final options, answer: final right) => choose(options, right),
    BuildSyllableStep(:final target, :final pieces) => switch (answer) {
        PieceOrder(pieces: final order)
            when order.every((i) => i >= 0 && i < pieces.length) &&
                order.toSet().length == order.length =>
          Result.ok(
            Answered(correct: order.map((i) => pieces[i]).join() == target),
          ),
        PieceOrder() => Result.error(
            AnswerMismatch(step.id, 'piece indexes are out of range or repeat'),
          ),
        _ => mismatch('a PieceOrder'),
      },
    ReadSupportedStep() => answer is SupportedReadingFinished
        ? const Result.ok(SupportedReadingDone())
        : mismatch('SupportedReadingFinished'),
    FindRuleStep(:final from, :final to, :final answerWords) => switch (
          answer) {
        RuleWords(:final words)
            when words
                .every((w) => w.compareTo(from) >= 0 && w.compareTo(to) <= 0) =>
          Result.ok(
            RuleFound(
              found: answerWords.where(words.contains).length,
              total: answerWords.length,
              wrong: words.where((w) => !answerWords.contains(w)).length,
            ),
          ),
        RuleWords() => Result.error(
            AnswerMismatch(step.id, 'a tapped word is outside the range'),
          ),
        _ => mismatch('RuleWords'),
      },
    QuizStep() => Result.error(
        AnswerMismatch(step.id, 'the quiz is scored by the lesson engine'),
      ),
    SpeakAndCheckStep() => switch (answer) {
        PronunciationChecked(:final verdict) when pronunciationCheck =>
          Result.ok(PronunciationResult(verdict)),
        SelfAssessment(:final gotIt) when !pronunciationCheck =>
          Result.ok(SelfAssessed(gotIt: gotIt)),
        _ => mismatch(
            pronunciationCheck ? 'PronunciationChecked' : 'a SelfAssessment',
          ),
      },
  };
}

/// Whether [answer] asks to keep the recording of a recording step.
bool keepsRecording(StepAnswer answer) => switch (answer) {
      SelfAssessment(:final saveRecording) => saveRecording,
      PronunciationChecked(:final saveRecording) => saveRecording,
      _ => false,
    };
