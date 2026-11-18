import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_capture/audio_capture.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

void main() {
  test('does not request microphone before the UI explanation', () async {
    final service = AudioCaptureService(
      sessionId: 'permission-test',
      recorderPort: _FakeRecorder(),
      workerEntrypoint: _runFakeWorker,
    );
    addTearDown(service.dispose);

    final result = await service.startMicrophone(
      vadModelPath: 'unused',
      permissionExplanationShown: false,
    );

    expect(result, isA<Error<void>>());
    final error = (result as Error<void>).error;
    expect(error, isA<AudioCaptureException>());
    expect(
      (error as AudioCaptureException).code,
      'permissionExplanationRequired',
    );
  });

  test('permission denial returns self-check error before worker start',
      () async {
    final recorder = _FakeRecorder(permission: false);
    final service = AudioCaptureService(
      sessionId: 'denied',
      recorderPort: recorder,
      workerEntrypoint: _runFakeWorker,
    );
    addTearDown(service.dispose);

    final result = await service.startMicrophone(
      vadModelPath: 'unused',
      permissionExplanationShown: true,
    );

    expect(result, isA<Error<void>>());
    expect((result as Error<void>).error, isA<AudioCaptureException>());
    expect((result.error as AudioCaptureException).code, 'micDenied');
    expect(recorder.startCalls, 0);
  });

  test('playback suppresses microphone events until it ends', () async {
    final recorder = _FakeRecorder();
    final service = AudioCaptureService(
      sessionId: 'playback',
      recorderPort: recorder,
      workerEntrypoint: _runFakeWorker,
    );
    addTearDown(service.dispose);
    final events = <Object>[];
    final subscription = service.events.listen((result) {
      if (result case Ok<Object>(:final value)) events.add(value);
    });
    addTearDown(subscription.cancel);
    expect(
      await service.startMicrophone(
        vadModelPath: 'unused',
        permissionExplanationShown: true,
      ),
      isA<Ok<void>>(),
    );

    await service.setPlaybackActive(true);
    recorder.addPcm(Uint8List(640));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(events.whereType<SpeechSegmentOpened>(), isEmpty);

    await service.setPlaybackActive(false);
    recorder.addPcm(Uint8List(640));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(events.whereType<SpeechSegmentOpened>(), hasLength(1));
  });

  test('playback enabled before capture starts keeps the recorder paused',
      () async {
    final recorder = _FakeRecorder();
    final service = AudioCaptureService(
      sessionId: 'early-playback',
      recorderPort: recorder,
      workerEntrypoint: _runFakeWorker,
    );
    addTearDown(service.dispose);

    expect(await service.setPlaybackActive(true), isA<Ok<void>>());
    expect(
      await service.startMicrophone(
        vadModelPath: 'unused',
        permissionExplanationShown: true,
      ),
      isA<Ok<void>>(),
    );
    expect(recorder.startCalls, 1);
    expect(recorder.pauseCalls, 1);
  });

  test('system interruption reaches coordinator once with Bluetooth warning',
      () async {
    final recorder = _FakeRecorder();
    final service = AudioCaptureService(
      sessionId: 'interrupt',
      recorderPort: recorder,
      workerEntrypoint: _runFakeWorker,
    );
    final automaticPause = Completer<CapturePaused>();
    final source = AudioCaptureSessionSource(
      capture: service,
      vadModelPath: 'unused',
      permissionExplanationShown: true,
      onAutomaticPause: (event) async => automaticPause.complete(event),
    );
    addTearDown(source.dispose);
    expect(await source.start('interrupt'), isA<Ok<void>>());

    expect(
      await service.notifyInterruption(
        CapturePauseReason.deviceChanged,
        bluetoothInput: true,
      ),
      isA<Ok<void>>(),
    );
    final event = await automaticPause.future;
    expect(event.reason, CapturePauseReason.deviceChanged);
    expect(event.bluetoothInput, isTrue);
    expect(recorder.pauseCalls, 1);

    // The session's Pause command follows the callback and must not pause the
    // already stopped capture a second time; it can safely save a checkpoint.
    expect(await source.pause(), isA<Ok<void>>());
    expect(recorder.pauseCalls, 1);
  });

  final vadModel = Platform.environment['SUDUR_SILERO_VAD_PATH'];
  test(
    'loads real Silero VAD in the worker isolate',
    () async {
      final model = vadModel;
      if (model == null) {
        return;
      }
      final service = AudioCaptureService(sessionId: 'vad-test');
      addTearDown(service.dispose);

      final result = await service.startFile(
        vadModelPath: model,
        wavPath: '/path/that/does/not/exist.wav',
      );

      expect(result, isA<Error<void>>());
      final error = (result as Error<void>).error as AudioCaptureException;
      expect(error.code, 'fileReadFailed');
    },
    skip: vadModel == null ? 'Set SUDUR_SILERO_VAD_PATH to run.' : false,
  );
}

final class _FakeRecorder implements AudioRecorderPort {
  _FakeRecorder({this.permission = true});

  final bool permission;
  final StreamController<Uint8List> _pcm =
      StreamController<Uint8List>.broadcast();
  final StreamController<RecordState> _states =
      StreamController<RecordState>.broadcast();
  int startCalls = 0;
  int pauseCalls = 0;

  void addPcm(Uint8List value) => _pcm.add(value);

  @override
  Future<void> dispose() async {
    await _pcm.close();
    await _states.close();
  }

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Stream<RecordState> onStateChanged() => _states.stream;

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> resume() async {}

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    startCalls++;
    return _pcm.stream;
  }

  @override
  Future<String?> stop() async => null;
}

void _runFakeWorker(SendPort ownerPort) {
  final requests = ReceivePort();
  ownerPort.send(requests.sendPort);
  var atMs = 0;
  requests.listen((raw) {
    if (raw is! Map<String, Object?>) return;
    final requestId = raw['requestId'];
    final operation = raw['operation'];
    if (requestId is! int || operation is! String) return;
    if (operation == 'audio') {
      atMs += 20;
      ownerPort.send(<String, Object?>{
        'type': 'event',
        'kind': 'segmentOpened',
        'atMs': atMs,
        'segmentId': atMs,
      });
    } else if (operation == 'pause') {
      ownerPort.send(<String, Object?>{
        'type': 'event',
        'kind': 'paused',
        'atMs': atMs,
        'reason': raw['reason'],
        'bluetoothInput': raw['bluetoothInput'],
      });
    }
    ownerPort.send(<String, Object?>{
      'type': 'response',
      'requestId': requestId,
      'ok': true,
      'value': null,
    });
    if (operation == 'dispose') requests.close();
  });
}
