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
    expect(
      (sessionFactory.session.pauses, sessionFactory.session.resumes),
      (1, 1),
    );
    expect(
      (sessionFactory.session.hints, sessionFactory.session.stops),
      (1, 1),
    );
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
      viewModel.markPageRendered(582);
      await viewModel.start();
      sessionFactory.session.emit(
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
      );
      final json = viewModel.measurementJson;
      final decoded = jsonDecode(json) as Map<String, Object?>;
      final events = switch (decoded['events']) {
        final List<Object?> value => value,
        _ => fail('The measurement log must contain an events list.'),
      };

      expect(json, isNot(contains('EXPECTED_SECRET')));
      expect(json, isNot(contains('HEARD_SECRET')));
      expect(
        events.whereType<Map<String, Object?>>().any(
          (event) => event['type'] == 'MushafPageRendered',
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

    await viewModel.start();

    expect(sessionFactory.sessions, hasLength(2));
    expect(viewModel.wordStates[firstWord], MushafWordState.hidden);
    expect(viewModel.state, ReadingPrototypeState.running);
  });
}
