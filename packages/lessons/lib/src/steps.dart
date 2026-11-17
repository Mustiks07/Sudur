import 'package:contracts/contracts.dart';
import 'package:lessons/src/localized_text.dart';
import 'package:meta/meta.dart';

/// Step types of the lesson package (docs/tz 11.2), with their JSON names.
enum StepType {
  /// Read a short text with a picture, listen to a sound.
  explain('explain'),

  /// Listen to a sample while a letter or word is highlighted.
  listen('listen'),

  /// Listen, record oneself, compare, assess oneself.
  repeatAndCompare('repeatAndCompare'),

  /// Hear a sound, choose the letter or syllable.
  hearAndChoose('hearAndChoose'),

  /// See a letter or syllable, choose the sound.
  seeAndChoose('seeAndChoose'),

  /// Similar letters: which one sounds.
  pairDiscriminate('pairDiscriminate'),

  /// Choose the form of a letter for a position in a word.
  findForm('findForm'),

  /// Put letters and vowel marks together.
  buildSyllable('buildSyllable'),

  /// Read Quran words aloud while they follow the voice.
  readSupported('readSupported'),

  /// Tap the words of an ayah that have a tajweed rule (ТД-03).
  findRule('findRule'),

  /// The mini-quiz at the end of a lesson (УЧ-04).
  quiz('quiz'),

  /// «Произнеси, приложение проверит»: automatic check of a sound. Only an
  /// interface stub: it depends on trial И-5 (docs/tz 16.9, МС-03/МС-04).
  /// While the check is not available it works as [repeatAndCompare].
  speakAndCheck('speakAndCheck');

  const StepType(this.jsonName);

  /// Name in the package JSON (`type`).
  final String jsonName;

  /// Steps with a right answer: they can be quiz questions.
  bool get isQuestion => switch (this) {
        hearAndChoose ||
        seeAndChoose ||
        pairDiscriminate ||
        findForm ||
        buildSyllable ||
        findRule =>
          true,
        _ => false,
      };

  /// Steps a skill review asks (docs/tz 11.2, «Навыки»).
  bool get isSkillReviewQuestion => switch (this) {
        hearAndChoose || seeAndChoose || pairDiscriminate || findRule => true,
        _ => false,
      };

  /// Steps that record the reader's voice (УЧ-06).
  bool get records => this == repeatAndCompare || this == speakAndCheck;
}

/// Position of a letter in a word for [FindFormStep].
enum LetterPosition {
  /// At the start of a word.
  initial('initial'),

  /// In the middle of a word.
  medial('medial'),

  /// At the end of a word.
  finalPosition('final'),

  /// Standing alone.
  isolated('isolated');

  const LetterPosition(this.jsonName);

  /// Name in the package JSON.
  final String jsonName;
}

/// One step of a lesson (docs/tz 11.2, «Типы шагов и данные»).
///
/// Letters, syllables and options are lesson content written by people
/// (УЧ-09, МС-02); the engine never makes them up. Media fields are paths
/// inside the package.
@immutable
sealed class LessonStep {
  const LessonStep({required this.id, required this.skills});

  /// Step id, unique within the lesson.
  final String id;

  /// Skills this step trains or asks (`letter:ba`). A skill review asks only
  /// steps marked with the skill.
  final List<String> skills;

  /// Type of the step.
  StepType get type;

  /// Package files the step refers to.
  List<String> get media;
}

/// `explain`: a short text, maybe with a picture and a sound.
final class ExplainStep extends LessonStep {
  /// Creates the step.
  const ExplainStep({
    required super.id,
    required super.skills,
    required this.text,
    this.image,
    this.audio,
  });

  /// The explanation.
  final LocalizedText text;

  /// Picture file, if any.
  final String? image;

  /// Sound file, if any.
  final String? audio;

  @override
  StepType get type => StepType.explain;

  @override
  List<String> get media => [
        if (image case final i?) i,
        if (audio case final a?) a,
      ];
}

/// `listen`: a sample with something highlighted.
final class ListenStep extends LessonStep {
  /// Creates the step.
  const ListenStep({
    required super.id,
    required super.skills,
    required this.audio,
    required this.highlight,
  });

  /// Sample sound.
  final String audio;

  /// What is highlighted while the sample plays (a letter, syllable, word).
  final String highlight;

  @override
  StepType get type => StepType.listen;

  @override
  List<String> get media => [audio];
}

/// `repeatAndCompare`: sample, own recording, self-assessment.
final class RepeatAndCompareStep extends LessonStep {
  /// Creates the step.
  const RepeatAndCompareStep({
    required super.id,
    required super.skills,
    required this.audio,
  });

  /// Sample sound.
  final String audio;

  @override
  StepType get type => StepType.repeatAndCompare;

  @override
  List<String> get media => [audio];
}

/// `hearAndChoose`: hear a sound, choose one of [options].
final class HearAndChooseStep extends LessonStep {
  /// Creates the step.
  const HearAndChooseStep({
    required super.id,
    required super.skills,
    required this.audio,
    required this.options,
    required this.answer,
  });

