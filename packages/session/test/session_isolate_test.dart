import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:session/session.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

const _versions = ReadingVersions(
  modelId: 'isolate-test',
  modelVersion: '0',
  rulesVersion: '0',
  textVersion: '0',
);

FutureOr<SessionIsolateWorker> _createTestWorker(
  SessionAudioSource _,
  Object? configuration,
) =>
    _TestWorker();

FutureOr<SessionIsolateWorker> _failToCreateWorker(
  SessionAudioSource _,
  Object? configuration,
) =>
    throw StateError('deliberate startup failure');

FutureOr<SessionIsolateWorker> _createBridgeWorker(
  SessionAudioSource audioSource,
  Object? configuration,
) =>
    _BridgeWorker(audioSource);

FutureOr<SessionIsolateWorker> _createConcurrentStopWorker(
  SessionAudioSource _,
  Object? configuration,
) =>
    _ConcurrentStopWorker();

final class _TestWorker implements SessionIsolateWorker {
  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast(sync: true);
  final StreamController<ReadingSessionState> _states =
      StreamController<ReadingSessionState>.broadcast(sync: true);
  final StreamController<StrictSignal> _strict =
      StreamController<StrictSignal>.broadcast(sync: true);

  ReadingSessionState _state = ReadingSessionState.idle;

  @override
  Stream<SessionEvent> get events => _events.stream;

  @override
  Stream<ReadingSessionState> get states => _states.stream;

  @override
  Stream<StrictSignal> get strictSignals => _strict.stream;

  @override
  ReadingSessionState get state => _state;

  @override
  Future<Result<void>> execute(SessionCommand command) async {
    switch (command) {
      case StartSession():
        _state = const ReadingSessionState(ReadingSessionPhase.ready);
        _states.add(_state);
        _events.add(
          SessionStarted(
            sessionId: 'isolate-session',
            atMs: 0,
            fromWordKey: command.fromWordKey,
            toWordKey: command.toWordKey,
            mode: command.mode,
            versions: _versions,
          ),
        );
        return const Result<void>.ok(null);
      case RequestHint():
        _strict.add(
          const OfferHint(word: WordKey(78, 1, 1), atMs: 10),
        );
        return const Result<void>.ok(null);
      case Pause():
        return const Result<void>.error(
          ReadingSessionException('testFailure', 'Deliberate failure.'),
        );
      case Resume():
        Isolate.exit();
      case Stop():
        return await Completer<Result<void>>().future;
      case DisputeEvent():
        return const Result<void>.ok(null);
    }
  }

  @override
  Future<void> dispose() async {
    await _events.close();
    await _states.close();
    await _strict.close();
  }
}

final class _BridgeWorker implements SessionIsolateWorker {
  _BridgeWorker(this._audioSource);

  final SessionAudioSource _audioSource;
  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast(sync: true);
  final StreamController<ReadingSessionState> _states =
      StreamController<ReadingSessionState>.broadcast(sync: true);
  final StreamController<StrictSignal> _strict =
      StreamController<StrictSignal>.broadcast(sync: true);
  StreamSubscription<Result<SessionAudioEvent>>? _audioSubscription;

  @override
  Stream<SessionEvent> get events => _events.stream;

  @override
  Stream<ReadingSessionState> get states => _states.stream;

  @override
  Stream<StrictSignal> get strictSignals => _strict.stream;

  @override
  ReadingSessionState get state => ReadingSessionState.idle;

  @override
  Future<Result<void>> execute(SessionCommand command) {
    return switch (command) {
      StartSession() => _start(),
      Pause() => _audioSource.pause(),
      Resume() => _audioSource.resume(),
      Stop() => _audioSource.stop(),
      RequestHint() ||
      DisputeEvent() =>
        Future<Result<void>>.value(const Result<void>.ok(null)),
    };
  }

  Future<Result<void>> _start() {
    _audioSubscription ??= _audioSource.events.listen(_onAudio);
    return _audioSource.start('bridge-session');
  }

