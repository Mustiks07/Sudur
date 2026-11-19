import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/today/view_models/today_view_model.dart';
import 'package:sudur/ui/today/views/today_screen.dart';

import '../../../test_helpers/fake_app_user_repository.dart';

void main() {
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
