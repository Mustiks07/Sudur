import 'package:planner/planner.dart';
import 'package:test/test.dart';

void main() {
  test('УП-06: the exercise for each event, as in the table of 3.3', () {
    const table = {
      ExerciseTrigger.omissionOrSubstitution: ExerciseKind.hardPassage,
      ExerciseTrigger.missedAyahStart: ExerciseKind.transition,
      ExerciseTrigger.jumpToSimilar: ExerciseKind.similarAyahs,
      ExerciseTrigger.onlyFromSurahStart: ExerciseKind.startInMiddle,
      ExerciseTrigger.frequentHints: ExerciseKind.fadingHelp,
      ExerciseTrigger.unverified: ExerciseKind.rereadOrSelfCheck,
    };
    expect(table.keys, unorderedEquals(ExerciseTrigger.values));
    for (final MapEntry(:key, :value) in table.entries) {
      expect(chooseExercise(key), value, reason: key.name);
    }
  });

  test('every exercise ends with a check of the place (УП-07)', () {
    for (final kind in ExerciseKind.values) {
      final steps = exerciseSteps(kind, PlannerParams.defaults);
      expect(steps, isNotEmpty, reason: kind.name);
      expect(steps.last.span, isNot(ExerciseSpan.other), reason: kind.name);
    }
  });

  test('УП-01 goes from support to hidden and widens to the ayah', () {
    expect(exerciseSteps(ExerciseKind.hardPassage, PlannerParams.defaults), [
      (span: ExerciseSpan.place, mode: ExerciseReadMode.supported),
      (span: ExerciseSpan.place, mode: ExerciseReadMode.recall),
      (span: ExerciseSpan.ayah, mode: ExerciseReadMode.test),
    ]);
  });

  test('УП-02 reads the junction hidden as often as the parameter says', () {
    final steps = exerciseSteps(
      ExerciseKind.transition,
      PlannerParams.defaults,
    );
    expect(steps, hasLength(PlannerParams.defaults.junctionRepeats));
    expect(steps.toSet(), {
      (span: ExerciseSpan.junction, mode: ExerciseReadMode.test),
    });
  });

  test('УП-04 help fades: supported, recall, hidden', () {
    expect(
      exerciseSteps(
        ExerciseKind.fadingHelp,
        PlannerParams.defaults,
      ).map((s) => s.mode),
      [
        ExerciseReadMode.supported,
        ExerciseReadMode.recall,
        ExerciseReadMode.test,
      ],
    );
  });
}
