import 'dart:async';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:session/session.dart';
import 'package:test/test.dart';

const _versions = ReadingVersions(
  modelId: 'isolate-test',
  modelVersion: '0',
  rulesVersion: '0',
  textVersion: '0',
);

FutureOr<SessionIsolateWorker> _createTestWorker(Object? _) => _TestWorker();

FutureOr<SessionIsolateWorker> _failToCreateWorker(Object? _) =>
    throw StateError('deliberate startup failure');

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
      case Resume() || Stop() || DisputeEvent():
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

void main() {
  test('long-lived isolate forwards commands, events, states and errors',
      () async {
    final spawned = await ReadingSessionIsolate.spawn(
      factory: _createTestWorker,
    );
    final isolate = switch (spawned) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    addTearDown(isolate.dispose);

    final event = isolate.events.first;
    final state = isolate.states.first;
    expect(
      await isolate.execute(
        const StartSession(
          fromWordKey: WordKey(78, 1, 1),
          toWordKey: WordKey(78, 1, 2),
          mode: SessionMode.recall,
          behavior: SessionBehavior.gentle,
        ),
      ),
      isA<Ok<void>>(),
    );
    expect(await event, isA<SessionStarted>());
    expect((await state).phase, ReadingSessionPhase.ready);

    final strict = isolate.strictSignals.first;
    await isolate.execute(const RequestHint(kind: HintKind.word));
    expect(await strict, isA<OfferHint>());
    expect(await isolate.execute(const Pause()), isA<Error<void>>());
  });

  test('worker startup failures are explicit Result errors', () async {
    final spawned = await ReadingSessionIsolate.spawn(
      factory: _failToCreateWorker,
    );
    expect(spawned, isA<Error<ReadingSessionIsolate>>());
  });
}
