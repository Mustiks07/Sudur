import 'dart:typed_data';

import 'package:audio_capture/audio_capture.dart';
import 'package:audio_capture/src/signal_quality_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = AudioCaptureConfig(sampleRate: 1000);

  test('reports quiet speech only after the hold duration', () {
    final estimator = SignalQualityEstimator(config);
    final quiet = Float32List.fromList(List<double>.filled(1000, 0.001));

    expect(
      estimator.add(quiet, isSpeech: true).single.level,
      SignalQualityLevel.ok,
    );
    expect(
      estimator.add(quiet, isSpeech: true).single.level,
      SignalQualityLevel.ok,
    );
    expect(
      estimator.add(quiet, isSpeech: true).single.level,
      SignalQualityLevel.tooQuiet,
    );
  });

  test('reports clipping immediately', () {
    final estimator = SignalQualityEstimator(config);
    final clipped = Float32List(1000)..fillRange(0, 20, 1);

    expect(
      estimator.add(clipped, isSpeech: true).single.level,
      SignalQualityLevel.clipping,
    );
  });

  test('reports persistent non-speech noise', () {
    final estimator = SignalQualityEstimator(config);
    final noise = Float32List.fromList(
      List<double>.generate(1000, (index) => index.isEven ? 0.1 : -0.1),
    );

    estimator
      ..add(noise, isSpeech: false)
      ..add(noise, isSpeech: false);
    expect(
      estimator.add(noise, isSpeech: false).single.level,
      SignalQualityLevel.noisy,
    );
  });
}
