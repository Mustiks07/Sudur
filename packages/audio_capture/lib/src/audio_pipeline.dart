import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_config.dart';
import 'package:audio_capture/src/audio_capture_exception.dart';
import 'package:audio_capture/src/float_ring_buffer.dart';
import 'package:audio_capture/src/signal_quality_estimator.dart';
import 'package:audio_capture/src/speech_segmenter.dart';

/// One completed segment copied from the in-memory ring.
final class ProcessedSegment {
  /// Creates a processed segment.
  const ProcessedSegment({required this.boundary, required this.samples});

  /// Padded and unpadded sample positions.
  final SegmentBoundary boundary;

  /// Padded audio samples.
  final Float32List samples;
}

/// Results produced for one fixed-size frame.
final class AudioPipelineOutput {
  /// Creates frame output.
  const AudioPipelineOutput({
    required this.segments,
    required this.qualityReadings,
  });

  /// Newly closed segments.
  final List<ProcessedSegment> segments;

  /// Newly completed signal windows.
  final List<SignalQualityReading> qualityReadings;
}

/// Pure in-memory audio processing after VAD classification.
final class AudioPipeline {
  /// Creates an empty pipeline.
  AudioPipeline(this.config)
      : _ring = FloatRingBuffer(config.sampleRate * config.ringBufferSec),
        _segmenter = SpeechSegmenter(config),
        _quality = SignalQualityEstimator(config);

  /// Pipeline parameters.
  final AudioCaptureConfig config;
  final FloatRingBuffer _ring;
  final SpeechSegmenter _segmenter;
  final SignalQualityEstimator _quality;

  /// Current session time in samples.
  int get currentSample => _ring.totalSamples;

  /// Processes a fixed-size frame already classified by VAD.
  AudioPipelineOutput processFrame(
    Float32List samples, {
    required bool isSpeech,
  }) {
    final frameStart = _ring.totalSamples;
    _ring.push(samples);
    final boundaries = _segmenter.addFrame(
      samples: samples,
      frameStart: frameStart,
      isSpeech: isSpeech,
    );
    return AudioPipelineOutput(
      segments: boundaries.map(_copySegment).toList(growable: false),
      qualityReadings: _quality.add(samples, isSpeech: isSpeech),
    );
  }

  /// Flushes the open segment at capture end.
  ProcessedSegment? flush() {
    final boundary = _segmenter.flush(_ring.totalSamples);
    return boundary == null ? null : _copySegment(boundary);
  }

  /// Copies a padded review fragment from the ring.
  Float32List snippet(int startMs, int endMs, {int? paddingMs}) {
    if (startMs < 0 || endMs <= startMs) {
      throw const AudioCaptureException(
        'invalidSnippetRange',
        'Snippet times must form a positive range.',
      );
    }
    final padding = paddingMs ?? config.reviewSnippetPadMs;
    final paddedStartMs = startMs > padding ? startMs - padding : 0;
    final paddedEndMs = endMs + padding;
    return _ring.read(
      paddedStartMs * config.sampleRate ~/ 1000,
      paddedEndMs * config.sampleRate ~/ 1000,
    );
  }

  /// Zeros retained audio and resets segment state.
  void clear() {
    _ring.clear();
    _segmenter.reset();
    _quality.reset();
  }

  ProcessedSegment _copySegment(SegmentBoundary boundary) => ProcessedSegment(
        boundary: boundary,
        samples: _ring.read(boundary.audioStart, boundary.audioEnd),
      );
}
