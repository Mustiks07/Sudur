import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:asr_sherpa/src/benchmark_audio.dart';
import 'package:asr_sherpa/src/device_benchmark.dart';
import 'package:asr_sherpa/src/isolate_protocol.dart';
import 'package:asr_sherpa/src/model_package.dart';
import 'package:asr_sherpa/src/recognizer_config.dart';
import 'package:asr_sherpa/src/recognizer_exception.dart';
import 'package:asr_sherpa/src/segment_audio.dart';
import 'package:contracts/contracts.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Entry point for the long-lived native recognition isolate.
void runRecognizerWorker(SendPort ownerPort) {
  final requests = ReceivePort();
  final worker = _RecognizerWorker(ownerPort, requests);
  ownerPort.send(requests.sendPort);
  requests.listen(worker.handle);
}

final class _RecognizerWorker {
  _RecognizerWorker(this._ownerPort, this._requests);

  final SendPort _ownerPort;
  final ReceivePort _requests;
  final SegmentAudio _segment = SegmentAudio();
  AsrModelPackage? _package;
  sherpa.OfflineRecognizer? _recognizer;
  SherpaRecognizerConfig _config = const SherpaRecognizerConfig();
  String _sessionId = '';
  int _currentSegmentId = 1;
  int? _lastPartialEndMs;

  void handle(Object? rawMessage) {
    if (rawMessage is! Map<String, Object?>) {
      return;
    }
    final requestId = rawMessage['requestId'];
    final operation = rawMessage['operation'];
    if (requestId is! int || operation is! String) {
      return;
    }
    switch (operation) {
      case 'load':
        unawaited(_load(requestId, rawMessage));
        return;
      case 'acceptAudio':
        _acceptAudio(requestId, rawMessage);
        return;
      case 'closeSegment':
        _closeSegment(requestId, rawMessage);
        return;
      case 'benchmark':
        _benchmark(requestId);
        return;
      case 'dispose':
        _dispose(requestId);
        return;
      default:
        _error(
          requestId,
          'unsupportedOperation',
          'Unsupported recognizer operation.',
        );
        return;
    }
  }

  Future<void> _load(int requestId, Map<String, Object?> message) async {
    if (_recognizer != null) {
      _error(requestId, 'alreadyLoaded', 'A model is already loaded.');
      return;
    }
    final directory = message['modelDirectory'];
    final sessionId = message['sessionId'];
    final configValue = message['config'];
    if (directory is! String ||
        sessionId is! String ||
        configValue is! Map<String, Object?>) {
      _error(requestId, 'invalidRequest', 'The load request is invalid.');
      return;
    }
    final packageResult = await AsrModelPackage.load(directory);
    switch (packageResult) {
      case Error(:final error):
        final safeError = error is SherpaRecognizerException
            ? error
            : const SherpaRecognizerException(
                'invalidModelPackage',
                'The model package is invalid.',
              );
        _error(requestId, safeError.code, safeError.message);
      case Ok(:final value):
        final asrThreads = configValue['asrThreads'];
        final partialIntervalMs = configValue['partialIntervalMs'];
        final maxPartialWindowMs = configValue['maxPartialWindowMs'];
        final deviceTestAudioMs = configValue['deviceTestAudioMs'];
        if (asrThreads is! int ||
            partialIntervalMs is! int ||
            maxPartialWindowMs is! int ||
            deviceTestAudioMs is! int) {
          _error(
            requestId,
            'invalidRequest',
            'Recognizer parameters are invalid.',
          );
          return;
        }
        try {
          _config = SherpaRecognizerConfig(
            asrThreads: asrThreads,
            partialIntervalMs: partialIntervalMs,
            maxPartialWindowMs: maxPartialWindowMs,
            deviceTestAudioMs: deviceTestAudioMs,
          );
          _sessionId = sessionId;
          sherpa.initBindings();
          final recognizer = sherpa.OfflineRecognizer(
            sherpa.OfflineRecognizerConfig(
              model: sherpa.OfflineModelConfig(
                zipformerCtc: sherpa.OfflineZipformerCtcModelConfig(
                  model: value.modelPath,
                ),
                tokens: value.tokensPath,
                numThreads: _config.asrThreads,
                debug: false,
              ),
            ),
          );
          _package = value;
          _recognizer = recognizer;
          _success(requestId, infoToMessage(value.info));
        } on Object {
          _error(
            requestId,
            'modelLoadFailed',
            'sherpa-onnx could not load the model.',
          );
        }
    }
  }

