import 'dart:typed_data';

import 'package:record/record.dart';

/// Root-isolate microphone operations used by `AudioCaptureService`.
///
/// The indirection keeps platform EventChannels on the root isolate and lets
/// tests exercise permission and playback transitions without a device.
abstract interface class AudioRecorderPort {
  /// Whether microphone access is currently granted.
  Future<bool> hasPermission();

  /// Platform recorder state changes.
  Stream<RecordState> onStateChanged();

  /// Starts the raw PCM stream.
  Future<Stream<Uint8List>> startStream(RecordConfig config);

  /// Pauses input.
  Future<void> pause();

  /// Resumes input.
  Future<void> resume();

  /// Stops input.
  Future<String?> stop();

  /// Releases platform resources.
  Future<void> dispose();
}

/// Production adapter around `record`.
///
/// The platform recorder is created on first use, not with the adapter: a
/// session (and its tests) can be built without touching the microphone
/// plugin, as before the port existed.
final class RecordAudioRecorderPort implements AudioRecorderPort {
  /// Creates an adapter, optionally around an existing recorder.
  RecordAudioRecorderPort([AudioRecorder? recorder]) : _created = recorder;

  AudioRecorder? _created;

  AudioRecorder get _recorder => _created ??= AudioRecorder();

  @override
  Future<void> dispose() async {
    // Nothing to release if the recorder was never used.
    await _created?.dispose();
  }

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Stream<RecordState> onStateChanged() => _recorder.onStateChanged();

  @override
  Future<void> pause() => _recorder.pause();

  @override
  Future<void> resume() => _recorder.resume();

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) =>
      _recorder.startStream(config);

  @override
  Future<String?> stop() => _recorder.stop();
}
