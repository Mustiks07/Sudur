import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/planner.dart';
import 'package:sudur/data/repositories/exercise_repository.dart';
import 'package:sudur/ui/exercise/view_models/exercise_view_model.dart';

import '../read/read_test_helpers.dart';

final class _FakeExercises implements ExerciseRepository {
  final finished = <bool>[];

  @override
  Future<Result<ExercisePlanData>> plan(CheckEvent check) async => Result.ok(
    ExercisePlanData(
      kind: ExerciseKind.hardPassage,
      place: check.words.first,
      steps: const [
        ExerciseStepData(
          from: w1,
          to: w2,
          mode: ExerciseReadMode.supported,
          span: ExerciseSpan.place,
        ),
        ExerciseStepData(
          from: w1,
          to: w3,
          mode: ExerciseReadMode.test,
          span: ExerciseSpan.ayah,
        ),
      ],
    ),
  );

  @override
  Future<Result<void>> finish({
    required ExercisePlanData plan,
    required bool closed,
    String? parentUnitId,
  }) async {
    finished.add(closed);
    return const Result.ok(null);
  }
}

void main() {
  test('steps go in order; a clean last step closes the place', () async {
    final repository = _FakeExercises();
    final viewModel = ExerciseViewModel(repository);
    await viewModel.open(check('c', w2), parentUnitId: 'u');
    expect(viewModel.state, ExerciseState.step);
    expect(viewModel.current?.mode, ExerciseReadMode.supported);

    await viewModel.stepFinished(clean: false);
    expect(viewModel.index, 1, reason: 'only the last step decides');
    await viewModel.stepFinished(clean: true);

    expect(viewModel.state, ExerciseState.closed);
    expect(repository.finished, [true]);
  });

  test('a last step with a mistake: back to it tomorrow', () async {
    final repository = _FakeExercises();
    final viewModel = ExerciseViewModel(repository);
    await viewModel.open(check('c', w2));
    await viewModel.stepFinished(clean: true);
    await viewModel.stepFinished(clean: false);

    expect(viewModel.state, ExerciseState.again);
    expect(repository.finished, [false]);
  });
}
