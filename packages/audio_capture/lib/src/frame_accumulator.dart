import 'dart:typed_data';

/// Reframes arbitrary stream chunks into fixed-size contiguous frames.
final class FrameAccumulator {
  /// Creates an accumulator emitting [frameSamples] per frame.
  FrameAccumulator(this.frameSamples)
      : assert(frameSamples > 0, 'frameSamples must be positive.'),
        _pending = Float32List(frameSamples);

  /// Samples in each output frame.
  final int frameSamples;
  Float32List _pending;
  var _pendingLength = 0;

  /// Adds a chunk and returns all complete frames.
  List<Float32List> add(Float32List samples) {
    final frames = <Float32List>[];
    var sourceOffset = 0;
    while (sourceOffset < samples.length) {
      final take =
          (frameSamples - _pendingLength) < (samples.length - sourceOffset)
              ? frameSamples - _pendingLength
              : samples.length - sourceOffset;
      _pending.setRange(
        _pendingLength,
        _pendingLength + take,
        samples,
        sourceOffset,
      );
      _pendingLength += take;
      sourceOffset += take;
      if (_pendingLength == frameSamples) {
        frames.add(_pending);
        _pending = Float32List(frameSamples);
        _pendingLength = 0;
      }
    }
    return frames;
  }

  /// Returns and clears the last short frame, if any.
  Float32List? flush() {
    if (_pendingLength == 0) {
      return null;
    }
    final result = Float32List.sublistView(_pending, 0, _pendingLength);
    _pending = Float32List(frameSamples);
    _pendingLength = 0;
    return Float32List.fromList(result);
  }

  /// Drops pending samples.
  void clear() {
    _pending.fillRange(0, _pending.length, 0);
    _pendingLength = 0;
  }
}
