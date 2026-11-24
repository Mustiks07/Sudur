import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:session/session.dart';
import 'package:sudur/config/prototype_real_session.dart';
import 'package:sudur/data/services/prototype_session.dart';

void main() {
  test(
    'worker factory builds an idle real session from installed data',
    () async {
      final audio = _FakeAudioSource();
      final diagnostics = ReceivePort();
      addTearDown(diagnostics.close);
      final worker = createPrototypeSessionWorker(audio, <String, Object?>{
        'contentJson': File(
          '../packages/testing/fixtures/content_p582_583.json',
        ).readAsStringSync(),
        'normalizerJson': '''
        {
          "id": "prototype-test",
          "nfc": true,
          "removeRanges": [],
          "replace": [],
          "wordSeparator": " "
        }
      ''',
        'modelDirectory': '/verified/model',
        'textVersion': 'fixture',
        'rulesVersion': 'test-rules',
        'sessionId': 'prototype-test-1',
        'diagnosticPort': diagnostics.sendPort,
      });
      addTearDown(worker.dispose);

      expect(worker, isA<ReadingSession>());
      expect(worker.state.phase, ReadingSessionPhase.idle);
    },
  );

  test('worker factory rejects an incomplete configuration', () {
    expect(
      () => createPrototypeSessionWorker(
        _FakeAudioSource(),
        const <String, Object?>{},
      ),
      throwsA(isA<PrototypeRealSessionException>()),
    );
  });

  test('concurrent starts await one isolate spawn', () async {
    final spawnGate = Completer<void>();
    var spawnCalls = 0;
    final factory = RealPrototypeReadingSessionFactory(
      spawner: ({required factory, required audioSource, configuration}) async {
        spawnCalls += 1;
        await spawnGate.future;
        return await ReadingSessionIsolate.spawn(
          factory: createLifecycleTestWorker,
          audioSource: audioSource,
        );
      },
    );
    final session = factory.create(_configuration);
    addTearDown(session.dispose);

    final first = session.execute(_startCommand);
    final second = session.execute(_startCommand);
    expect(spawnCalls, 1);

    spawnGate.complete();
    expect(await first, isA<Ok<void>>());
    expect(await second, isA<Ok<void>>());
    expect(spawnCalls, 1);
  });

  test('dispose releases an isolate that appears after startup', () async {
    final spawnGate = Completer<void>();
    ReadingSessionIsolate? lateIsolate;
    final factory = RealPrototypeReadingSessionFactory(
      spawner: ({required factory, required audioSource, configuration}) async {
        await spawnGate.future;
        final result = await ReadingSessionIsolate.spawn(
          factory: createLifecycleTestWorker,
          audioSource: audioSource,
        );
        if (result case Ok<ReadingSessionIsolate>(:final value)) {
          lateIsolate = value;
        }
        return result;
      },
    );
    final session = factory.create(_configuration);

    final start = session.execute(_startCommand);
    final disposing = session.dispose();
    spawnGate.complete();
    await disposing;

    expect(await start, isA<Error<void>>());
    expect(lateIsolate, isNotNull);
    expect(
      await lateIsolate!.execute(const RequestHint(kind: HintKind.word)),
      isA<Error<void>>(),
    );
  });
}

const _configuration = PrototypeSessionConfiguration(
  words: <WordKey>[WordKey(78, 1, 1)],
  contentJson: '{}',
  normalizerJson: '{}',
  modelDirectory: '/unused/model',
  vadModelPath: '/unused/vad.onnx',
  textVersion: 'test-text',
  rulesVersion: 'test-rules',
);

const _startCommand = StartSession(
  fromWordKey: WordKey(78, 1, 1),
  toWordKey: WordKey(78, 1, 1),
  mode: SessionMode.recall,
  behavior: SessionBehavior.gentle,
);

SessionIsolateWorker createLifecycleTestWorker(
  SessionAudioSource audioSource,
  Object? configuration,
) => _LifecycleTestWorker();

final class _LifecycleTestWorker implements SessionIsolateWorker {
  @override
  Stream<SessionEvent> get events => const Stream<SessionEvent>.empty();

  @override
  Stream<ReadingSessionState> get states =>
      const Stream<ReadingSessionState>.empty();

  @override
  Stream<StrictSignal> get strictSignals => const Stream<StrictSignal>.empty();

  @override
  ReadingSessionState get state => ReadingSessionState.idle;

  @override
  Future<Result<void>> execute(SessionCommand command) async =>
      const Result<void>.ok(null);

  @override
  Future<void> dispose() async {}
}

final class _FakeAudioSource implements SessionAudioSource {
  final StreamController<Result<SessionAudioEvent>> _events =
      StreamController<Result<SessionAudioEvent>>.broadcast();

  @override
  Stream<Result<SessionAudioEvent>> get events => _events.stream;

  @override
  Future<Result<void>> start(String sessionId) async =>
      const Result<void>.ok(null);

  @override
  Future<Result<void>> pause() async => const Result<void>.ok(null);

  @override
  Future<Result<void>> resume() async => const Result<void>.ok(null);

  @override
  Future<Result<void>> stop() async => const Result<void>.ok(null);

  @override
  Future<void> dispose() => _events.close();
}
