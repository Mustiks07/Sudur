import 'dart:io';
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
