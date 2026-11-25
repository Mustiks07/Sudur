import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/self_check/view_models/self_check_view_model.dart';
import 'package:sudur/ui/self_check/views/self_check_screen.dart';

import '../../test_helpers/fake_app_user_repository.dart';
import '../read/read_test_helpers.dart';

void main() {
  test('recall, reveal, rate: the answer is written (СП-01)', () async {
    final user = FakeAppUserRepository();
    final viewModel = SelfCheckViewModel(
      reading: FakeReadingRepository(voice: false),
      user: user,
    );
    await viewModel.open(from: w1, to: w3, stepId: 'step-1');
    expect(viewModel.step, SelfCheckStep.recall, reason: 'no model needed');

    await viewModel.rate(SelfCheckAnswer.remembered);
    expect(user.selfChecks, isEmpty, reason: 'the text must be opened first');

    viewModel.reveal();
    expect(viewModel.step, SelfCheckStep.rate);
    await viewModel.rate(SelfCheckAnswer.withDifficulty);

    expect(viewModel.step, SelfCheckStep.done);
    final result = user.selfChecks.single;
    expect(result.answer, SelfCheckAnswer.withDifficulty);
    expect(result.stepId, 'step-1');
    expect((result.from, result.to), (w1, w3));
  });

  testWidgets('the screen hides the text until «Готово»', (tester) async {
    final user = FakeAppUserRepository();
    final viewModel = SelfCheckViewModel(
      reading: FakeReadingRepository(),
      user: user,
    );
    await viewModel.open(from: w1, to: w3);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => ChangeNotifierProvider.value(
                  value: viewModel,
                  child: const SelfCheckScreen(),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Прочитайте про себя суру 2, аяты 255–255'), findsOne);
    expect(find.text('test-2'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('self-done')));
    await tester.pumpAndSettle();
    expect(find.text('test-2'), findsOneWidget);
    expect(find.text('Как получилось?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('self-forgotten')));
    await tester.pumpAndSettle();
    expect(user.selfChecks.single.answer, SelfCheckAnswer.forgotten);
    expect(find.byType(SelfCheckScreen), findsNothing);
  });

  test('a step marked self-check opens the self-check', () {
    const step = TodayStepData(
      id: 'p1',
      kind: TodayStepKind.passage,
      reason: TodayStepReason.recentDue,
      estimatedSeconds: 60,
      from: WordKey(78, 1, 1),
      to: WordKey(78, 5, 2),
      requiresVoice: true,
      selfCheck: true,
    );
    expect(locationOfStep(step), startsWith('/self?'));
    expect(locationOfStep(step.withDone(done: false)), startsWith('/self?'));
  });
}
