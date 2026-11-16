import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_config.dart';

/// Sample boundaries for one completed speech segment.
final class SegmentBoundary {
  /// Creates segment boundaries.
  const SegmentBoundary({
    required this.audioStart,
    required this.audioEnd,
    required this.speechStart,
    required this.speechEnd,
    required this.pauseBefore,
  });

  /// Padded audio start sample.
  final int audioStart;

  /// Padded audio end sample.
  final int audioEnd;

  /// Unpadded speech start sample.
  final int speechStart;

  /// Unpadded speech end sample.
  final int speechEnd;

  /// Silence before speech in samples.
  final int pauseBefore;
}

/// Converts frame-level VAD decisions into padded, bounded segments.
final class SpeechSegmenter {
  /// Creates an empty segmenter.
  SpeechSegmenter(this._config);

  final AudioCaptureConfig _config;
  final List<_EnergyFrame> _energyFrames = <_EnergyFrame>[];
  int? _speechStart;
  int? _audioStart;
  int? _lastSpeechEnd;
  int? _previousSegmentSpeechEnd;
  var _pauseBefore = 0;

  /// Whether speech is currently being accumulated.
  bool get isOpen => _speechStart != null;

  /// Absolute first speech sample of the open segment.
  int? get speechStart => _speechStart;

  int get _preRollSamples => _msToSamples(_config.preRollMs);
  int get _postRollSamples => _msToSamples(_config.postRollMs);
  int get _endPauseSamples => _msToSamples(_config.segmentEndPauseMs);
  int get _maxSegmentSamples => _msToSamples(_config.maxSegmentMs);
  int get _quietSearchSamples => _msToSamples(_config.quietSplitWindowMs);

  /// Adds one contiguous frame and returns zero or one closed segment.
  List<SegmentBoundary> addFrame({
    required Float32List samples,
    required int frameStart,
    required bool isSpeech,
  }) {
    if (samples.isEmpty) {
      return const <SegmentBoundary>[];
    }
    final frameEnd = frameStart + samples.length;
    if (isSpeech && _speechStart == null) {
      _beginSpeech(frameStart);
    }
    if (_speechStart != null) {
      _energyFrames.add(
        _EnergyFrame(
          start: frameStart,
          end: frameEnd,
          meanSquare: _meanSquare(samples),
        ),
      );
    }
    if (isSpeech) {
      _lastSpeechEnd = frameEnd;
    }

    final speechStart = _speechStart;
    final lastSpeechEnd = _lastSpeechEnd;
    if (speechStart == null || lastSpeechEnd == null) {
      return const <SegmentBoundary>[];
    }
    if (frameEnd - speechStart >= _maxSegmentSamples) {
      final split = _quietestSplit(frameEnd);
      final boundary = _close(speechEnd: split, availableEnd: frameEnd);
      if (isSpeech) {
        _beginSpeech(split);
        _lastSpeechEnd = frameEnd;
        _energyFrames.removeWhere((frame) => frame.end <= split);
      }
      return <SegmentBoundary>[boundary];
    }
    if (!isSpeech && frameEnd - lastSpeechEnd >= _endPauseSamples) {
      return <SegmentBoundary>[
        _close(speechEnd: lastSpeechEnd, availableEnd: frameEnd),
      ];
    }
    return const <SegmentBoundary>[];
  }

  /// Closes an open segment at end-of-file or capture stop.
  SegmentBoundary? flush(int availableEnd) {
    final lastSpeechEnd = _lastSpeechEnd;
    if (_speechStart == null || lastSpeechEnd == null) {
      reset();
      return null;
    }
    return _close(speechEnd: lastSpeechEnd, availableEnd: availableEnd);
  }

  /// Drops all segment state without emitting audio.
  void reset() {
    _speechStart = null;
    _audioStart = null;
    _lastSpeechEnd = null;
    _previousSegmentSpeechEnd = null;
    _pauseBefore = 0;
    _energyFrames.clear();
  }

  void _beginSpeech(int start) {
    _speechStart = start;
    _audioStart = start > _preRollSamples ? start - _preRollSamples : 0;
    final previousEnd = _previousSegmentSpeechEnd;
    _pauseBefore =
        previousEnd == null || start <= previousEnd ? 0 : start - previousEnd;
    _energyFrames.clear();
  }

  SegmentBoundary _close({required int speechEnd, required int availableEnd}) {
    final speechStart = _speechStart;
    final audioStart = _audioStart;
    if (speechStart == null || audioStart == null) {
      throw StateError('No speech segment is open.');
    }
    final desiredEnd = speechEnd + _postRollSamples;
    final boundary = SegmentBoundary(
      audioStart: audioStart,
      audioEnd: desiredEnd < availableEnd ? desiredEnd : availableEnd,
      speechStart: speechStart,
      speechEnd: speechEnd,
      pauseBefore: _pauseBefore,
    );
    _previousSegmentSpeechEnd = speechEnd;
    _speechStart = null;
    _audioStart = null;
    _lastSpeechEnd = null;
    _pauseBefore = 0;
    _energyFrames.clear();
    return boundary;
  }

  int _quietestSplit(int availableEnd) {
    final latestAllowed = availableEnd - _postRollSamples;
    final earliest = availableEnd - _quietSearchSamples;
    _EnergyFrame? quietest;
    for (final frame in _energyFrames) {
      if (frame.start < earliest || frame.end > latestAllowed) {
        continue;
      }
      final current = quietest;
      if (current == null || frame.meanSquare < current.meanSquare) {
        quietest = frame;
      }
    }
    final selected = quietest;
    if (selected != null) {
      return selected.start + (selected.end - selected.start) ~/ 2;
    }
    return latestAllowed;
  }

  int _msToSamples(int milliseconds) =>
      _config.sampleRate * milliseconds ~/ 1000;

  double _meanSquare(Float32List samples) {
    var sum = 0.0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    return sum / samples.length;
  }
}

final class _EnergyFrame {
  const _EnergyFrame({
    required this.start,
    required this.end,
    required this.meanSquare,
  });

  final int start;
  final int end;
  final double meanSquare;
}
