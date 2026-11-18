import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:provider/provider.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/reading/view_models/reading_view_model.dart';
import 'package:sudur/ui/reading/views/reading_screen.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('revealed word keeps the same rectangle', (tester) async {
    final repository = FakePrototypeRepository();
    final sessionFactory = ManualPrototypeSessionFactory();
    final viewModel = ReadingViewModel(repository, sessionFactory);
    await viewModel.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider<ReadingViewModel>.value(
        value: viewModel,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReadingScreen(),
        ),
      ),
    );
    await tester.pump();

    final beforePage = tester.widget<MushafPage>(find.byType(MushafPage).first);
    final beforeRect = beforePage.controller?.wordRect(firstWord);
    expect(beforeRect, isNotNull);
    expect(beforePage.wordStates[firstWord], MushafWordState.hidden);

    sessionFactory.session.emit(
      const PositionUpdate(
        sessionId: 'widget',
        atMs: 100,
        word: firstWord,
        confidence: PositionConfidence.high,
      ),
    );
    sessionFactory.session.emit(
      const WordRevealed(
        sessionId: 'widget',
        atMs: 120,
        word: firstWord,
        reason: RevealReason.heard,
      ),
    );
    await tester.pump();

    final afterPage = tester.widget<MushafPage>(find.byType(MushafPage).first);
    expect(afterPage.wordStates[firstWord], MushafWordState.correct);
    expect(afterPage.controller?.wordRect(firstWord), beforeRect);
    expect(find.text('Surah 78 prototype'), findsOneWidget);
  });
}
