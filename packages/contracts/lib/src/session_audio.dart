import 'dart:async';
import 'dart:typed_data';

import 'package:contracts/src/result.dart';
import 'package:meta/meta.dart';

/// Input event produced by a reading-session audio source.
@immutable
abstract class SessionAudioEvent {
  /// Creates an audio event on the session timeline.
  const SessionAudioEvent({required this.atMs});

  /// Milliseconds from session start on the same timeline as session events.
  final int atMs;
}

/// Voice activity detection opened a speech segment.
final class SessionAudioSegmentOpened extends SessionAudioEvent {
  /// Creates a segment-open event.
  const SessionAudioSegmentOpened({
    required super.atMs,
    required this.segmentId,
  });

  /// Monotonically increasing segment number within the session.
  final int segmentId;
}

/// One frame from an open speech segment.
final class SessionAudioFrame extends SessionAudioEvent {
  /// Creates an audio-frame event.
  const SessionAudioFrame({
    required super.atMs,
    required this.segmentId,
    required this.samples,
    required this.sampleRateHz,
    required this.startMs,
    required this.endMs,
  });

  /// Segment that receives this frame.
  final int segmentId;

  /// Mono samples in the range -1..1, held in memory only.
  final Float32List samples;

  /// Samples per second.
  final int sampleRateHz;

  /// Absolute time of the first sample on the session timeline.
  final int startMs;

  /// Absolute exclusive end time on the session timeline.
  final int endMs;
}

/// No more frames will arrive for a speech segment.
final class SessionAudioSegmentClosed extends SessionAudioEvent {
  /// Creates a segment-close event.
  const SessionAudioSegmentClosed({
    required super.atMs,
    required this.segmentId,
  });

  /// Segment to pass to `SpeechRecognizer.closeSegment`.
  final int segmentId;
}

/// Supplies in-memory audio to a reading session.
///
/// Implementations may capture audio in another isolate. They must preserve a
/// single timeline across pause and resume and must never persist audio.
abstract interface class SessionAudioSource {
  /// Open segments, their frames, segment closures and `SignalQuality`.
  Stream<Result<SessionAudioEvent>> get events;

  /// Starts capture for [sessionId].
  Future<Result<void>> start(String sessionId);

  /// Pauses capture without resetting the session timeline.
  Future<Result<void>> pause();

  /// Resumes capture on the existing session timeline.
  Future<Result<void>> resume();

  /// Stops capture and closes an open segment.
  Future<Result<void>> stop();

  /// Releases capture resources.
  Future<void> dispose();
}
