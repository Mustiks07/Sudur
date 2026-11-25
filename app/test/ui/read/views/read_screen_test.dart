import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/read/view_models/read_view_model.dart';
import 'package:sudur/ui/read/views/read_screen.dart';

import '../../../test_helpers/fake_app_user_repository.dart';
import '../../reading/test_helpers.dart';
import '../read_test_helpers.dart';

void main() {
  late FakeReadingRepository reading;
  late FakeAppUserRepository user;
  late ManualPrototypeSessionFactory sessions;

  setUp(() {
    reading = FakeReadingRepository();
    user = FakeAppUserRepository();
    sessions = ManualPrototypeSessionFactory();
  });

  Future<ReadViewModel> pump(WidgetTester tester, {bool? popped}) async {
    final viewModel = ReadViewModel(
      reading: reading,
      user: user,
      sessionFactory: sessions,
    );
    await viewModel.open(from: w1, to: w3, stepId: 'step-1');
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
                  child: const ReadScreen(),
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
    return viewModel;
  }

  testWidgets('a passage without layout is shown as text; hidden words keep '
      'their place', (tester) async {
    await pump(tester);

    expect(find.byKey(const ValueKey('read-text-view')), findsOneWidget);
    expect(find.text('Сура 2, аяты 255–255'), findsOneWidget);
    final hidden = tester.widget<Text>(find.text('test-2'));
    expect(hidden.style?.color, Colors.transparent);
    expect(find.text('Начинайте читать'), findsOneWidget);
    expect(find.byKey(const ValueKey('read-mode')), findsOneWidget);
  });

  testWidgets('modelMissing offers download and reading without voice', (
    tester,
  ) async {
    reading.voice = false;
    await pump(tester);

    expect(find.text('Модель не скачана'), findsOneWidget);
    expect(find.text('Без голоса'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('read-download')));
    await tester.pumpAndSettle();
    expect(find.text('Начинайте читать'), findsOneWidget);
  });

  testWidgets('pause dims the page; finish writes and returns', (tester) async {
    final viewModel = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('read-start')));
    await tester.pumpAndSettle();
    expect(viewModel.state, ReadState.listening);

    await viewModel.pause();
    await tester.pump();
    expect(find.text('Пауза'), findsWidgets);
    await viewModel.resume();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('read-finish')));
    await tester.pump();
    sessions.session.emit(finishedEvent());
    await tester.pumpAndSettle();

    expect(user.readings, hasLength(1));
    expect(find.byType(ReadScreen), findsNothing, reason: 'returned to Today');
  });
}
