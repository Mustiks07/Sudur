import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_config.dart';
import 'package:audio_capture/src/audio_capture_event.dart';

/// One complete signal-quality window.
final class SignalQualityReading {
  /// Creates a quality reading.
  const SignalQualityReading({
    required this.level,
    required this.dbfs,
    required this.clippedRatio,
    required this.endSample,
  });

  /// Classified condition.
  final SignalQualityLevel level;

  /// Full-window RMS level.
  final double dbfs;

  /// Saturated sample fraction.
  final double clippedRatio;

  /// Absolute end sample of this window.
  final int endSample;
}

/// Streaming RMS, clipping, quiet-speech, and non-speech-noise estimator.
final class SignalQualityEstimator {
  /// Creates an empty estimator.
  SignalQualityEstimator(this._config);

  final AudioCaptureConfig _config;
  var _windowSamples = 0;
  var _windowSquareSum = 0.0;
  var _clippedSamples = 0;
  var _speechSamples = 0;
  var _speechSquareSum = 0.0;
  var _silenceSamples = 0;
  var _silenceSquareSum = 0.0;
  var _processedSamples = 0;
  var _quietHoldMs = 0;
  var _noisyHoldMs = 0;

  /// Adds samples labelled by the VAD and returns any completed windows.
  List<SignalQualityReading> add(
    Float32List samples, {
    required bool isSpeech,
  }) {
    final readings = <SignalQualityReading>[];
    final target = _config.sampleRate * _config.signalWindowMs ~/ 1000;
    var sourceOffset = 0;
    while (sourceOffset < samples.length) {
      final remaining = target - _windowSamples;
      final take = math.min(remaining, samples.length - sourceOffset);
      for (var index = 0; index < take; index++) {
        final sample = samples[sourceOffset + index];
        final square = sample * sample;
        _windowSquareSum += square;
        if (sample.abs() >= 32767 / 32768) {
          _clippedSamples++;
        }
        if (isSpeech) {
          _speechSamples++;
          _speechSquareSum += square;
        } else {
          _silenceSamples++;
          _silenceSquareSum += square;
        }
      }
      _windowSamples += take;
      _processedSamples += take;
      sourceOffset += take;
      if (_windowSamples == target) {
        readings.add(_finishWindow());
      }
    }
    return readings;
  }

  /// Clears accumulated signal statistics and hold timers.
  void reset() {
    _windowSamples = 0;
    _windowSquareSum = 0;
    _clippedSamples = 0;
    _speechSamples = 0;
    _speechSquareSum = 0;
    _silenceSamples = 0;
    _silenceSquareSum = 0;
    _processedSamples = 0;
    _quietHoldMs = 0;
    _noisyHoldMs = 0;
  }

  SignalQualityReading _finishWindow() {
    final dbfs = _dbfs(_windowSquareSum, _windowSamples);
    final speechDbfs = _dbfs(_speechSquareSum, _speechSamples);
    final silenceDbfs = _dbfs(_silenceSquareSum, _silenceSamples);
    final clippedRatio = _clippedSamples / _windowSamples;
    if (_speechSamples > 0 && speechDbfs < _config.quietDbfs) {
      _quietHoldMs += _config.signalWindowMs;
    } else {
      _quietHoldMs = 0;
    }
    if (_silenceSamples > 0 && silenceDbfs > _config.noisyDbfs) {
      _noisyHoldMs += _config.signalWindowMs;
    } else {
      _noisyHoldMs = 0;
    }

    final level = clippedRatio > _config.clippingRatio
        ? SignalQualityLevel.clipping
        : _quietHoldMs >= _config.signalHoldMs
            ? SignalQualityLevel.tooQuiet
            : _noisyHoldMs >= _config.signalHoldMs
                ? SignalQualityLevel.noisy
                : SignalQualityLevel.ok;
    final reading = SignalQualityReading(
      level: level,
      dbfs: dbfs,
      clippedRatio: clippedRatio,
      endSample: _processedSamples,
    );
    _windowSamples = 0;
    _windowSquareSum = 0;
    _clippedSamples = 0;
    _speechSamples = 0;
    _speechSquareSum = 0;
    _silenceSamples = 0;
    _silenceSquareSum = 0;
    return reading;
  }

  double _dbfs(double squareSum, int count) {
    if (count == 0 || squareSum == 0) {
      return -160;
    }
    final rms = math.sqrt(squareSum / count);
    return 20 * math.log(rms) / math.ln10;
  }
}
