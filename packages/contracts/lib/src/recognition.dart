import 'dart:typed_data';

import 'package:contracts/src/result.dart';
import 'package:meta/meta.dart';

/// What a speech recognition model outputs.
enum AsrOutputKind {
  /// Uthmani letters without diacritics.
  uthmaniLettersNoDiacritics,

  /// Phonemes, including short vowels.
  phonemes,
}

/// Description of the loaded recognition model (docs/tz section 4.4).
@immutable
final class RecognizerInfo {
  /// Creates a description of a recognition model.
  const RecognizerInfo({
    required this.modelId,
    required this.modelVersion,
    required this.output,
    required this.isStreaming,
    required this.hasTokenTimes,
  });

  /// Model identifier, for example `abdou/quran-asr-small`.
  final String modelId;

  /// Version of the installed model package.
  final String modelVersion;

  /// What the model outputs.
  final AsrOutputKind output;

  /// Whether the model is truly streaming; `false` means streaming is
  /// simulated by re-decoding the open segment (docs/tz section 10.3).
  final bool isStreaming;

  /// Whether tokens carry timestamps.
  final bool hasTokenTimes;
}

/// One output token of the recognizer.
@immutable
final class AsrToken {
  /// Creates a token.
  const AsrToken({required this.text, this.startMs});

  /// Token text exactly as produced by the model.
  final String text;

  /// Start time in milliseconds from session start, if the model provides it.
  final int? startMs;
}

/// One recognition result for a speech segment.
///
/// [text] is always what the model recognized. It is never replaced with the
/// expected Quran text (docs/tz requirement ПО-13).
@immutable
final class RecognitionResult {
  /// Creates a recognition result.
  const RecognitionResult({
    required this.sessionId,
    required this.segmentId,
    required this.isFinal,
    required this.text,
    required this.tokens,
    required this.audioStartMs,
    required this.audioEndMs,
    required this.decodeMs,
    required this.info,
  });

  /// Reading session this result belongs to.
  final String sessionId;

  /// Speech segment number within the session.
  final int segmentId;

  /// Whether this is the final result for the segment.
  final bool isFinal;

  /// Raw recognized text.
  final String text;

  /// Recognized tokens with optional timestamps.
  final List<AsrToken> tokens;

  /// Start of the decoded audio, in milliseconds from session start.
  final int audioStartMs;

  /// End of the decoded audio, in milliseconds from session start.
  final int audioEndMs;

  /// Time spent decoding, in milliseconds.
  final int decodeMs;

  /// Model that produced the result.
  final RecognizerInfo info;
}

/// Converts speech to text. Implementations hide the concrete model, so the
/// rest of the app never depends on it (docs/tz requirement РС-01).
abstract interface class SpeechRecognizer {
  /// Information about the loaded model.
  RecognizerInfo get info;

  /// Loads the model from an installed model package directory.
  Future<Result<void>> load(String modelDirectory);

  /// Partial and final recognition results.
  Stream<RecognitionResult> get results;

  /// Feeds mono audio samples in the range -1..1, starting at [startMs]
  /// from session start.
  void acceptAudio(Float32List samples, int sampleRateHz, int startMs);

  /// Marks the end of speech segment [segmentId] so a final result is
  /// produced.
  void closeSegment(int segmentId);

  /// Releases native resources.
  Future<void> dispose();
}
