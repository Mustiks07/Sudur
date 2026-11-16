import 'dart:typed_data';

/// An explicitly requested in-memory audio fragment.
final class AudioSnippet {
  /// Creates an audio fragment.
  const AudioSnippet({
    required this.samples,
    required this.sampleRate,
    required this.startMs,
    required this.endMs,
  });

  /// Mono Float32 samples. The caller must release its reference after review.
  final Float32List samples;

  /// Samples per second.
  final int sampleRate;

  /// Actual fragment start in session time.
  final int startMs;

  /// Actual fragment end in session time.
  final int endMs;
}
