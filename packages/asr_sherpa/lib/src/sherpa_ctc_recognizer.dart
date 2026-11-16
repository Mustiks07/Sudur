import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:asr_sherpa/src/device_benchmark.dart';
import 'package:asr_sherpa/src/isolate_protocol.dart';
import 'package:asr_sherpa/src/recognizer_config.dart';
import 'package:asr_sherpa/src/recognizer_exception.dart';
import 'package:asr_sherpa/src/recognizer_worker.dart';
import 'package:asr_sherpa/src/request_outcome.dart';
import 'package:contracts/contracts.dart';

/// sherpa-onnx Zipformer CTC recognizer hosted by a long-lived isolate.
final class SherpaCtcRecognizer implements SpeechRecognizer {
  /// Creates an unloaded recognizer for one reading session.
  SherpaCtcRecognizer({
    required String sessionId,
    SherpaRecognizerConfig config = const SherpaRecognizerConfig(),
  })  : _sessionId = sessionId,
        _config = config;

  final String _sessionId;
  final SherpaRecognizerConfig _config;
  final StreamController<RecognitionResult> _results =
      StreamController<RecognitionResult>.broadcast();
  final StreamController<RecognizerRequestOutcome> _outcomes =
      StreamController<RecognizerRequestOutcome>.broadcast();
  final Map<int, Completer<Map<String, Object?>>> _pending =
      <int, Completer<Map<String, Object?>>>{};
  final Completer<SendPort> _workerReady = Completer<SendPort>();

  ReceivePort? _responses;
  ReceivePort? _isolateErrors;
  ReceivePort? _isolateExit;
  StreamSubscription<Object?>? _responseSubscription;
  StreamSubscription<Object?>? _errorSubscription;
  StreamSubscription<Object?>? _exitSubscription;
  Isolate? _isolate;
  SendPort? _workerPort;
  RecognizerInfo? _info;
  var _nextRequestId = 1;
  var _disposed = false;

  @override
  RecognizerInfo get info {
    final value = _info;
    if (value == null) {
      throw StateError('No ASR model has been loaded.');
    }
    return value;
  }

  @override
  Stream<RecognitionResult> get results => _results.stream;

  /// Outcomes for all numbered audio and close-segment requests.
  Stream<RecognizerRequestOutcome> get outcomes => _outcomes.stream;

  @override
  Future<Result<void>> load(String modelDirectory) async {
    if (_disposed) {
      return const Result.error(
        SherpaRecognizerException('disposed', 'The recognizer is disposed.'),
      );
    }
    if (_info != null) {
      return const Result.error(
        SherpaRecognizerException(
          'alreadyLoaded',
          'A model is already loaded.',
        ),
      );
    }
    try {
      await _ensureWorker();
      final response = await _sendAndWait(
        'load',
        <String, Object?>{
          'modelDirectory': modelDirectory,
          'sessionId': _sessionId,
          'config': <String, Object?>{
            'asrThreads': _config.asrThreads,
            'partialIntervalMs': _config.partialIntervalMs,
            'maxPartialWindowMs': _config.maxPartialWindowMs,
            'deviceTestAudioMs': _config.deviceTestAudioMs,
          },
        },
      );
      final error = _errorFromResponse(response);
      if (error != null) {
        return Result.error(error);
      }
      final value = response['value'];
      if (value is! Map<String, Object?>) {
        return const Result.error(
          SherpaRecognizerException(
            'workerProtocol',
            'The worker returned invalid model metadata.',
          ),
        );
      }
      _info = infoFromMessage(value);
      return const Result<void>.ok(null);
    } on Object {
      return const Result.error(
        SherpaRecognizerException(
          'workerStartFailed',
          'The recognizer isolate could not start.',
        ),
      );
    }
  }

  @override
  void acceptAudio(Float32List samples, int sampleRateHz, int startMs) {
    final requestId = _nextRequestId++;
    final worker = _workerPort;
    if (_disposed || worker == null || _info == null) {
      _publishLocalError(
        requestId,
        'notLoaded',
        'No recognition model is loaded.',
      );
      return;
    }
    final bytes = samples.buffer.asUint8List(
      samples.offsetInBytes,
      samples.lengthInBytes,
    );
    worker.send(<String, Object?>{
      'requestId': requestId,
      'operation': 'acceptAudio',
      'samples': TransferableTypedData.fromList(<TypedData>[bytes]),
      'sampleRateHz': sampleRateHz,
      'startMs': startMs,
    });
  }

  @override
  void closeSegment(int segmentId) {
    final requestId = _nextRequestId++;
    final worker = _workerPort;
    if (_disposed || worker == null || _info == null) {
      _publishLocalError(
        requestId,
        'notLoaded',
        'No recognition model is loaded.',
      );
      return;
    }
    worker.send(<String, Object?>{
      'requestId': requestId,
      'operation': 'closeSegment',
      'segmentId': segmentId,
    });
  }

