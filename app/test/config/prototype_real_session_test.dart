import 'dart:async';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:session/session.dart';
import 'package:sudur/config/prototype_real_session.dart';

void main() {
  test(
    'worker factory builds an idle real session from installed data',
    () async {
      final audio = _FakeAudioSource();
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
