import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_config.dart';
import 'package:audio_capture/src/audio_capture_event.dart';
import 'package:audio_capture/src/audio_capture_exception.dart';
import 'package:audio_capture/src/audio_event_codec.dart';
import 'package:audio_capture/src/audio_snippet.dart';
import 'package:audio_capture/src/audio_worker.dart';
import 'package:contracts/contracts.dart';
import 'package:record/record.dart';

enum _InputMode { none, microphone, file }

/// Microphone and real-time WAV input that forwards PCM to a worker isolate.
final class AudioCaptureService {
  /// Creates an idle audio service.
  AudioCaptureService({
    AudioCaptureConfig config = const AudioCaptureConfig(),
    AudioRecorder? recorder,
  })  : _config = config,
        _recorder = recorder;

  final AudioCaptureConfig _config;
  AudioRecorder? _recorder;
  final StreamController<Result<AudioCaptureEvent>> _events =
      StreamController<Result<AudioCaptureEvent>>.broadcast();
  final Map<int, Completer<Map<String, Object?>>> _pending =
      <int, Completer<Map<String, Object?>>>{};
  final Completer<SendPort> _workerReady = Completer<SendPort>();

  ReceivePort? _responses;
  ReceivePort? _workerErrors;
  ReceivePort? _workerExit;
  StreamSubscription<Object?>? _responseSubscription;
  StreamSubscription<Object?>? _errorSubscription;
  StreamSubscription<Object?>? _exitSubscription;
  StreamSubscription<Uint8List>? _recordSubscription;
  StreamSubscription<RecordState>? _recordStateSubscription;
  Isolate? _isolate;
  SendPort? _workerPort;
  _InputMode _mode = _InputMode.none;
  String? _vadModelPath;
  var _nextRequestId = 1;
  var _disposed = false;
  var _expectedRecorderPause = false;
  var _playbackActive = false;

  /// Segments, quality changes, pauses, and explicit operation errors.
  Stream<Result<AudioCaptureEvent>> get events => _events.stream;

  AudioRecorder get _activeRecorder => _recorder ??= AudioRecorder();

  /// Starts PCM16, 16 kHz, mono microphone capture.
  ///
  /// The UI must display its localized permission rationale before setting
  /// [permissionExplanationShown] to true.
  Future<Result<void>> startMicrophone({
    required String vadModelPath,
    required bool permissionExplanationShown,
  }) async {
    if (_disposed) {
      return _failure('disposed', 'The audio service is disposed.');
    }
    if (_mode != _InputMode.none) {
      return _failure('alreadyCapturing', 'Audio capture is already active.');
    }
    if (!permissionExplanationShown) {
      return _failure(
        'permissionExplanationRequired',
        'Explain microphone use before requesting permission.',
      );
    }
    try {
      if (!await _activeRecorder.hasPermission()) {
        return _failure(
          'micDenied',
          'Microphone permission was denied; use self-check mode.',
        );
      }
      final loaded = await _ensureWorker(vadModelPath);
      if (loaded case Error<void>()) {
        return loaded;
      }
      _mode = _InputMode.microphone;
      await _startRecorderStream();
      return const Result<void>.ok(null);
    } on Object {
      await _stopRecorder();
      _mode = _InputMode.none;
      return _failure(
        'microphoneStartFailed',
        'Microphone capture could not start.',
      );
    }
  }

  /// Feeds a mono PCM16 16 kHz WAV through the same pipeline in real time.
  Future<Result<void>> startFile({
    required String vadModelPath,
    required String wavPath,
  }) async {
    if (_disposed) {
      return _failure('disposed', 'The audio service is disposed.');
    }
    if (_mode != _InputMode.none) {
      return _failure('alreadyCapturing', 'Audio capture is already active.');
    }
    final loaded = await _ensureWorker(vadModelPath);
    if (loaded case Error<void>()) {
      return loaded;
    }
    final response = await _sendAndWait(
      'startFile',
      <String, Object?>{'path': wavPath},
    );
    final error = _responseError(response);
    if (error != null) {
      return Result.error(error);
    }
    _mode = _InputMode.file;
    return const Result<void>.ok(null);
  }

