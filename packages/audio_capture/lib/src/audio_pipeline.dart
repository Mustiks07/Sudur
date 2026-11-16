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
    required this.frameStart,
    required this.frameEnd,
    required this.wasSegmentOpen,
    required this.isSegmentOpen,
    required this.openedAtSample,
    required this.reopenedSamples,
  });

  /// Newly closed segments.
  final List<ProcessedSegment> segments;

  /// Newly completed signal windows.
  final List<SignalQualityReading> qualityReadings;

  /// Absolute first sample in the input frame.
  final int frameStart;

  /// Absolute exclusive end sample in the input frame.
  final int frameEnd;

  /// Whether a speech segment was open before this frame.
  final bool wasSegmentOpen;

  /// Whether a speech segment remains open after this frame.
  final bool isSegmentOpen;

  /// Start of a segment opened by this frame, including a forced split.
  final int? openedAtSample;

  /// Audio replayed into the new segment after a forced split.
  final Float32List? reopenedSamples;
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
    final wasSegmentOpen = _segmenter.isOpen;
    _ring.push(samples);
    final boundaries = _segmenter.addFrame(
      samples: samples,
      frameStart: frameStart,
      isSpeech: isSpeech,
    );
    final isSegmentOpen = _segmenter.isOpen;
    final openedAtSample = !wasSegmentOpen && isSegmentOpen ||
            boundaries.isNotEmpty && isSegmentOpen
        ? _segmenter.speechStart
        : null;
    final reopenedSamples = boundaries.isNotEmpty && isSegmentOpen
        ? _ring.read(openedAtSample ?? frameStart, _ring.totalSamples)
        : null;
    return AudioPipelineOutput(
      segments: boundaries.map(_copySegment).toList(growable: false),
      qualityReadings: _quality.add(samples, isSpeech: isSpeech),
      frameStart: frameStart,
      frameEnd: _ring.totalSamples,
      wasSegmentOpen: wasSegmentOpen,
      isSegmentOpen: isSegmentOpen,
      openedAtSample: openedAtSample,
      reopenedSamples: reopenedSamples,
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

  /// Zeros retained audio and resets state, optionally keeping session time.
  void clear({bool preserveTimeline = false}) {
    _ring.clear(preservePosition: preserveTimeline);
    _segmenter.reset();
    _quality.reset();
  }

  ProcessedSegment _copySegment(SegmentBoundary boundary) => ProcessedSegment(
        boundary: boundary,
        samples: _ring.read(boundary.audioStart, boundary.audioEnd),
      );
}
