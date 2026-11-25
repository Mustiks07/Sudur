import 'package:planner/src/params.dart';

// Exercise vocabulary is the product vocabulary of docs/tz 3.3.
// ignore_for_file: public_member_api_docs

/// What happened at a place (docs/tz 3.3, table under УП-06).
enum ExerciseTrigger {
  /// A word was skipped or another word was read.
  omissionOrSubstitution,

  /// The start of the next ayah was not remembered.
  missedAyahStart,

  /// The reader moved to a similar ayah.
  jumpToSimilar,

  /// The surah works only from its start.
  onlyFromSurahStart,

  /// A hint is often needed.
  frequentHints,

  /// The place could not be checked.
  unverified,
}

/// Exercise types (УП-01…05) and the answer for “could not check”.
enum ExerciseKind {
  /// УП-01: the place and words around it.
  hardPassage,

  /// УП-02: end of an ayah and start of the next one.
  transition,

  /// УП-03: start from an ayah in the middle of the surah.
  startInMiddle,

  /// УП-04: help fades from supported to hidden.
  fadingHelp,

  /// УП-05: both similar places.
  similarAyahs,

  /// Read again without penalty, or check oneself.
  rereadOrSelfCheck,
}

/// УП-06: which exercise answers what happened.
ExerciseKind chooseExercise(ExerciseTrigger trigger) => switch (trigger) {
      ExerciseTrigger.omissionOrSubstitution => ExerciseKind.hardPassage,
      ExerciseTrigger.missedAyahStart => ExerciseKind.transition,
      ExerciseTrigger.jumpToSimilar => ExerciseKind.similarAyahs,
      ExerciseTrigger.onlyFromSurahStart => ExerciseKind.startInMiddle,
      ExerciseTrigger.frequentHints => ExerciseKind.fadingHelp,
      ExerciseTrigger.unverified => ExerciseKind.rereadOrSelfCheck,
    };

/// How a step of an exercise is read (the reading modes of 13.3).
enum ExerciseReadMode { supported, recall, test }

/// Which part of the place a step reads.
enum ExerciseSpan {
  /// The place with the words around it (УП-01).
  place,

  /// The whole ayah (or ayahs) of the place (УП-01 «расширить до аята»).
  ayah,

  /// The end of one ayah and the start of the next (УП-02).
  junction,

  /// The similar place (УП-05).
  other,
}

/// One step of an exercise: which part of the place, and how it is read.
typedef ExerciseStepPlan = ({ExerciseSpan span, ExerciseReadMode mode});

/// Steps of [kind]. Listening to the reciter (УП-01, УП-05) is left out
/// until reciter audio is licensed. The last step is always the check: the
/// exercise is closed when it is read cleanly (УП-07).
List<ExerciseStepPlan> exerciseSteps(
  ExerciseKind kind,
  PlannerParams params,
) {
  ExerciseStepPlan step(ExerciseSpan span, ExerciseReadMode mode) =>
      (span: span, mode: mode);
  const place = ExerciseSpan.place;
  const ayah = ExerciseSpan.ayah;
  const supported = ExerciseReadMode.supported;
  const recall = ExerciseReadMode.recall;
  const hidden = ExerciseReadMode.test;
  final steps = switch (kind) {
    ExerciseKind.hardPassage => [
        step(place, supported),
        step(place, recall),
        step(ayah, hidden),
      ],
    ExerciseKind.transition => [
        for (var i = 0; i < params.junctionRepeats; i++)
          step(ExerciseSpan.junction, hidden),
      ],
    ExerciseKind.startInMiddle => [step(ayah, recall), step(ayah, hidden)],
    ExerciseKind.fadingHelp => [
        step(ayah, supported),
        step(ayah, recall),
        step(ayah, hidden),
      ],
    ExerciseKind.similarAyahs => [
        step(ayah, supported),
        step(ExerciseSpan.other, supported),
        step(ayah, recall),
        step(ayah, hidden),
      ],
    ExerciseKind.rereadOrSelfCheck => [step(ayah, recall)],
  };
  return List.unmodifiable(steps);
}
