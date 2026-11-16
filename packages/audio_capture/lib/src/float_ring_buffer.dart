import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_exception.dart';

/// Fixed-capacity Float32 ring addressed by absolute sample positions.
final class FloatRingBuffer {
  /// Creates a zeroed buffer with [capacity] samples.
  FloatRingBuffer(int capacity)
      : assert(capacity > 0, 'capacity must be positive.'),
        _samples = Float32List(capacity);

  final Float32List _samples;
  var _writeIndex = 0;
  var _totalSamples = 0;

  /// Total samples accepted since the last clear.
  int get totalSamples => _totalSamples;

  /// Oldest absolute sample that is still available.
  int get availableStart =>
      _totalSamples > _samples.length ? _totalSamples - _samples.length : 0;

  /// Adds samples, overwriting only the oldest data when full.
  void push(Float32List values) {
    for (final value in values) {
      _samples[_writeIndex] = value;
      _writeIndex = (_writeIndex + 1) % _samples.length;
      _totalSamples++;
    }
  }

  /// Copies absolute half-open range [start], [end] from memory.
  Float32List read(int start, int end) {
    if (start < availableStart ||
        end > _totalSamples ||
        start < 0 ||
        end < start) {
      throw const AudioCaptureException(
        'audioRangeUnavailable',
        'The requested audio is outside the in-memory ring buffer.',
      );
    }
    final result = Float32List(end - start);
    for (var offset = 0; offset < result.length; offset++) {
      result[offset] = _samples[(start + offset) % _samples.length];
    }
    return result;
  }

  /// Zeros all retained audio and resets the absolute clock.
  void clear() {
    _samples.fillRange(0, _samples.length, 0);
    _writeIndex = 0;
    _totalSamples = 0;
  }
}
