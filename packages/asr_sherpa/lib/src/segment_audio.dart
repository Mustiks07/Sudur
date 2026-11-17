import 'dart:typed_data';

/// In-memory audio for the currently open speech segment.
final class SegmentAudio {
  final List<Float32List> _chunks = <Float32List>[];
  int _length = 0;

  /// Start in session time, or null before the first chunk.
  int? get startMs => _startMs;
  int? _startMs;

  /// End in session time, or null before the first chunk.
  int? get endMs => _endMs;
  int? _endMs;

  /// Number of buffered samples.
  int get length => _length;

  /// Adds a chunk. Samples remain in memory only.
  void add(Float32List samples, int sampleRate, int chunkStartMs) {
    if (samples.isEmpty) {
      return;
    }
    _startMs ??= chunkStartMs;
    _endMs = chunkStartMs + (samples.length * 1000 / sampleRate).round();
    _chunks.add(samples);
    _length += samples.length;
  }

  /// Returns all buffered samples.
  Float32List allSamples() => tail(_length);

  /// Returns at most [sampleCount] samples from the end.
  Float32List tail(int sampleCount) {
    final wanted = sampleCount.clamp(0, _length);
    final result = Float32List(wanted);
    var writeAt = wanted;
    var remaining = wanted;
    for (var index = _chunks.length - 1; index >= 0 && remaining > 0; index--) {
      final chunk = _chunks[index];
      final take = remaining < chunk.length ? remaining : chunk.length;
      writeAt -= take;
      result.setRange(writeAt, writeAt + take, chunk, chunk.length - take);
      remaining -= take;
    }
    return result;
  }

  /// Removes all samples and timing information.
  void clear() {
    _chunks.clear();
    _length = 0;
    _startMs = null;
    _endMs = null;
  }
}