  /// Returns a padded fragment from the in-memory ring only.
  Future<Result<AudioSnippet>> requestSnippet({
    required int startMs,
    required int endMs,
  }) async {
    if (_workerPort == null) {
      return _snippetFailure('notCapturing', 'No audio pipeline is active.');
    }
    final response = await _sendAndWait(
      'snippet',
      <String, Object?>{'startMs': startMs, 'endMs': endMs},
    );
    final error = _responseError(response);
    if (error != null) {
      return Result.error(error);
    }
    final value = response['value'];
    if (value is! Map<String, Object?>) {
      return _snippetFailure(
        'workerProtocol',
        'The worker returned an invalid snippet.',
      );
    }
    try {
      final transfer = _required<TransferableTypedData>(value, 'samples');
      final bytes = transfer.materialize().asUint8List();
      return Result.ok(
        AudioSnippet(
          samples: Float32List.view(
            bytes.buffer,
            bytes.offsetInBytes,
            bytes.lengthInBytes ~/ 4,
          ),
          sampleRate: _required<int>(value, 'sampleRate'),
          startMs: _required<int>(value, 'startMs'),
          endMs: _required<int>(value, 'endMs'),
        ),
      );
    } on FormatException {
      return _snippetFailure(
        'workerProtocol',
        'The worker returned an invalid snippet.',
      );
    }
  }

  /// Pauses capture after a system lifecycle or permission event.
  Future<Result<void>> notifyInterruption(
    CapturePauseReason reason, {
    bool bluetoothInput = false,
  }) async {
    if (_workerPort == null) {
      return _failure('notCapturing', 'No audio pipeline is active.');
    }
    if (_mode == _InputMode.microphone &&
        reason != CapturePauseReason.permissionRevoked) {
      _expectedRecorderPause = true;
      try {
        await _activeRecorder.pause();
      } on Object {
        // The worker still transitions to paused with an explicit reason.
      }
    }
    if (_mode == _InputMode.microphone &&
        reason == CapturePauseReason.permissionRevoked) {
      await _stopRecorder();
    }
    final response = await _sendAndWait(
      'pause',
      <String, Object?>{
        'reason': reason.name,
        'bluetoothInput': bluetoothInput,
      },
    );
    final result = _voidResult(response);
    if (reason == CapturePauseReason.permissionRevoked && result is Ok<void>) {
      return _failure(
        'micDenied',
        'Microphone permission was revoked; use self-check mode.',
      );
    }
    return result;
  }

  /// Restarts the default microphone after an input-device change.
  Future<Result<void>> handleAudioDeviceChanged({
    required bool bluetoothInput,
  }) async {
    if (_mode != _InputMode.microphone) {
      return _failure('notMicrophone', 'Microphone capture is not active.');
    }
    final paused = await notifyInterruption(
      CapturePauseReason.deviceChanged,
      bluetoothInput: bluetoothInput,
    );
    if (paused case Error<void>()) {
      return paused;
    }
    try {
      await _stopRecorder();
      _mode = _InputMode.microphone;
      await _startRecorderStream();
      return const Result<void>.ok(null);
    } on Object {
      return _failure(
        'deviceRestartFailed',
        'Recording could not restart on the new device.',
      );
    }
  }

  /// Resumes microphone capture after a call or foreground transition.
  Future<Result<void>> resumeMicrophone() async {
    if (_mode != _InputMode.microphone) {
      return _failure('notMicrophone', 'Microphone capture is not active.');
    }
    try {
      if (!await _activeRecorder.hasPermission()) {
        return await notifyInterruption(
          CapturePauseReason.permissionRevoked,
        );
      }
      _expectedRecorderPause = true;
      await _activeRecorder.resume();
      return const Result<void>.ok(null);
    } on Object {
      return _failure(
        'microphoneResumeFailed',
        'Microphone capture could not resume.',
      );
    }
  }