  void _onAudio(Result<SessionAudioEvent> result) {
    switch (result) {
      case Ok<SessionAudioEvent>(value: final SessionAudioFrame frame):
        _events.add(
          SignalQuality(
            sessionId: 'bridge-session',
            atMs: frame.atMs,
            level: SignalQualityLevel.ok,
            dbfs: frame.samples.first,
            clippedRatio: frame.samples.last,
          ),
        );
      case Ok<SessionAudioEvent>(value: final SignalQuality quality):
        _events.add(quality);
      default:
        break;
    }
  }

  @override
  Future<void> dispose() async {
    await _audioSubscription?.cancel();
    await _audioSource.dispose();
    await _events.close();
    await _states.close();
    await _strict.close();
  }
}

final class _ConcurrentStopWorker implements SessionIsolateWorker {
  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast(sync: true);
  final StreamController<ReadingSessionState> _states =
      StreamController<ReadingSessionState>.broadcast(sync: true);
  final StreamController<StrictSignal> _strict =
      StreamController<StrictSignal>.broadcast(sync: true);
  ReadingSessionState _state =
      const ReadingSessionState(ReadingSessionPhase.ready);

  @override
  Stream<SessionEvent> get events => _events.stream;

  @override
  Stream<ReadingSessionState> get states => _states.stream;

  @override
  Stream<StrictSignal> get strictSignals => _strict.stream;

  @override
  ReadingSessionState get state => _state;

  @override
  Future<Result<void>> execute(SessionCommand command) async {
    if (command is! Stop) return const Result<void>.ok(null);
    if (_state.phase != ReadingSessionPhase.ready) {
      return const Result<void>.error(
        ReadingSessionException(
          'invalidState',
          'The session has already finished.',
        ),
      );
    }
    // Mirrors ReadingSession._stop before it enters finishing: both calls can
    // observe ready while the source is still stopping unless commands are
    // serialized by the public isolate wrapper.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    _state = const ReadingSessionState(ReadingSessionPhase.finished);
    _states.add(_state);
    _events.add(
      const SessionFinished(
        sessionId: 'stop-race',
        atMs: 10,
        words: <SessionWordResult>[
          SessionWordResult(
            wordKey: WordKey(78, 1, 1),
            outcome: SessionWordOutcome.notRead,
          ),
        ],
        eventIds: <String>[],
        durationMs: 10,
        audioWasSuitable: true,
      ),
    );
    return const Result<void>.ok(null);
  }

  @override
  Future<void> dispose() async {
    await _events.close();
    await _states.close();
    await _strict.close();
  }
}

StartSession get _startCommand => const StartSession(
      fromWordKey: WordKey(78, 1, 1),
      toWordKey: WordKey(78, 1, 2),
      mode: SessionMode.recall,
      behavior: SessionBehavior.gentle,
    );

Future<ReadingSessionIsolate> _spawnTestWorker(
  FakeSessionAudioSource audio,
) async {
  final spawned = await ReadingSessionIsolate.spawn(
    factory: _createTestWorker,
    audioSource: audio,
  );
  return switch (spawned) {
    Ok(:final value) => value,
    Error(:final error) => throw error,
  };
}

