import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/start/view_models/start_view_model.dart';
import 'package:sudur/ui/start/views/start_screen.dart';

import '../../../test_helpers/fake_app_user_repository.dart';

void main() {
  testWidgets('completes the memorization first-run path', (tester) async {
    final repository = FakeAppUserRepository();
    final viewModel = StartViewModel(repository, const E01Config());
    await viewModel.initialize();
    await tester.pumpWidget(_app(viewModel));

    await tester.tap(find.text('Русский'));
    await tester.pump();
    await tester.tap(find.text('Уже читаю, хочу учить наизусть'));
    await tester.pump();
    await tester.tap(find.text('Пропустить'));
    await tester.pump();
    await tester.tap(find.text('5 минут'));
    await tester.pump();
    await tester.tap(find.text('Позже'));
    await tester.pump();
    await tester.tap(find.text('С первой суры'));
    await tester.pump();

    expect(repository.completed, isTrue);
    expect(viewModel.completed, isTrue);
  });
}

Widget _app(StartViewModel viewModel) => ChangeNotifierProvider.value(
  value: viewModel,
  child: const MaterialApp(
    locale: Locale('ru'),
    localizationsDelegates: [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: StartScreen(),
  ),
);