  /// Prevents capturing a reciter played by the app.
  Future<Result<void>> setPlaybackActive(bool active) async {
    if (_workerPort == null) {
      _playbackActive = active;
      return const Result<void>.ok(null);
    }
    _playbackActive = active;
    if (_mode == _InputMode.microphone) {
      try {
        _expectedRecorderPause = true;
        if (active) {
          await _activeRecorder.pause();
        } else if (await _activeRecorder.hasPermission()) {
          await _activeRecorder.resume();
        }
      } on Object {
        return _failure(
          'playbackTransitionFailed',
          'Capture could not follow playback state.',
        );
      }
    }
    return _voidResult(
      await _sendAndWait('playback', <String, Object?>{'active': active}),
    );
  }

  /// Stops input, emits the last segment, and zeros retained audio.
  Future<Result<void>> stop() async {
    if (_workerPort == null) {
      _mode = _InputMode.none;
      return const Result<void>.ok(null);
    }
    if (_mode == _InputMode.microphone) {
      await _stopRecorder();
    }
    _mode = _InputMode.none;
    return _voidResult(
      await _sendAndWait('stop', const <String, Object?>{}),
    );
  }

  /// Releases the microphone, worker isolate, ports, and in-memory audio.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await stop();
    _disposed = true;
    final worker = _workerPort;
    if (worker != null) {
      try {
        await _sendAndWait('dispose', const <String, Object?>{}).timeout(
          const Duration(seconds: 3),
        );
      } on Object {
        // The isolate is killed below if it cannot acknowledge disposal.
      }
    }
    await _recordStateSubscription?.cancel();
    await _recorder?.dispose();
    _isolate?.kill(priority: Isolate.immediate);
    await _responseSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _exitSubscription?.cancel();
    _responses?.close();
    _workerErrors?.close();
    _workerExit?.close();
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.complete(
          _failedResponse('disposed', 'The audio service was disposed.'),
        );
      }
    }
    _pending.clear();
    await _events.close();
  }

  Future<Result<void>> _ensureWorker(String vadModelPath) async {
    final existingPath = _vadModelPath;
    if (_workerPort != null) {
      return existingPath == vadModelPath
          ? const Result<void>.ok(null)
          : _failure(
              'vadModelChanged',
              'Dispose before changing the VAD model.',
            );
    }
    try {
      final responses = ReceivePort();
      final errors = ReceivePort();
      final exit = ReceivePort();
      _responses = responses;
      _workerErrors = errors;
      _workerExit = exit;
      _responseSubscription = responses.listen(_handleWorkerMessage);
      _errorSubscription = errors.listen(_handleWorkerFailure);
      _exitSubscription = exit.listen(_handleWorkerExit);
      _isolate = await Isolate.spawn<SendPort>(
        runAudioWorker,
        responses.sendPort,
        onError: errors.sendPort,
        onExit: exit.sendPort,
        debugName: 'sudur-audio-capture',
      );
      _workerPort =
          await _workerReady.future.timeout(const Duration(seconds: 5));
      final response = await _sendAndWait(
        'load',
        <String, Object?>{
          'vadModelPath': vadModelPath,
          'config': _config.toMessage(),
        },
      );
      final result = _voidResult(response);
      if (result case Ok<void>()) {
        _vadModelPath = vadModelPath;
      }
      return result;
    } on Object {
      return _failure(
        'workerStartFailed',
        'The audio worker isolate could not start.',
      );
    }
  }

  Future<void> _startRecorderStream() async {
    await _recordStateSubscription?.cancel();
    _recordStateSubscription = _activeRecorder.onStateChanged().listen(
          _handleRecordState,
          onError: _handleRecordError,
        );
    final stream = await _activeRecorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _config.sampleRate,
        numChannels: 1,
        streamBufferSize: _config.streamBufferBytes,
      ),
    );
    await _recordSubscription?.cancel();
    _recordSubscription = stream.listen(
      _forwardPcm,
      onError: _handleRecordError,
    );
  }

  void _forwardPcm(Uint8List pcm16) {
    final worker = _workerPort;
    if (worker == null || _playbackActive) {
      return;
    }
    final requestId = _nextRequestId++;
    worker.send(<String, Object?>{
      'requestId': requestId,
      'operation': 'audio',
      'pcm16': TransferableTypedData.fromList(<TypedData>[pcm16]),
    });
  }

  void _handleRecordState(RecordState state) {
    if (state == RecordState.pause) {
      if (_expectedRecorderPause) {
        _expectedRecorderPause = false;
        return;
      }
      unawaited(notifyInterruption(CapturePauseReason.interrupted));
      return;
    }
    _expectedRecorderPause = false;
  }

  void _handleRecordError(Object _) {
    if (_mode == _InputMode.microphone) {
      unawaited(notifyInterruption(CapturePauseReason.interrupted));
    }
  }

  Future<void> _stopRecorder() async {
    _expectedRecorderPause = true;
    try {
      await _activeRecorder.stop();
    } on Object {
      // The stream subscription is still cancelled and worker state is reset.
    }
    await _recordSubscription?.cancel();
    _recordSubscription = null;
  }

  Future<Map<String, Object?>> _sendAndWait(
    String operation,
    Map<String, Object?> fields,
  ) {
    final worker = _workerPort;
    if (worker == null) {
      return Future<Map<String, Object?>>.value(
        _failedResponse(
          'workerUnavailable',
          'The audio worker is unavailable.',
        ),
      );
    }
    final requestId = _nextRequestId++;
    final completer = Completer<Map<String, Object?>>();
    _pending[requestId] = completer;
    worker.send(<String, Object?>{
      'requestId': requestId,
      'operation': operation,
      ...fields,
    });
    return completer.future;
  }

  void _handleWorkerMessage(Object? message) {
    if (message is SendPort) {
      if (!_workerReady.isCompleted) {
        _workerReady.complete(message);
      }
      return;
    }
    if (message is! Map<String, Object?>) {
      return;
    }
    if (message['type'] == 'event') {
      try {
        _events.add(Result.ok(audioEventFromMessage(message)));
      } on FormatException {
        _events.add(
          const Result.error(
            AudioCaptureException(
              'workerProtocol',
              'The worker returned an invalid event.',
            ),
          ),
        );
      }
      return;
    }
    final requestId = message['requestId'];
    if (requestId is! int) {
      return;
    }
    final pending = _pending.remove(requestId);
    if (pending != null) {
      pending.complete(message);
      return;
    }
    final error = _responseError(message);
    if (error != null) {
      _events.add(Result.error(error));
    }
  }

  void _handleWorkerFailure(Object? _) {
    _completeAfterWorkerFailure();
  }

  void _handleWorkerExit(Object? _) {
    if (!_disposed) {
      _completeAfterWorkerFailure();
    }
  }

  void _completeAfterWorkerFailure() {
    final response = _failedResponse(
      'workerStopped',
      'The audio worker isolate stopped unexpectedly.',
    );
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    }
    _pending.clear();
    if (!_events.isClosed) {
      _events.add(
        const Result.error(
          AudioCaptureException(
            'workerStopped',
            'The audio worker isolate stopped unexpectedly.',
          ),
        ),
      );
    }
  }

  Result<void> _voidResult(Map<String, Object?> response) {
    final error = _responseError(response);
    return error == null ? const Result<void>.ok(null) : Result.error(error);
  }

  AudioCaptureException? _responseError(Map<String, Object?> response) {
    if (response['ok'] == true) {
      return null;
    }
    final errorCode = response['errorCode'];
    final errorMessage = response['errorMessage'];
    return AudioCaptureException(
      errorCode is String ? errorCode : 'audioError',
      errorMessage is String ? errorMessage : 'The audio operation failed.',
    );
  }

  Result<void> _failure(String code, String message) =>
      Result.error(AudioCaptureException(code, message));

  Result<AudioSnippet> _snippetFailure(String code, String message) =>
      Result.error(AudioCaptureException(code, message));

  Map<String, Object?> _failedResponse(String code, String message) =>
      <String, Object?>{
        'ok': false,
        'errorCode': code,
        'errorMessage': message,
      };
}

T _required<T>(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! T) {
    throw FormatException('$key has an invalid type.');
  }
  return field;
}