void main() {
  test('long-lived isolate forwards commands, events, states and errors',
      () async {
    final isolate = await _spawnTestWorker(FakeSessionAudioSource());
    addTearDown(isolate.dispose);

    final event = isolate.events.first;
    final state = isolate.states.first;
    expect(await isolate.execute(_startCommand), isA<Ok<void>>());
    expect(await event, isA<SessionStarted>());
    expect((await state).phase, ReadingSessionPhase.ready);

    final strict = isolate.strictSignals.first;
    await isolate.execute(const RequestHint(kind: HintKind.word));
    expect(await strict, isA<OfferHint>());
    expect(await isolate.execute(const Pause()), isA<Error<void>>());
  });

  test('commands after worker exit fail instead of hanging', () async {
    final isolate = await _spawnTestWorker(FakeSessionAudioSource());
    addTearDown(isolate.dispose);
    final failure = isolate.failures.first;

    expect(
      await isolate.execute(const Resume()).timeout(const Duration(seconds: 1)),
      isA<Error<void>>(),
    );
    await failure;
    expect(
      await isolate
          .execute(const Pause())
          .timeout(const Duration(milliseconds: 100)),
      isA<Error<void>>(),
    );
  });

  test('dispose completes commands that the worker has not finished', () async {
    final isolate = await _spawnTestWorker(FakeSessionAudioSource());
    final pending = isolate.execute(const Stop());

    final disposing = isolate.dispose();
    expect(
      await pending.timeout(const Duration(milliseconds: 100)),
      isA<Error<void>>(),
    );
    await disposing.timeout(const Duration(seconds: 1));
  });

  test('public wrapper serializes simultaneous Stop commands', () async {
    final spawned = await ReadingSessionIsolate.spawn(
      factory: _createConcurrentStopWorker,
      audioSource: FakeSessionAudioSource(),
    );
    final isolate = switch (spawned) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    addTearDown(isolate.dispose);
    final finished = <SessionFinished>[];
    final subscription = isolate.events
        .where((event) => event is SessionFinished)
        .cast<SessionFinished>()
        .listen(finished.add);
    addTearDown(subscription.cancel);

    final results = await Future.wait<Result<void>>(
      <Future<Result<void>>>[
        isolate.execute(const Stop()),
        isolate.execute(const Stop()),
      ],
    );

    expect(results.whereType<Ok<void>>(), hasLength(1));
    expect(results.whereType<Error<void>>(), hasLength(1));
    expect(finished, hasLength(1));
  });

  test('platform audio stays in root and frames cross the transferable bridge',
      () async {
    final audio = FakeSessionAudioSource();
    final spawned = await ReadingSessionIsolate.spawn(
      factory: _createBridgeWorker,
      audioSource: audio,
    );
    final isolate = switch (spawned) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    addTearDown(isolate.dispose);

    expect(await isolate.execute(_startCommand), isA<Ok<void>>());
    expect(audio.sessionId, 'bridge-session');
    expect(await isolate.execute(const Pause()), isA<Ok<void>>());
    expect(await isolate.execute(const Resume()), isA<Ok<void>>());
    expect(audio.pauseCalls, 1);
    expect(audio.resumeCalls, 1);
    final bridgedFrame =
        isolate.events.where((event) => event is SignalQuality).first;
    audio.emit(
      SessionAudioFrame(
        atMs: 120,
        segmentId: 7,
        samples: Float32List.fromList(<double>[0.25, -0.75]),
        sampleRateHz: 16000,
        startMs: 100,
        endMs: 120,
      ),
    );

    final frameEcho = await bridgedFrame as SignalQuality;
    expect(frameEcho.atMs, 120);
    expect(frameEcho.dbfs, 0.25);
    expect(frameEcho.clippedRatio, -0.75);

    final bridgedQuality = isolate.events
        .where((event) => event is SignalQuality && event.atMs == 200)
        .first;
    audio.emit(
      const SignalQuality(
        sessionId: 'bridge-session',
        atMs: 200,
        level: SignalQualityLevel.noisy,
        sinceMs: 150,
      ),
    );
    final qualityEcho = await bridgedQuality as SignalQuality;
    expect(qualityEcho.level, SignalQualityLevel.noisy);
    expect(qualityEcho.sinceMs, 150);

    expect(await isolate.execute(const Stop()), isA<Ok<void>>());
    expect(audio.stopCalls, 1);
  });

  test('worker startup failures are explicit and dispose root audio', () async {
    final audio = FakeSessionAudioSource();
    final spawned = await ReadingSessionIsolate.spawn(
      factory: _failToCreateWorker,
      audioSource: audio,
    );
    expect(spawned, isA<Error<ReadingSessionIsolate>>());
    expect(audio.disposed, isTrue);
  });
}
