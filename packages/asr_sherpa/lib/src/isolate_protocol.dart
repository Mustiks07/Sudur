import 'package:asr_sherpa/src/device_benchmark.dart';
import 'package:contracts/contracts.dart';

/// Encodes model metadata for an isolate message.
Map<String, Object?> infoToMessage(RecognizerInfo info) => <String, Object?>{
      'modelId': info.modelId,
      'modelVersion': info.modelVersion,
      'output': info.output.name,
      'isStreaming': info.isStreaming,
      'hasTokenTimes': info.hasTokenTimes,
    };

/// Decodes model metadata from an isolate message.
RecognizerInfo infoFromMessage(Map<String, Object?> value) => RecognizerInfo(
      modelId: _required<String>(value, 'modelId'),
      modelVersion: _required<String>(value, 'modelVersion'),
      output: AsrOutputKind.values.byName(_required<String>(value, 'output')),
      isStreaming: _required<bool>(value, 'isStreaming'),
      hasTokenTimes: _required<bool>(value, 'hasTokenTimes'),
    );

/// Encodes a recognition result for an isolate message.
Map<String, Object?> recognitionToMessage(RecognitionResult result) =>
    <String, Object?>{
      'sessionId': result.sessionId,
      'segmentId': result.segmentId,
      'isFinal': result.isFinal,
      'text': result.text,
      'tokens': result.tokens
          .map(
            (token) => <String, Object?>{
              'text': token.text,
              'startMs': token.startMs,
            },
          )
          .toList(growable: false),
      'audioStartMs': result.audioStartMs,
      'audioEndMs': result.audioEndMs,
      'decodeMs': result.decodeMs,
      'info': infoToMessage(result.info),
    };

/// Decodes a recognition result from an isolate message.
RecognitionResult recognitionFromMessage(Map<String, Object?> value) {
  final tokenValues = value['tokens'];
  if (tokenValues is! List<Object?>) {
    throw const FormatException('Worker returned invalid tokens.');
  }
  return RecognitionResult(
    sessionId: _required<String>(value, 'sessionId'),
    segmentId: _required<int>(value, 'segmentId'),
    isFinal: _required<bool>(value, 'isFinal'),
    text: _required<String>(value, 'text'),
    tokens: tokenValues.map((item) {
      if (item is! Map<String, Object?>) {
        throw const FormatException('Worker returned an invalid token.');
      }
      return AsrToken(
        text: _required<String>(item, 'text'),
        startMs: _optionalInt(item, 'startMs'),
      );
    }).toList(growable: false),
    audioStartMs: _required<int>(value, 'audioStartMs'),
    audioEndMs: _required<int>(value, 'audioEndMs'),
    decodeMs: _required<int>(value, 'decodeMs'),
    info: infoFromMessage(
      _required<Map<String, Object?>>(value, 'info'),
    ),
  );
}

/// Encodes a device benchmark for an isolate message.
Map<String, Object?> benchmarkToMessage(AsrDeviceBenchmark benchmark) =>
    <String, Object?>{
      'modelId': benchmark.modelId,
      'audioDurationMs': benchmark.audioDurationMs,
      'decodeMs': benchmark.decodeMs,
    };

/// Decodes a device benchmark from an isolate message.
AsrDeviceBenchmark benchmarkFromMessage(Map<String, Object?> value) =>
    AsrDeviceBenchmark(
      modelId: _required<String>(value, 'modelId'),
      audioDurationMs: _required<int>(value, 'audioDurationMs'),
      decodeMs: _required<int>(value, 'decodeMs'),
    );

T _required<T>(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! T) {
    throw FormatException('Worker field $key has an invalid type.');
  }
  return field;
}

int? _optionalInt(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field == null) {
    return null;
  }
  if (field is int) {
    return field;
  }
  throw FormatException('Worker field $key has an invalid type.');
}
