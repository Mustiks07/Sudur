import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/learn/view_models/learn_view_model.dart';

import '../../test_helpers/fake_app_user_repository.dart';
import '../read/read_test_helpers.dart';

LearnPlan _plan({int start = 0}) => LearnPlan(
  unitId: 'u1',
  from: w1,
  to: w3,
  startIndex: start,
  steps: const [
    LearnStep(kind: LearnStepKind.listen, from: w1, to: w3),
    LearnStep(kind: LearnStepKind.listen, from: w1, to: w3),
    LearnStep(kind: LearnStepKind.supported, from: w1, to: w3),
    LearnStep(kind: LearnStepKind.recall, from: w1, to: w3),
    LearnStep(kind: LearnStepKind.test, from: w1, to: w3),
  ],
);

void main() {
  test('ЗН-01: listen can be skipped; recall repeats until clean; a failed '
      'check goes back to recall; then the passage is learned', () async {
    final user = FakeAppUserRepository()..learn = _plan();
    final viewModel = LearnViewModel(user);
    await viewModel.open('step-1');
    expect(viewModel.current?.kind, LearnStepKind.listen);

    await viewModel.skipListening();
    expect(viewModel.current?.kind, LearnStepKind.supported);
    await viewModel.stepFinished(clean: false);
    expect(
      viewModel.current?.kind,
      LearnStepKind.recall,
      reason: 'reading with the text always moves on',
    );

    await viewModel.stepFinished(clean: false);
    expect(viewModel.current?.kind, LearnStepKind.recall);
    await viewModel.stepFinished(clean: true);
    expect(viewModel.current?.kind, LearnStepKind.test);

    await viewModel.stepFinished(clean: false);
    expect(viewModel.current?.kind, LearnStepKind.recall);
    await viewModel.stepFinished(clean: true);
    await viewModel.stepFinished(clean: true);

    expect(viewModel.state, LearnState.learned);
    expect(user.learnProgress['u1'], 0, reason: 'nothing left to continue');
  });

  test('ЗН-04: an unfinished learning continues where it stopped', () async {
    final user = FakeAppUserRepository()..learn = _plan(start: 3);
    final viewModel = LearnViewModel(user);
    await viewModel.open('step-1');
    expect(viewModel.current?.kind, LearnStepKind.recall);

    await viewModel.stepFinished(clean: true);
    expect(user.learnProgress['u1'], 4);
  });

  test('a new passage of Today opens learning', () {
    const step = TodayStepData(
      id: 'n1',
      kind: TodayStepKind.passage,
      reason: TodayStepReason.newMaterial,
      estimatedSeconds: 60,
      unitId: 'u1',
      from: WordKey(114, 1, 1),
      to: WordKey(114, 3, 2),
      requiresVoice: true,
    );
    expect(locationOfStep(step), '/learn?step=n1');
  });
}
