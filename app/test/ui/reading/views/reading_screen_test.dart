import 'dart:async';

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

  testWidgets('start is disabled while the session worker is starting', (
    tester,
  ) async {
    final repository = FakePrototypeRepository();
    final sessionFactory = ManualPrototypeSessionFactory();
    final viewModel = ReadingViewModel(repository, sessionFactory);
    await viewModel.initialize();
    final startResult = Completer<Result<void>>();
    sessionFactory.session.startResult = startResult;
    final start = viewModel.start();

    await tester.pumpWidget(_app(viewModel));
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Start'),
    );
    expect(button.onPressed, isNull);

    startResult.complete(const Result<void>.ok(null));
    await start;
  });

  testWidgets('WAV mode disables pause but keeps stop available', (
    tester,
  ) async {
    final repository = FakePrototypeRepository()
      ..pickedWav = '/selected/measurement.wav';
    final sessionFactory = ManualPrototypeSessionFactory();
    final viewModel = ReadingViewModel(repository, sessionFactory);
    await viewModel.initialize();
    await viewModel.chooseWav();
    await viewModel.start();

    await tester.pumpWidget(_app(viewModel));
    final pause = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Pause'),
    );
    final stop = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Stop'),
    );
    expect(pause.onPressed, isNull);
    expect(stop.onPressed, isNotNull);
  });

  testWidgets('model selector opens while the prototype is ready', (
    tester,
  ) async {
    final viewModel = ReadingViewModel(
      FakePrototypeRepository(),
      ManualPrototypeSessionFactory(),
    );
    await viewModel.initialize();
    await tester.pumpWidget(_app(viewModel));
    final before = find.text('Tiny model').evaluate().length;

    await tester.tap(
      find.byKey(const ValueKey<String>('prototype-model-selector')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tiny model').evaluate().length, greaterThan(before));
  });

  testWidgets('model selector opens after reading is finished', (tester) async {
    final sessionFactory = ManualPrototypeSessionFactory();
    final viewModel = ReadingViewModel(
      FakePrototypeRepository(),
      sessionFactory,
    );
    await viewModel.initialize();
    await viewModel.start();
    sessionFactory.session.emit(
      const SessionFinished(
        sessionId: 'widget',
        atMs: 100,
        words: <SessionWordResult>[],
        eventIds: <String>[],
        durationMs: 100,
        audioWasSuitable: true,
      ),
    );
    await tester.pumpWidget(_app(viewModel));
    final before = find.text('Tiny model').evaluate().length;

    await tester.tap(
      find.byKey(const ValueKey<String>('prototype-model-selector')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tiny model').evaluate().length, greaterThan(before));
  });

  testWidgets('active reading explains why model selection is locked', (
    tester,
  ) async {
    final viewModel = ReadingViewModel(
      FakePrototypeRepository(),
      ManualPrototypeSessionFactory(),
    );
    await viewModel.initialize();
    await viewModel.start();
    await tester.pumpWidget(_app(viewModel));

    final selector = find.byKey(
      const ValueKey<String>('prototype-model-selector'),
    );
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: selector, matching: find.byType(Tooltip)),
    );

    expect(tooltip.message, 'Finish reading first');
  });
}

Widget _app(ReadingViewModel viewModel) =>
    ChangeNotifierProvider<ReadingViewModel>.value(
      value: viewModel,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReadingScreen(),
      ),
    );
