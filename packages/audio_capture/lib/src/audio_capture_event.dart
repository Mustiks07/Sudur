import 'dart:typed_data';

/// Signal condition measured over the configured quality window.
enum SignalQualityLevel {
  /// Signal can be checked.
  ok,

  /// Speech stayed below the configured level.
  tooQuiet,

  /// Too many samples reached the PCM limit.
  clipping,

  /// Non-speech level stayed above the configured limit.
  noisy,
}

/// Why capture was paused.
enum CapturePauseReason {
  /// A call or another application interrupted the recorder.
  interrupted,

  /// The application entered the background.
  background,

  /// The active input device changed.
  deviceChanged,

  /// Microphone permission was revoked.
  permissionRevoked,

  /// Playback is active, so learner audio must not be captured.
  playback,
}

/// Event produced by the audio worker isolate.
sealed class AudioCaptureEvent {
  /// Creates an audio event at session time [atMs].
  const AudioCaptureEvent({required this.atMs});

  /// Milliseconds since capture started.
  final int atMs;
}

/// VAD opened a segment that can now be streamed to the recognizer.
final class SpeechSegmentOpened extends AudioCaptureEvent {
  /// Creates an open-segment event.
  const SpeechSegmentOpened({
    required super.atMs,
    required this.segmentId,
  });

  /// Monotonically increasing segment number.
  final int segmentId;
}

/// One in-memory Float32 frame belonging to an open speech segment.
final class SpeechSegmentAudioFrame extends AudioCaptureEvent {
  /// Creates an open-segment audio frame.
  const SpeechSegmentAudioFrame({
    required super.atMs,
    required this.segmentId,
    required this.samples,
    required this.sampleRate,
    required this.startMs,
    required this.endMs,
  });

  /// Segment that receives this frame.
  final int segmentId;

  /// Mono Float32 samples, transferred from the worker isolate.
  final Float32List samples;

  /// Samples per second.
  final int sampleRate;

  /// Absolute first sample time on the session timeline.
  final int startMs;

  /// Absolute exclusive end time on the session timeline.
  final int endMs;
}

/// No more audio frames will arrive for this segment.
final class SpeechSegmentClosed extends AudioCaptureEvent {
  /// Creates a close-segment event.
  const SpeechSegmentClosed({
    required super.atMs,
    required this.segmentId,
  });

  /// Segment to pass to `SpeechRecognizer.closeSegment`.
  final int segmentId;
}

/// A complete in-memory speech segment with padding and pause duration.
final class SpeechSegmentReady extends AudioCaptureEvent {
  /// Creates a segment event.
  const SpeechSegmentReady({
    required super.atMs,
    required this.segmentId,
    required this.samples,
    required this.sampleRate,
    required this.audioStartMs,
    required this.audioEndMs,
    required this.speechStartMs,
    required this.speechEndMs,
    required this.pauseBeforeMs,
  });

  /// Monotonically increasing segment number.
  final int segmentId;

  /// Padded mono Float32 audio, retained in memory only.
  final Float32List samples;

  /// Samples per second.
  final int sampleRate;

  /// Padded audio start.
  final int audioStartMs;

  /// Padded audio end.
  final int audioEndMs;

  /// VAD speech start before padding.
  final int speechStartMs;

  /// VAD speech end before padding.
  final int speechEndMs;

  /// Silence since the previous segment's unpadded speech end.
  final int pauseBeforeMs;
}

/// A signal-quality measurement.
final class SignalQualityChanged extends AudioCaptureEvent {
  /// Creates a quality event.
  const SignalQualityChanged({
    required super.atMs,
    required this.level,
    required this.dbfs,
    required this.clippedRatio,
  });

  /// Classified quality.
  final SignalQualityLevel level;

  /// RMS level for the full quality window.
  final double dbfs;

  /// Fraction of saturated samples.
  final double clippedRatio;
}

/// Capture paused because of a system or playback event.
final class CapturePaused extends AudioCaptureEvent {
  /// Creates a pause event.
  const CapturePaused({
    required super.atMs,
    required this.reason,
    this.bluetoothInput = false,
  });

  /// Pause reason.
  final CapturePauseReason reason;

  /// Whether a newly selected input is Bluetooth and may reduce quality.
  final bool bluetoothInput;
}

/// Real-time file input reached its end.
final class FileInputFinished extends AudioCaptureEvent {
  /// Creates a file completion event.
  const FileInputFinished({required super.atMs});
}
