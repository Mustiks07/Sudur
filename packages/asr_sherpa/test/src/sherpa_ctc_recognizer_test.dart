import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing model package is returned as Result.error', () async {
    final recognizer = SherpaCtcRecognizer(sessionId: 'test');
    addTearDown(recognizer.dispose);

    final result = await recognizer.load('/path/that/does/not/exist');

    expect(result, isA<Error<void>>());
  });

  test('isolate failure completes pending and future requests', () async {
    final recognizer = SherpaCtcRecognizer(
      sessionId: 'failure',
      workerEntrypoint: _runFailingWorker,
    );
    addTearDown(recognizer.dispose);

    final loaded =
        await recognizer.load('unused').timeout(const Duration(seconds: 5));
    expect(loaded, isA<Ok<void>>());

    final pendingOutcome = recognizer.outcomes.first;
    recognizer.acceptAudio(Float32List(1), 16000, 0);
    final failedPending = await pendingOutcome.timeout(
      const Duration(seconds: 5),
    );
    expect(_errorCode(failedPending.result), 'workerStopped');

    final benchmark = await recognizer
        .benchmarkDevice()
        .timeout(const Duration(milliseconds: 100));
    expect(_errorCode(benchmark), 'workerStopped');

    final nextOutcome = recognizer.outcomes.first;
    recognizer.acceptAudio(Float32List(1), 16000, 1);
    final failedNew = await nextOutcome.timeout(
      const Duration(milliseconds: 100),
    );
    expect(_errorCode(failedNew.result), 'workerStopped');
  });

  test('loads an active directory through the content package interface',
      () async {
    final recognizer = SherpaCtcRecognizer(
      sessionId: 'content-source',
      workerEntrypoint: _runDelayedWorker,
    );
    addTearDown(recognizer.dispose);
    final source = _FakeModelPackages('/installed/asr/1.0.0');

    expect(
      await recognizer.loadInstalled(source, 'quran-asr-small'),
      isA<Ok<void>>(),
    );
    expect(source.requested, 'quran-asr-small');
  });

  test('model loading leaves the root isolate responsive', () async {
    final recognizer = SherpaCtcRecognizer(
      sessionId: 'non-blocking',
      workerEntrypoint: _runDelayedWorker,
    );
    addTearDown(recognizer.dispose);
    var rootTimerRan = false;
    final loading = recognizer.load('/installed/model');
    Timer.run(() => rootTimerRan = true);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(rootTimerRan, isTrue);
    expect(await loading, isA<Ok<void>>());
  });

  final modelDirectory = Platform.environment['SUDUR_ASR_MODEL_DIR'];
  test(
    'loads and decodes in the worker isolate with a real model',
    () async {
      final directory = modelDirectory;
      if (directory == null) {
        return;
      }
      final recognizer = SherpaCtcRecognizer(sessionId: 'integration');
      addTearDown(recognizer.dispose);
      expect(await recognizer.load(directory), isA<Ok<void>>());
      expect(await recognizer.benchmarkDevice(), isA<Ok<AsrDeviceBenchmark>>());
      final finalResult =
          recognizer.results.firstWhere((result) => result.isFinal);

      recognizer
        ..acceptAudio(Float32List(1600), 16000, 0)
        ..closeSegment(7);

      final result = await finalResult.timeout(const Duration(minutes: 1));
      expect(result.segmentId, 7);
      expect(result.text, isNotNull);
    },
    skip: modelDirectory == null ? 'Set SUDUR_ASR_MODEL_DIR to run.' : false,
  );
}

final class _FakeModelPackages implements AsrModelPackageSource {
  _FakeModelPackages(this.directory);

  final String directory;
  String? requested;

  @override
  Future<Result<String>> activeDirectory(String packageId) async {
    requested = packageId;
    return Result.ok(directory);
  }
}

void _runDelayedWorker(SendPort ownerPort) {
  final requests = ReceivePort();
  ownerPort.send(requests.sendPort);
  requests.listen((message) async {
    if (message is! Map<String, Object?>) return;
    final requestId = message['requestId'];
    final operation = message['operation'];
    if (requestId is! int || operation is! String) return;
    if (operation == 'load') {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      ownerPort.send(<String, Object?>{
        'requestId': requestId,
        'ok': true,
        'value': <String, Object?>{
          'modelId': 'test/model',
          'modelVersion': '1',
          'output': 'uthmaniLettersNoDiacritics',
          'isStreaming': false,
          'hasTokenTimes': true,
        },
      });
      return;
    }
    ownerPort.send(<String, Object?>{
      'requestId': requestId,
      'ok': true,
      'value': null,
    });
    if (operation == 'dispose') requests.close();
  });
}

void _runFailingWorker(SendPort ownerPort) {
  final requests = ReceivePort();
  ownerPort.send(requests.sendPort);
  requests.listen((message) {
    if (message is! Map<String, Object?>) {
      return;
    }
    final requestId = message['requestId'];
    if (message['operation'] == 'load' && requestId is int) {
      ownerPort.send(<String, Object?>{
        'requestId': requestId,
        'ok': true,
        'value': <String, Object?>{
          'modelId': 'test/model',
          'modelVersion': '1',
          'output': 'uthmaniLettersNoDiacritics',
          'isStreaming': false,
          'hasTokenTimes': true,
        },
      });
      return;
    }
    throw StateError('Synthetic worker failure.');
  });
}

String? _errorCode<T>(Result<T> result) => switch (result) {
      Error(:final error) when error is SherpaRecognizerException => error.code,
      _ => null,
    };