  void _acceptAudio(int requestId, Map<String, Object?> message) {
    final package = _package;
    if (package == null || _recognizer == null) {
      _error(requestId, 'notLoaded', 'No recognition model is loaded.');
      return;
    }
    final transfer = message['samples'];
    final sampleRate = message['sampleRateHz'];
    final startMs = message['startMs'];
    if (transfer is! TransferableTypedData ||
        sampleRate is! int ||
        startMs is! int) {
      _error(requestId, 'invalidRequest', 'The audio request is invalid.');
      return;
    }
    if (sampleRate != package.sampleRate) {
      _error(
        requestId,
        'sampleRateMismatch',
        'Audio sample rate does not match the model.',
      );
      return;
    }
    final bytes = transfer.materialize().asUint8List();
    if (bytes.lengthInBytes.isOdd || bytes.lengthInBytes % 4 != 0) {
      _error(requestId, 'invalidAudio', 'The audio buffer is not Float32 PCM.');
      return;
    }
    final samples = Float32List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 4,
    );
    _segment.add(samples, sampleRate, startMs);
    final endMs = _segment.endMs;
    if (endMs == null) {
      _success(requestId, null);
      return;
    }
    final previousPartial = _lastPartialEndMs ?? _segment.startMs ?? endMs;
    if (endMs - previousPartial < _config.partialIntervalMs) {
      _success(requestId, null);
      return;
    }
    _lastPartialEndMs = endMs;
    final windowSamples =
        package.sampleRate * _config.maxPartialWindowMs ~/ 1000;
    final samplesToDecode = _segment.tail(windowSamples);
    final windowDurationMs =
        samplesToDecode.length * 1000 ~/ package.sampleRate;
    try {
      final result = _decode(
        samples: samplesToDecode,
        segmentId: _currentSegmentId,
        isFinal: false,
        audioStartMs: endMs - windowDurationMs,
        audioEndMs: endMs,
      );
      _success(requestId, recognitionToMessage(result));
    } on Object {
      _error(
        requestId,
        'decodeFailed',
        'sherpa-onnx could not decode the partial window.',
      );
    }
  }

  void _closeSegment(int requestId, Map<String, Object?> message) {
    final package = _package;
    if (package == null || _recognizer == null) {
      _error(requestId, 'notLoaded', 'No recognition model is loaded.');
      return;
    }
    final segmentId = message['segmentId'];
    final startMs = _segment.startMs;
    final endMs = _segment.endMs;
    if (segmentId is! int || startMs == null || endMs == null) {
      _error(
        requestId,
        'emptySegment',
        'Cannot close an empty speech segment.',
      );
      return;
    }
    _currentSegmentId = segmentId;
    try {
      final result = _decode(
        samples: _segment.allSamples(),
        segmentId: segmentId,
        isFinal: true,
        audioStartMs: startMs,
        audioEndMs: endMs,
      );
      _success(requestId, recognitionToMessage(result));
    } on Object {
      _error(
        requestId,
        'decodeFailed',
        'sherpa-onnx could not decode the segment.',
      );
    } finally {
      _segment.clear();
      _lastPartialEndMs = null;
      _currentSegmentId = segmentId + 1;
    }
  }

  void _benchmark(int requestId) {
    final package = _package;
    if (package == null || _recognizer == null) {
      _error(requestId, 'notLoaded', 'No recognition model is loaded.');
      return;
    }
    try {
      final samples = generateBenchmarkNoise(
        sampleRate: package.sampleRate,
        durationMs: _config.deviceTestAudioMs,
      );
      final stopwatch = Stopwatch()..start();
      _decodeNative(samples, package.sampleRate);
      stopwatch.stop();
      _success(
        requestId,
        benchmarkToMessage(
          AsrDeviceBenchmark(
            modelId: package.info.modelId,
            audioDurationMs: _config.deviceTestAudioMs,
            decodeMs: stopwatch.elapsedMilliseconds,
          ),
        ),
      );
    } on Object {
      _error(requestId, 'benchmarkFailed', 'The model speed test failed.');
    }
  }

  RecognitionResult _decode({
    required Float32List samples,
    required int segmentId,
    required bool isFinal,
    required int audioStartMs,
    required int audioEndMs,
  }) {
    final package = _package;
    if (package == null) {
      throw StateError('No model package is loaded.');
    }
    final stopwatch = Stopwatch()..start();
    final nativeResult = _decodeNative(samples, package.sampleRate);
    stopwatch.stop();
    final tokens = <AsrToken>[];
    for (var index = 0; index < nativeResult.tokens.length; index++) {
      final timestamp = index < nativeResult.timestamps.length
          ? audioStartMs + (nativeResult.timestamps[index] * 1000).round()
          : null;
      tokens
          .add(AsrToken(text: nativeResult.tokens[index], startMs: timestamp));
    }
    return RecognitionResult(
      sessionId: _sessionId,
      segmentId: segmentId,
      isFinal: isFinal,
      text: nativeResult.text,
      tokens: tokens,
      audioStartMs: audioStartMs,
      audioEndMs: audioEndMs,
      decodeMs: stopwatch.elapsedMilliseconds,
      info: package.info,
    );
  }

  sherpa.OfflineRecognizerResult _decodeNative(
    Float32List samples,
    int sampleRate,
  ) {
    final recognizer = _recognizer;
    if (recognizer == null) {
      throw StateError('No recognizer is loaded.');
    }
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
      recognizer.decode(stream);
      return recognizer.getResult(stream);
    } finally {
      stream.free();
    }
  }

  void _dispose(int requestId) {
    _segment.clear();
    _recognizer?.free();
    _recognizer = null;
    _package = null;
    _success(requestId, null);
    _requests.close();
  }

  void _success(int requestId, Object? value) {
    _ownerPort.send(<String, Object?>{
      'requestId': requestId,
      'ok': true,
      'value': value,
    });
  }

  void _error(int requestId, String code, String message) {
    _ownerPort.send(<String, Object?>{
      'requestId': requestId,
      'ok': false,
      'errorCode': code,
      'errorMessage': message,
    });
  }
}
