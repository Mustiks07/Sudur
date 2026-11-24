import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/ui/today/view_models/today_view_model.dart';

import '../../../test_helpers/fake_app_user_repository.dart';

TodayStepData _step(String id) => TodayStepData(
  id: id,
  kind: TodayStepKind.passage,
  reason: TodayStepReason.newMaterial,
  estimatedSeconds: 60,
  surah: 78,
  from: const WordKey(78, 1, 1),
  to: const WordKey(78, 5, 2),
  requiresVoice: true,
);

void main() {
  test('start and skip update the visible stable plan', () async {
    final repository = FakeAppUserRepository();
    final viewModel = TodayViewModel(repository, const E01Config());

    await viewModel.initialize();
    await viewModel.start();
    expect(viewModel.data?.inProgress, isTrue);

    await viewModel.skip('step-1');
    expect(viewModel.data?.steps, isEmpty);
    expect(viewModel.data?.condition.name, 'completed');
    viewModel.dispose();
  });

  test('start opens the first step; a finished step is marked done', () async {
    final repository = FakeAppUserRepository()
      ..today = TodayDashboardData(
        date: '2026-11-24',
        approximateMinutes: 2,
        steps: [_step('a'), _step('b')],
        extraReview: const [],
        condition: TodayCondition.normal,
      );
    final viewModel = TodayViewModel(repository, const E01Config());
    await viewModel.initialize();

    final first = await viewModel.start();
    expect(first?.id, 'a');
    expect(first?.from, const WordKey(78, 1, 1));
    expect(viewModel.data?.currentStepId, 'a');

    // Closed without finishing: “Continue” opens the same step.
    await viewModel.returnedFrom('a', finished: false);
    expect((await viewModel.start())?.id, 'a');

    await viewModel.returnedFrom('a', finished: true);
    expect(repository.finished, ['a']);
    expect((await viewModel.start())?.id, 'b');

    await viewModel.returnedFrom('b', finished: true);
    expect(viewModel.data?.condition, TodayCondition.completed);
    expect(viewModel.data?.nextStep, isNull);
    expect(viewModel.data?.doneCount, 2);
    expect(await viewModel.start(), isNull);
    viewModel.dispose();
  });
}
