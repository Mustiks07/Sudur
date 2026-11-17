import 'dart:convert';

import 'package:contracts/contracts.dart';

/// Reads `<id>.<model>.asr.jsonl` (docs/tz 12.6): one [RecognitionResult]
/// per line, field names as in the contract, `info.output` by enum name.
/// Empty lines are skipped.
Result<List<RecognitionResult>> parseAsrJsonl(String source) {
  final results = <RecognitionResult>[];
  final lines = const LineSplitter().convert(source);
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    try {
      results.add(recognitionResultFromJson(jsonDecode(lines[i])));
    } on FormatException catch (e) {
      return Result.error(
        FormatException('Line ${i + 1}: ${e.message}', e.source),
      );
    }
  }
  return Result.ok(List.unmodifiable(results));
}

/// One [RecognitionResult] from its JSON object.
RecognitionResult recognitionResultFromJson(Object? json) {
  final r = _object(json);
  final info = _object(r['info']);
  final output = info['output'];
  return RecognitionResult(
    sessionId: _string(r['sessionId'], 'sessionId'),
    segmentId: _int(r['segmentId'], 'segmentId'),
    isFinal: _bool(r['isFinal'], 'isFinal'),
    text: _text(r['text']),
    tokens: [
      for (final t in _list(r['tokens'] ?? const <Object?>[]))
        AsrToken(
          text: _text(_object(t)['text']),
          startMs: switch (_object(t)['startMs']) {
            null => null,
            final int v => v,
            final v => throw FormatException('Bad token startMs', v),
          },
        ),
    ],
    audioStartMs: _int(r['audioStartMs'], 'audioStartMs'),
    audioEndMs: _int(r['audioEndMs'], 'audioEndMs'),
    decodeMs: _int(r['decodeMs'], 'decodeMs'),
    info: RecognizerInfo(
      modelId: _string(info['modelId'], 'info.modelId'),
      modelVersion: _string(info['modelVersion'], 'info.modelVersion'),
      output: AsrOutputKind.values.firstWhere(
        (k) => k.name == output,
        orElse: () => throw FormatException('Bad info.output', output),
      ),
      isStreaming: _bool(info['isStreaming'], 'info.isStreaming'),
      hasTokenTimes: _bool(info['hasTokenTimes'], 'info.hasTokenTimes'),
    ),
  );
}

/// JSON form of a [RecognitionResult], the inverse of
/// [recognitionResultFromJson]; used to write synthetic corpora.
Map<String, Object?> recognitionResultToJson(RecognitionResult r) => {
      'sessionId': r.sessionId,
      'segmentId': r.segmentId,
      'isFinal': r.isFinal,
      'text': r.text,
      'tokens': [
        for (final t in r.tokens) {'text': t.text, 'startMs': t.startMs},
      ],
      'audioStartMs': r.audioStartMs,
      'audioEndMs': r.audioEndMs,
      'decodeMs': r.decodeMs,
      'info': {
        'modelId': r.info.modelId,
        'modelVersion': r.info.modelVersion,
        'output': r.info.output.name,
        'isStreaming': r.info.isStreaming,
        'hasTokenTimes': r.info.hasTokenTimes,
      },
    };

Map<String, Object?> _object(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected an object', value);
}

List<Object?> _list(Object? value) {
  if (value is List<Object?>) return value;
  throw FormatException('Expected a list', value);
}

String _string(Object? value, String what) {
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Expected a non-empty string for $what', value);
}

/// Recognized text may be empty (silence), but must be a string.
String _text(Object? value) {
  if (value is String) return value;
  throw FormatException('Expected a string', value);
}

int _int(Object? value, String what) {
  if (value is int) return value;
  throw FormatException('Expected an integer for $what', value);
}

bool _bool(Object? value, String what) {
  if (value is bool) return value;
  throw FormatException('Expected a boolean for $what', value);
}