  /// Runs the generated in-memory phone speed test on the loaded model.
  Future<Result<AsrDeviceBenchmark>> benchmarkDevice() async {
    if (_disposed || _workerPort == null || _info == null) {
      return const Result.error(
        SherpaRecognizerException(
          'notLoaded',
          'No recognition model is loaded.',
        ),
      );
    }
    final response = await _sendAndWait('benchmark', const <String, Object?>{});
    final error = _errorFromResponse(response);
    if (error != null) {
      return Result.error(error);
    }
    final value = response['value'];
    if (value is! Map<String, Object?>) {
      return const Result.error(
        SherpaRecognizerException(
          'workerProtocol',
          'The worker returned an invalid benchmark.',
        ),
      );
    }
    return Result.ok(benchmarkFromMessage(value));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
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
    _isolate?.kill(priority: Isolate.immediate);
    await _responseSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _exitSubscription?.cancel();
    _responses?.close();
    _isolateErrors?.close();
    _isolateExit?.close();
    await _results.close();
    await _outcomes.close();
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.complete(
          _failureResponse('disposed', 'The recognizer was disposed.'),
        );
      }
    }
    _pending.clear();
  }

  Future<void> _ensureWorker() async {
    if (_workerPort != null) {
      return;
    }
    final responses = ReceivePort();
    final errors = ReceivePort();
    final exit = ReceivePort();
    _responses = responses;
    _isolateErrors = errors;
    _isolateExit = exit;
    _responseSubscription = responses.listen(_handleResponse);
    _errorSubscription = errors.listen(_handleIsolateFailure);
    _exitSubscription = exit.listen(_handleIsolateExit);
    _isolate = await Isolate.spawn<SendPort>(
      runRecognizerWorker,
      responses.sendPort,
      onError: errors.sendPort,
      onExit: exit.sendPort,
      debugName: 'sudur-asr-sherpa',
    );
    _workerPort = await _workerReady.future.timeout(const Duration(seconds: 5));
  }

  Future<Map<String, Object?>> _sendAndWait(
    String operation,
    Map<String, Object?> fields,
  ) {
    final requestId = _nextRequestId++;
    final worker = _workerPort;
    if (worker == null) {
      return Future<Map<String, Object?>>.value(
        _failureResponse(
          'workerUnavailable',
          'The recognizer isolate is unavailable.',
        ),
      );
    }
    final completer = Completer<Map<String, Object?>>();
    _pending[requestId] = completer;
    worker.send(<String, Object?>{
      'requestId': requestId,
      'operation': operation,
      ...fields,
    });
    return completer.future;
  }

  void _handleResponse(Object? message) {
    if (message is SendPort) {
      if (!_workerReady.isCompleted) {
        _workerReady.complete(message);
      }
      return;
    }
    if (message is! Map<String, Object?>) {
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
    final error = _errorFromResponse(message);
    if (error != null) {
      _outcomes.add(
        RecognizerRequestOutcome(
          requestId: requestId,
          result: Result.error(error),
        ),
      );
      return;
    }
    final value = message['value'];
    if (value == null) {
      _outcomes.add(
        RecognizerRequestOutcome(
          requestId: requestId,
          result: const Result.ok(null),
        ),
      );
      return;
    }
    if (value is! Map<String, Object?>) {
      _publishLocalError(
        requestId,
        'workerProtocol',
        'The worker returned an invalid result.',
      );
      return;
    }
    try {
      final result = recognitionFromMessage(value);
      _results.add(result);
      _outcomes.add(
        RecognizerRequestOutcome(
          requestId: requestId,
          result: Result.ok(result),
        ),
      );
    } on Object {
      _publishLocalError(
        requestId,
        'workerProtocol',
        'The worker returned an invalid result.',
      );
    }
  }

  void _handleIsolateFailure(Object? _) {
    _completePendingAfterWorkerFailure();
  }

  void _handleIsolateExit(Object? _) {
    if (!_disposed) {
      _completePendingAfterWorkerFailure();
    }
  }

  void _completePendingAfterWorkerFailure() {
    final response = _failureResponse(
      'workerStopped',
      'The recognizer isolate stopped unexpectedly.',
    );
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    }
    _pending.clear();
  }

  SherpaRecognizerException? _errorFromResponse(
    Map<String, Object?> response,
  ) {
    if (response['ok'] == true) {
      return null;
    }
    return SherpaRecognizerException(
      response['errorCode'] as String? ?? 'workerError',
      response['errorMessage'] as String? ?? 'The recognizer operation failed.',
    );
  }

  void _publishLocalError(int requestId, String code, String message) {
    _outcomes.add(
      RecognizerRequestOutcome(
        requestId: requestId,
        result: Result.error(SherpaRecognizerException(code, message)),
      ),
    );
  }

  Map<String, Object?> _failureResponse(String code, String message) =>
      <String, Object?>{
        'ok': false,
        'errorCode': code,
        'errorMessage': message,
      };
}
