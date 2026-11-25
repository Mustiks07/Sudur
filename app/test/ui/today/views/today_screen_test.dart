import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/today/view_models/today_view_model.dart';
import 'package:sudur/ui/today/views/today_screen.dart';

import '../../../test_helpers/fake_app_user_repository.dart';

void main() {
  _flowTests();
  for (final condition in TodayCondition.values) {
    testWidgets('renders ${condition.name} state', (tester) async {
      final repository = FakeAppUserRepository()
        ..today = TodayDashboardData(
          date: '2026-11-19',
          approximateMinutes: 10,
          steps: condition == TodayCondition.completed
              ? const []
              : const [
                  TodayStepData(
                    id: 'step-1',
                    kind: TodayStepKind.passage,
                    reason: TodayStepReason.longUnchecked,
                    estimatedSeconds: 600,
                    requiresVoice: true,
                    selfCheck: true,
                  ),
                ],
          extraReview: condition == TodayCondition.completed
              ? const [
                  TodayStepData(
                    id: 'extra-1',
                    kind: TodayStepKind.passage,
                    reason: TodayStepReason.recentDue,
                    estimatedSeconds: 60,
                  ),
                ]
              : const [],
          condition: condition,
        );
      final viewModel = TodayViewModel(repository, const E01Config());
      await viewModel.initialize();

      await tester.pumpWidget(_app(viewModel));

      expect(find.byKey(ValueKey('today-${condition.name}')), findsOneWidget);
      if (condition == TodayCondition.completed) {
        expect(find.text('Ещё повторить'), findsOneWidget);
      } else {
        expect(find.byKey(const ValueKey('today-main-action')), findsOneWidget);
      }
    });
  }
}

void _flowTests() {
  testWidgets('Start opens the step; Done there marks it and ends the day', (
    tester,
  ) async {
    final repository = FakeAppUserRepository()
      ..today = TodayDashboardData(
        date: '2026-11-24',
        approximateMinutes: 1,
        steps: const [
          TodayStepData(
            id: 'step-1',
            kind: TodayStepKind.passage,
            reason: TodayStepReason.newMaterial,
            estimatedSeconds: 60,
            surah: 78,
            from: WordKey(78, 1, 1),
            to: WordKey(78, 5, 2),
            requiresVoice: true,
          ),
        ],
        extraReview: const [],
        condition: TodayCondition.firstDay,
      );
    final viewModel = TodayViewModel(repository, const E01Config());
    await viewModel.initialize();
    Uri? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: TodayScreen()),
        ),
        GoRoute(
          path: '/read',
          builder: (context, state) {
            opened = state.uri;
            return Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('done-here'),
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ru'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('today-main-action')));
    await tester.pumpAndSettle();

    expect(opened?.queryParameters, {
      'from': '78:1:1',
      'to': '78:5:2',
      'step': 'step-1',
    });

    await tester.tap(find.text('done-here'));
    await tester.pumpAndSettle();

    expect(repository.finished, ['step-1']);
    expect(find.text('Сделано шагов: 1'), findsOneWidget);
  });

  test('a lesson step opens the course', () {
    const lesson = TodayStepData(
      id: 'lesson:first',
      kind: TodayStepKind.lesson,
      reason: TodayStepReason.courseLesson,
      estimatedSeconds: 60,
    );
    expect(locationOfStep(lesson), '/course');
  });
}

Widget _app(TodayViewModel viewModel) => ChangeNotifierProvider.value(
  value: viewModel,
  child: const MaterialApp(
    locale: Locale('ru'),
    localizationsDelegates: [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: TodayScreen()),
  ),
);
