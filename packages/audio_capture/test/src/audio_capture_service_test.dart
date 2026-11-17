import 'dart:io';

import 'package:audio_capture/audio_capture.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not request microphone before the UI explanation', () async {
    final service = AudioCaptureService();
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

  final vadModel = Platform.environment['SUDUR_SILERO_VAD_PATH'];
  test(
    'loads real Silero VAD in the worker isolate',
    () async {
      final model = vadModel;
      if (model == null) {
        return;
      }
      final service = AudioCaptureService();
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
