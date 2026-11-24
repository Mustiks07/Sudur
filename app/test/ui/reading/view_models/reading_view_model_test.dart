import 'dart:async';
import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_session.dart';
import 'package:sudur/ui/reading/view_models/reading_view_model.dart';

import '../test_helpers.dart';

void main() {
  late FakePrototypeRepository repository;
  late ManualPrototypeSessionFactory sessionFactory;
  late ReadingViewModel viewModel;

  setUp(() async {
    repository = FakePrototypeRepository();
    sessionFactory = ManualPrototypeSessionFactory();
    viewModel = ReadingViewModel(repository, sessionFactory);
    await viewModel.initialize();
  });

  test('session events reveal words and commands keep their state', () async {
    expect(viewModel.state, ReadingPrototypeState.ready);
    expect(viewModel.wordStates[firstWord], MushafWordState.hidden);

    await viewModel.start();
    expect(sessionFactory.session.input, isA<PrototypeMicrophoneInput>());
    sessionFactory.session.emit(
      const PositionUpdate(
        sessionId: 'test',
        atMs: 100,
        word: firstWord,
        confidence: PositionConfidence.high,
      ),
    );
    expect(viewModel.wordStates[firstWord], MushafWordState.current);

    sessionFactory.session.emit(
      const WordRevealed(
        sessionId: 'test',
        atMs: 120,
        word: firstWord,
        reason: RevealReason.heard,
      ),
    );
    expect(viewModel.wordStates[firstWord], MushafWordState.correct);

    await viewModel.pause();
    await viewModel.resume();
    await viewModel.requestHint();
    await viewModel.stop();
    sessionFactory.session.emit(
      const SessionFinished(
        sessionId: 'test',
        atMs: 200,
        words: <SessionWordResult>[
          SessionWordResult(
            wordKey: firstWord,
            outcome: SessionWordOutcome.read,
          ),
          SessionWordResult(
            wordKey: secondWord,
            outcome: SessionWordOutcome.notRead,
          ),
        ],
        eventIds: <String>[],
        durationMs: 200,
        audioWasSuitable: true,
      ),
    );
    expect(
      (sessionFactory.session.pauses, sessionFactory.session.resumes),
      (1, 1),
    );
    expect(
      (sessionFactory.session.hints, sessionFactory.session.stops),
      (1, 1),
    );
    expect(
      sessionFactory.session.commands.map((command) => command.runtimeType),
      <Type>[StartSession, Pause, Resume, RequestHint, Stop],
    );
    expect(viewModel.state, ReadingPrototypeState.finished);
  });

  test('a second start is blocked while the first start is pending', () async {
    final startResult = Completer<Result<void>>();
    sessionFactory.session.startResult = startResult;

    final firstStart = viewModel.start();
    expect(viewModel.state, ReadingPrototypeState.starting);

    await viewModel.start();
    expect(
      sessionFactory.session.commands.whereType<StartSession>(),
      hasLength(1),
    );

    startResult.complete(const Result<void>.ok(null));
    await firstStart;
    expect(viewModel.state, ReadingPrototypeState.running);
  });

  test('moving position never hides an already revealed word', () {
    sessionFactory.session
      ..emit(
        const WordRevealed(
          sessionId: 'test',
          atMs: 100,
          word: firstWord,
          reason: RevealReason.heard,
        ),
      )
      ..emit(
        const PositionUpdate(
          sessionId: 'test',
          atMs: 110,
          word: firstWord,
          confidence: PositionConfidence.high,
        ),
      )
      ..emit(
        const PositionUpdate(
          sessionId: 'test',
          atMs: 120,
          word: secondWord,
          confidence: PositionConfidence.high,
        ),
      );

    expect(viewModel.wordStates[firstWord], MushafWordState.correct);
    expect(viewModel.wordStates[secondWord], MushafWordState.current);
  });

  test('new ADR 0005 events update checks, hints, and final results', () {
    sessionFactory.session
      ..emit(
        const CheckEvent(
          sessionId: 'test',
          atMs: 100,
          eventId: 'check-1',
          kind: CheckKind.omission,
          state: CheckState.preliminary,
          words: <WordKey>[firstWord],
          expectedText: '',
          heardText: '',
          audioStartMs: 0,
          audioEndMs: 100,
          versions: ReadingVersions(
            modelId: 'model',
            modelVersion: '1',
            rulesVersion: '1',
            textVersion: '1',
          ),
        ),
      )
      ..emit(
        const CheckStateChanged(
          sessionId: 'test',
          atMs: 110,
          eventId: 'check-1',
          from: CheckState.preliminary,
          to: CheckState.confirmed,
          reason: 'context',
        ),
      )
      ..emit(
        const HintGiven(
          sessionId: 'test',
          atMs: 120,
          kind: HintKind.word,
          wordKey: secondWord,
        ),
      );

    expect(viewModel.wordStates[firstWord], MushafWordState.error);
    expect(viewModel.wordStates[secondWord], MushafWordState.revealedByHint);

    sessionFactory.session.emit(
      const SessionFinished(
        sessionId: 'test',
        atMs: 200,
        words: <SessionWordResult>[
          SessionWordResult(
            wordKey: firstWord,
            outcome: SessionWordOutcome.corrected,
          ),
          SessionWordResult(
            wordKey: secondWord,
            outcome: SessionWordOutcome.readWithHint,
          ),
        ],
        eventIds: <String>['check-1'],
        durationMs: 200,
        audioWasSuitable: true,
      ),
    );

    expect(viewModel.wordStates[firstWord], MushafWordState.corrected);
    expect(viewModel.wordStates[secondWord], MushafWordState.revealedByHint);
    expect(viewModel.state, ReadingPrototypeState.finished);
  });

  test(
    'WAV and model selection pass only through injected boundaries',
    () async {
      repository.pickedWav = '/selected/measurement.wav';
      await viewModel.chooseWav();
      expect(viewModel.selectedWavName, 'measurement.wav');

      await viewModel.start();
      expect(sessionFactory.session.input, isA<PrototypeWavInput>());
      expect(viewModel.canPause, isFalse);
      await viewModel.pause();
      expect(sessionFactory.session.pauses, 0);
      expect(viewModel.state, ReadingPrototypeState.running);
      sessionFactory.session.emit(
        const SessionFinished(
          sessionId: 'test',
          atMs: 100,
          words: <SessionWordResult>[],
          eventIds: <String>[],
          durationMs: 100,
          audioWasSuitable: true,
        ),
      );
      await viewModel.selectModel(PrototypeModelChoice.tiny);
      expect(repository.preparedModels, <PrototypeModelChoice>[
        PrototypeModelChoice.small,
        PrototypeModelChoice.tiny,
      ]);
    },
  );

  test(
    'measurement log contains timing but excludes Quran and heard text',
    () async {
      viewModel
        ..beginPageRender(582)
        ..markPageRendered(582);
      await viewModel.start();
      sessionFactory.session
        ..emitDiagnostic(
          const PrototypeSessionDiagnostic(
            PrototypeDiagnosticKind.segmentOpened,
          ),
        )
        ..emitDiagnostic(
          const PrototypeSessionDiagnostic(
            PrototypeDiagnosticKind.recognitionPartial,
            decodeMs: 31,
          ),
        )
        ..emitDiagnostic(
          const PrototypeSessionDiagnostic(
            PrototypeDiagnosticKind.recognitionFinal,
            decodeMs: 47,
          ),
        )
        ..emitDiagnostic(
          const PrototypeSessionDiagnostic(
            PrototypeDiagnosticKind.segmentClosed,
          ),
        )
        ..emit(
          const SessionStarted(
            sessionId: 'test',
            atMs: 0,
            fromWordKey: firstWord,
            toWordKey: secondWord,
            mode: SessionMode.recall,
            versions: ReadingVersions(
              modelId: 'model',
              modelVersion: '1',
              rulesVersion: '1',
              textVersion: '1',
            ),
          ),
        )
        ..emit(
          const CheckEvent(
            sessionId: 'test',
            atMs: 500,
            eventId: 'event-1',
            kind: CheckKind.substitution,
            state: CheckState.confirmed,
            words: <WordKey>[firstWord],
            expectedText: 'EXPECTED_SECRET',
            heardText: 'HEARD_SECRET',
            audioStartMs: 100,
            audioEndMs: 450,
            versions: ReadingVersions(
              modelId: 'model',
              modelVersion: '1',
              rulesVersion: '1',
              textVersion: '1',
            ),
          ),
        )
        ..emitFailure(const FormatException('PRIVATE_FAILURE_DETAIL'));
      final json = viewModel.measurementJson;
      final decoded = jsonDecode(json) as Map<String, Object?>;
      final diagnostics = decoded['diagnostics']! as Map<String, Object?>;
      final events = switch (decoded['events']) {
        final List<Object?> value => value,
        _ => fail('The measurement log must contain an events list.'),
      };

      expect(json, isNot(contains('EXPECTED_SECRET')));
      expect(json, isNot(contains('HEARD_SECRET')));
      expect(json, isNot(contains('PRIVATE_FAILURE_DETAIL')));
      expect(diagnostics['segmentsOpened'], 1);
      expect(diagnostics['segmentsClosed'], 1);
      expect(diagnostics['recognitionResults'], 2);
      expect(diagnostics['recognitionPartial'], 1);
      expect(diagnostics['recognitionFinal'], 1);
      expect(diagnostics['recognitionDecodeMsTotal'], 78);
      expect(diagnostics['recognitionDecodeMsMax'], 47);
      expect(diagnostics['positionUpdates'], 0);
      expect(diagnostics['wordsRevealed'], 0);
      expect(diagnostics['lastErrorReason'], 'FormatException');
      expect(
        events.whereType<Map<String, Object?>>().any(
          (event) =>
              event['type'] == 'SessionStarted' &&
              event.containsKey('uiAtSessionMs'),
        ),
        isTrue,
      );
      expect(viewModel.wordStates[firstWord], MushafWordState.error);

      await viewModel.shareLog();
      expect(repository.sharedLog, json);
    },
  );

  test('phone benchmark result comes from the repository', () async {
    await viewModel.runDeviceTest();

    expect(viewModel.benchmarkResult?.speedRatio, 0.25);
    expect(viewModel.isBenchmarking, isFalse);
  });

  test('each page first-frame timer starts with that page request', () async {
    var nowMs = 100;
    final timedViewModel = ReadingViewModel(
      FakePrototypeRepository(),
      ManualPrototypeSessionFactory(),
      monotonicMilliseconds: () => nowMs,
    );
    await timedViewModel.initialize();

    timedViewModel.beginPageRender(582);
    nowMs = 400;
    timedViewModel.markPageRendered(582);
    nowMs = 900;
    timedViewModel.beginPageRender(583);
    nowMs = 920;
    timedViewModel.markPageRendered(583);

    final decoded =
        jsonDecode(timedViewModel.measurementJson) as Map<String, Object?>;
    final events = decoded['events']! as List<Object?>;
    final pages = events
        .whereType<Map<String, Object?>>()
        .where((event) => event['type'] == 'MushafPageRendered')
        .toList();

    expect(pages, <Map<String, Object?>>[
      <String, Object?>{
        'type': 'MushafPageRendered',
        'page': 582,
        'firstFrameMs': 300,
      },
      <String, Object?>{
        'type': 'MushafPageRendered',
        'page': 583,
        'firstFrameMs': 20,
      },
    ]);
    timedViewModel.dispose();
  });

  test('a finished run starts with a fresh hidden-word session', () async {
    await viewModel.start();
    sessionFactory.session.emit(
      const WordRevealed(
        sessionId: 'first',
        atMs: 120,
        word: firstWord,
        reason: RevealReason.heard,
      ),
    );
    await viewModel.stop();
    sessionFactory.session.emit(
      const SessionFinished(
        sessionId: 'first',
        atMs: 200,
        words: <SessionWordResult>[
          SessionWordResult(
            wordKey: firstWord,
            outcome: SessionWordOutcome.read,
          ),
          SessionWordResult(
            wordKey: secondWord,
            outcome: SessionWordOutcome.notRead,
          ),
        ],
        eventIds: <String>[],
        durationMs: 200,
        audioWasSuitable: true,
      ),
    );

    await viewModel.start();

    expect(sessionFactory.sessions, hasLength(2));
    expect(viewModel.wordStates[firstWord], MushafWordState.hidden);
    expect(viewModel.state, ReadingPrototypeState.running);
  });
}