  /// The sound.
  final String audio;

  /// Letters or syllables to choose from.
  final List<String> options;

  /// The right option.
  final String answer;

  @override
  StepType get type => StepType.hearAndChoose;

  @override
  List<String> get media => [audio];
}

/// `seeAndChoose`: see [prompt], choose one of [optionsAudio].
final class SeeAndChooseStep extends LessonStep {
  /// Creates the step.
  const SeeAndChooseStep({
    required super.id,
    required super.skills,
    required this.prompt,
    required this.optionsAudio,
    required this.answer,
  });

  /// The letter or syllable shown.
  final String prompt;

  /// Sounds to choose from.
  final List<String> optionsAudio;

  /// The right sound (one of [optionsAudio]).
  final String answer;

  @override
  StepType get type => StepType.seeAndChoose;

  @override
  List<String> get media => optionsAudio;
}

/// `pairDiscriminate`: which of two similar letters sounds.
final class PairDiscriminateStep extends LessonStep {
  /// Creates the step.
  const PairDiscriminateStep({
    required super.id,
    required super.skills,
    required this.audio,
    required this.pair,
    required this.answer,
  });

  /// The sound.
  final String audio;

  /// The two similar letters.
  final (String, String) pair;

  /// The one that sounds.
  final String answer;

  @override
  StepType get type => StepType.pairDiscriminate;

  @override
  List<String> get media => [audio];
}

/// `findForm`: the form of [letter] at [position].
final class FindFormStep extends LessonStep {
  /// Creates the step.
  const FindFormStep({
    required super.id,
    required super.skills,
    required this.letter,
    required this.position,
    required this.options,
    required this.answer,
  });

  /// The letter.
  final String letter;

  /// Its position in a word.
  final LetterPosition position;

  /// Forms to choose from.
  final List<String> options;

  /// The right form.
  final String answer;

  @override
  StepType get type => StepType.findForm;

  @override
  List<String> get media => const [];
}

/// `buildSyllable`: put [pieces] in order to get [target]. Pieces not in
/// [target] are distractors.
final class BuildSyllableStep extends LessonStep {
  /// Creates the step.
  const BuildSyllableStep({
    required super.id,
    required super.skills,
    required this.target,
    required this.pieces,
  });

  /// The syllable or word to build.
  final String target;

  /// Letters and vowel marks to choose from.
  final List<String> pieces;

  @override
  StepType get type => StepType.buildSyllable;

  @override
  List<String> get media => const [];
}

/// `readSupported`: a reading session in supported mode over Quran words
/// [from]–[to]. The words come from the canonical text, not the package.
final class ReadSupportedStep extends LessonStep {
  /// Creates the step.
  const ReadSupportedStep({
    required super.id,
    required super.skills,
    required this.from,
    required this.to,
    required this.offerMemorize,
  });

  /// First word.
  final WordKey from;

  /// Last word.
  final WordKey to;

  /// Offer to memorize the range after reading (УЧ-07, a short surah).
  final bool offerMemorize;

  @override
  StepType get type => StepType.readSupported;

  @override
  List<String> get media => const [];
}

/// `findRule`: tap the words of [from]–[to] that have [rule] (ТД-03).
///
/// Which words have the rule comes from licensed markup or a teacher's
/// markup act (ТД-04), never from the engine.
final class FindRuleStep extends LessonStep {
  /// Creates the step.
  const FindRuleStep({
    required super.id,
    required super.skills,
    required this.from,
    required this.to,
    required this.rule,
    required this.answerWords,
  });

  /// First word of the range.
  final WordKey from;

  /// Last word of the range.
  final WordKey to;

  /// The rule, as a skill id (`rule:ikhfa`).
  final String rule;

  /// Words where the rule is, in text order.
  final List<WordKey> answerWords;

  @override
  StepType get type => StepType.findRule;

  @override
  List<String> get media => const [];
}

/// `quiz`: the mini-quiz (УЧ-04) over question steps of the lesson.
final class QuizStep extends LessonStep {
  /// Creates the step.
  const QuizStep({
    required super.id,
    required super.skills,
    required this.stepIds,
    this.passPercent,
  });

  /// Question steps asked, in order.
  final List<String> stepIds;

  /// Pass mark of this quiz; `null` — `quizPassPercent` from config.
  final double? passPercent;

  @override
  StepType get type => StepType.quiz;

  @override
  List<String> get media => const [];
}

/// `speakAndCheck`: say [target], the app checks it. Interface stub until
/// trial И-5; without the check it is a [RepeatAndCompareStep].
final class SpeakAndCheckStep extends LessonStep {
  /// Creates the step.
  const SpeakAndCheckStep({
    required super.id,
    required super.skills,
    required this.audio,
    required this.target,
  });

  /// Sample sound.
  final String audio;

  /// The sound or syllable to say.
  final String target;

  @override
  StepType get type => StepType.speakAndCheck;

  @override
  List<String> get media => [audio];
}
