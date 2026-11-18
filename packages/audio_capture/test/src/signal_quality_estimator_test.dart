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
    final bad = estimator.add(quiet, isSpeech: true).single;
    expect(bad.level, SignalQualityLevel.tooQuiet);
    expect(bad.sinceSample, 0);
  });

  test('reports clipping immediately', () {
    final estimator = SignalQualityEstimator(config);
    final clipped = Float32List(1000)..fillRange(0, 20, 1);

    final bad = estimator.add(clipped, isSpeech: true).single;
    expect(bad.level, SignalQualityLevel.clipping);
    expect(bad.sinceSample, 0);
  });

  test('reports persistent non-speech noise', () {
    final estimator = SignalQualityEstimator(config);
    final noise = Float32List.fromList(
      List<double>.generate(1000, (index) => index.isEven ? 0.1 : -0.1),
    );

    estimator
      ..add(noise, isSpeech: false)
      ..add(noise, isSpeech: false);
    final bad = estimator.add(noise, isSpeech: false).single;
    expect(bad.level, SignalQualityLevel.noisy);
    expect(bad.sinceSample, 0);
  });

  test('reports bad-stretch start on the preserved session timeline', () {
    final estimator = SignalQualityEstimator(config)..reset(startSample: 5000);
    final quiet = Float32List.fromList(List<double>.filled(1000, 0.001));

    estimator
      ..add(quiet, isSpeech: true)
      ..add(quiet, isSpeech: true);
    final bad = estimator.add(quiet, isSpeech: true).single;

    expect(bad.endSample, 8000);
    expect(bad.sinceSample, 5000);
  });
}
