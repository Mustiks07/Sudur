import 'package:contracts/contracts.dart';

/// Converts one result to the JSONL record from specification section 12.6.
Map<String, Object?> recognitionResultToJson(RecognitionResult result) =>
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
      'info': <String, Object?>{
        'modelId': result.info.modelId,
        'modelVersion': result.info.modelVersion,
        'output': result.info.output.name,
        'isStreaming': result.info.isStreaming,
        'hasTokenTimes': result.info.hasTokenTimes,
      },
    };
