import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_capture/src/vad_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

void main() {
  final modelPath = Platform.environment['SUDUR_SILERO_VAD_PATH'];
  test(
    'drains the native VAD queue over 20 accelerated synthetic minutes',
    () {
      final path = modelPath;
      if (path == null) {
        return;
      }
      const sampleRate = 16000;
      const windowSize = 512;
      const durationMinutes = 20;
      final random = math.Random(0x5D0D);
      sherpa.initBindings();
      final vad = sherpa.VoiceActivityDetector(
        config: sherpa.VadModelConfig(
          sileroVad: sherpa.SileroVadModelConfig(
            model: path,
            threshold: 0.1,
            minSilenceDuration: 0.01,
            minSpeechDuration: 0,
            maxSpeechDuration: 2,
          ),
          debug: false,
        ),
        bufferSizeInSeconds: 4,
      );
      addTearDown(vad.free);
      final frame = Float32List(windowSize);
      const totalSamples =
          sampleRate * Duration.secondsPerMinute * durationMinutes;
      var processedSamples = 0;
      var discarded = 0;
      var queueWasAlwaysDrained = true;
      while (processedSamples < totalSamples) {
        for (var index = 0; index < frame.length; index++) {
          final absoluteSample = processedSamples + index;
          final cycleSample = absoluteSample % (sampleRate * 3);
          if (cycleSample >= sampleRate * 2) {
            frame[index] = 0;
            continue;
          }
          final seconds = absoluteSample / sampleRate;
          final envelope = 0.7 + 0.3 * math.sin(2 * math.pi * 3 * seconds);
          final voiced = math.sin(2 * math.pi * 120 * seconds) +
              0.5 * math.sin(2 * math.pi * 240 * seconds) +
              0.25 * math.sin(2 * math.pi * 360 * seconds);
          final noise = (random.nextDouble() * 2 - 1) * 0.01;
          frame[index] = (voiced * 0.2 + noise) * envelope;
        }
        vad.acceptWaveform(frame);
        discarded += discardCompletedVadSegments(vad);
        queueWasAlwaysDrained = queueWasAlwaysDrained && vad.isEmpty();
        processedSamples += frame.length;
      }
      vad.flush();
      discarded += discardCompletedVadSegments(vad);

      expect(
        processedSamples,
        greaterThanOrEqualTo(
          sampleRate * 60 * durationMinutes,
        ),
      );
      expect(discarded, greaterThan(0));
      expect(queueWasAlwaysDrained, isTrue);
      expect(vad.isEmpty(), isTrue);
    },
    skip: modelPath == null ? 'Set SUDUR_SILERO_VAD_PATH to run.' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
