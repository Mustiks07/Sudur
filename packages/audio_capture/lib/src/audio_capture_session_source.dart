import 'dart:async';

import 'package:audio_capture/src/audio_capture_event.dart' as capture;
import 'package:audio_capture/src/audio_capture_service.dart';
import 'package:contracts/contracts.dart';

/// Adapts [AudioCaptureService] to the session-facing contract from ADR 0005.
final class AudioCaptureSessionSource implements SessionAudioSource {
  /// Creates a microphone source configured with an installed VAD model.
  AudioCaptureSessionSource({
    required AudioCaptureService capture,
    required String vadModelPath,
    required bool permissionExplanationShown,
    Future<void> Function(capture.CapturePaused event)? onAutomaticPause,
  })  : _capture = capture,
        _vadModelPath = vadModelPath,
        _permissionExplanationShown = permissionExplanationShown,
        _onAutomaticPause = onAutomaticPause;

  final AudioCaptureService _capture;
  final String _vadModelPath;
  final bool _permissionExplanationShown;
  final Future<void> Function(capture.CapturePaused event)? _onAutomaticPause;
  final StreamController<Result<SessionAudioEvent>> _events =
      StreamController<Result<SessionAudioEvent>>.broadcast(sync: true);
  final StreamController<capture.CapturePaused> _interruptions =
      StreamController<capture.CapturePaused>.broadcast(sync: true);
  final AudioCaptureSessionEventMapper _mapper =
      AudioCaptureSessionEventMapper();

  StreamSubscription<Result<Object>>? _subscription;
  String? _sessionId;
  var _disposed = false;
  var _systemPaused = false;
  var _pauseRequested = false;

  @override
  Stream<Result<SessionAudioEvent>> get events => _events.stream;

  /// System pause reasons for the screen/session coordinator.
  ///
  /// `onAutomaticPause` should execute the session `Pause` command so the
  /// session changes to `paused` and saves its checkpoint. Calling [pause]
  /// afterwards is idempotent because capture has already stopped.
  Stream<capture.CapturePaused> get interruptions => _interruptions.stream;

  @override
  Future<Result<void>> start(String sessionId) async {
    if (_disposed) {
      return const Result<void>.error(
        AudioCaptureSessionSourceException(
          'disposed',
          'The audio session source is disposed.',
        ),
      );
    }
    if (_sessionId != null) {
      return const Result<void>.error(
        AudioCaptureSessionSourceException(
          'alreadyStarted',
          'The audio session source is already started.',
        ),
      );
    }
    _sessionId = sessionId;
    _subscription = _capture.events.listen(_forward);
    final result = await _capture.startMicrophone(
      vadModelPath: _vadModelPath,
      permissionExplanationShown: _permissionExplanationShown,
    );
    if (result case Error<void>()) {
      await _subscription?.cancel();
      _subscription = null;
      _sessionId = null;
    }
    return result;
  }

  void _forward(Result<Object> result) {
    switch (result) {
      case Error<Object>(:final error):
        _events.add(Result<SessionAudioEvent>.error(error));
      case Ok<Object>(:final value):
        if (value case final capture.CapturePaused paused
            when paused.reason != capture.CapturePauseReason.playback &&
                !_pauseRequested) {
          _systemPaused = true;
          _interruptions.add(paused);
          final callback = _onAutomaticPause;
          if (callback != null) {
            unawaited(_notifyAutomaticPause(callback, paused));
          }
        }
        final mapped = _map(value);
        if (mapped != null) _events.add(Result.ok(mapped));
    }
  }

  SessionAudioEvent? _map(Object event) =>
      _sessionId == null ? null : _mapper.map(event);

  @override
  Future<Result<void>> pause() async {
    if (_systemPaused) {
      return const Result<void>.ok(null);
    }
    _pauseRequested = true;
    try {
      return await _capture.notifyInterruption(
        capture.CapturePauseReason.background,
      );
    } finally {
      _pauseRequested = false;
    }
  }

  @override
  Future<Result<void>> resume() async {
    final result = await _capture.resumeMicrophone();
    if (result is Ok<void>) _systemPaused = false;
    return result;
  }

  /// Suppresses microphone/recognition input while reciter playback is on.
  Future<Result<void>> setPlaybackActive(bool active) =>
      _capture.setPlaybackActive(active);

  Future<void> _notifyAutomaticPause(
    Future<void> Function(capture.CapturePaused event) callback,
    capture.CapturePaused event,
  ) async {
    try {
      await callback(event);
    } on Object {
      if (!_events.isClosed) {
        _events.add(
          const Result<SessionAudioEvent>.error(
            AudioCaptureSessionSourceException(
              'automaticPauseFailed',
              'The session coordinator could not apply an automatic pause.',
            ),
          ),
        );
      }
    }
  }

  @override
  Future<Result<void>> stop() => _capture.stop();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _subscription?.cancel();
    await _capture.dispose();
    await _interruptions.close();
    await _events.close();
  }
}

/// Stateful event mapper used by the adapter and its unit tests.
final class AudioCaptureSessionEventMapper {
  int? _previousSpeechEndMs;

  /// Converts one capture event; internal-only events return `null`.
  SessionAudioEvent? map(Object event) => switch (event) {
        capture.SpeechSegmentOpened() => SessionAudioSegmentOpened(
            atMs: event.atMs,
            segmentId: event.segmentId,
            pauseBeforeMs: _pauseBefore(event.atMs),
          ),
        capture.SpeechSegmentAudioFrame() => SessionAudioFrame(
            atMs: event.atMs,
            segmentId: event.segmentId,
            samples: event.samples,
            sampleRateHz: event.sampleRate,
            startMs: event.startMs,
            endMs: event.endMs,
          ),
        capture.SpeechSegmentClosed() => SessionAudioSegmentClosed(
            atMs: event.atMs,
            segmentId: event.segmentId,
          ),
        SignalQuality() => event,
        capture.SpeechSegmentReady() => _rememberSpeechEnd(event),
        capture.CapturePaused() || capture.FileInputFinished() => null,
        _ => null,
      };

  int _pauseBefore(int speechStartMs) {
    final previousEnd = _previousSpeechEndMs;
    if (previousEnd == null || speechStartMs <= previousEnd) return 0;
    return speechStartMs - previousEnd;
  }

  SessionAudioEvent? _rememberSpeechEnd(capture.SpeechSegmentReady event) {
    _previousSpeechEndMs = event.speechEndMs;
    return null;
  }
}

/// Configuration or lifecycle error in [AudioCaptureSessionSource].
final class AudioCaptureSessionSourceException implements Exception {
  /// Creates an adapter error.
  const AudioCaptureSessionSourceException(this.code, this.message);

  /// Stable machine-readable code.
  final String code;

  /// Message without audio or recognized text.
  final String message;

  @override
  String toString() => 'AudioCaptureSessionSourceException($code): $message';
}
