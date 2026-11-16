import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_event.dart';

/// Decodes one validated worker event and materializes transferred audio.
AudioCaptureEvent audioEventFromMessage(Map<String, Object?> value) {
  final kind = _required<String>(value, 'kind');
  final atMs = _required<int>(value, 'atMs');
  switch (kind) {
    case 'segmentOpened':
      return SpeechSegmentOpened(
        atMs: atMs,
        segmentId: _required<int>(value, 'segmentId'),
      );
    case 'segmentAudio':
      final transfer = _required<TransferableTypedData>(value, 'samples');
      final bytes = transfer.materialize().asUint8List();
      return SpeechSegmentAudioFrame(
        atMs: atMs,
        segmentId: _required<int>(value, 'segmentId'),
        samples: Float32List.view(
          bytes.buffer,
          bytes.offsetInBytes,
          bytes.lengthInBytes ~/ 4,
        ),
        sampleRate: _required<int>(value, 'sampleRate'),
        startMs: _required<int>(value, 'startMs'),
        endMs: _required<int>(value, 'endMs'),
      );
    case 'segmentClosed':
      return SpeechSegmentClosed(
        atMs: atMs,
        segmentId: _required<int>(value, 'segmentId'),
      );
    case 'segment':
      final transfer = _required<TransferableTypedData>(value, 'samples');
      final bytes = transfer.materialize().asUint8List();
      return SpeechSegmentReady(
        atMs: atMs,
        segmentId: _required<int>(value, 'segmentId'),
        samples: Float32List.view(
          bytes.buffer,
          bytes.offsetInBytes,
          bytes.lengthInBytes ~/ 4,
        ),
        sampleRate: _required<int>(value, 'sampleRate'),
        audioStartMs: _required<int>(value, 'audioStartMs'),
        audioEndMs: _required<int>(value, 'audioEndMs'),
        speechStartMs: _required<int>(value, 'speechStartMs'),
        speechEndMs: _required<int>(value, 'speechEndMs'),
        pauseBeforeMs: _required<int>(value, 'pauseBeforeMs'),
      );
    case 'quality':
      return SignalQualityChanged(
        atMs: atMs,
        level: SignalQualityLevel.values.byName(
          _required<String>(value, 'level'),
        ),
        dbfs: _required<num>(value, 'dbfs').toDouble(),
        clippedRatio: _required<num>(value, 'clippedRatio').toDouble(),
      );
    case 'paused':
      return CapturePaused(
        atMs: atMs,
        reason: CapturePauseReason.values.byName(
          _required<String>(value, 'reason'),
        ),
        bluetoothInput: _required<bool>(value, 'bluetoothInput'),
      );
    case 'fileFinished':
      return FileInputFinished(atMs: atMs);
    default:
      throw FormatException('Unknown worker event $kind.');
  }
}

T _required<T>(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! T) {
    throw FormatException('$key has an invalid type.');
  }
  return field;
}
