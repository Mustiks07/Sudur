import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';

/// What the reader did with an expected word (docs/tz 12.6).
enum WordStatus {
  /// Read correctly.
  correct,

  /// Not read.
  omitted,

  /// Another word was read instead.
  substituted,

  /// Read wrong, then corrected by the reader.
  selfCorrected,

  /// Read correctly more than once.
  repeated,

  /// Annotators could not tell; left out of every metric.
  unclear,
}

/// One annotated expected word.
@immutable
final class AnnotatedWord {
  /// Creates an annotated word.
  const AnnotatedWord({
    required this.key,
    required this.status,
    this.heard,
    this.startMs,
    this.endMs,
    this.correctionAfterWords,
    this.correctionAfterMs,
  });

  /// The expected word.
  final WordKey key;

  /// What happened to it.
  final WordStatus status;

  /// What was read instead, for substitutions; data, never shown as Quran.
  final String? heard;

  /// Start of the word in the recording, ms.
  final int? startMs;

  /// End of the word in the recording, ms.
  final int? endMs;

  /// For `selfCorrected`: after how many words the correction came (1 = the
  /// next word read was the corrected one).
  final int? correctionAfterWords;

  /// For `selfCorrected`: ms from the start of the wrong reading to the
  /// start of the correction.
  final int? correctionAfterMs;

  /// Whether the reader read this word in the end (correct, repeated or
  /// self-corrected).
  bool get wasRead =>
      status == WordStatus.correct ||
      status == WordStatus.repeated ||
      status == WordStatus.selfCorrected;

  /// Whether the word was read correctly without trouble.
  bool get readCleanly =>
      status == WordStatus.correct || status == WordStatus.repeated;

  /// Whether the word is a true reading mistake that check should find.
  bool get isMistake =>
      status == WordStatus.omitted || status == WordStatus.substituted;
}

/// A heard stretch that is not an expected word: an extra word, or reading
/// at another place of the Quran.
@immutable
final class AnnotatedSpan {
  /// Creates a span.
  const AnnotatedSpan({
    required this.startMs,
    required this.endMs,
    this.afterWordKey,
    this.to,
  });

  /// Start in the recording, ms.
  final int startMs;

  /// End in the recording, ms.
  final int endMs;

  /// Expected word after which it happened, if known.
  final WordKey? afterWordKey;

  /// For jumps: where the reader went.
  final WordKey? to;
}

/// Who read and on what.
@immutable
final class Speaker {
  /// Creates speaker data.
  const Speaker({
    required this.id,
    required this.nativeLanguage,
    required this.gender,
    this.ageGroup,
  });

  /// Pseudonymous person id; bootstrap resamples by it (docs/tz КЧ-09).
  final String id;

  /// `ru`, `kk`, `uz`, …
  final String nativeLanguage;

  /// `m` or `f`.
  final String gender;

  /// Age band, if given.
  final String? ageGroup;
}

/// Annotation of one recording (`<id>.ann.json`, docs/tz 12.6).
@immutable
final class Annotation {
  /// Creates an annotation.
  const Annotation({
    required this.recordingId,
    required this.speaker,
    required this.device,
    required this.noise,
    required this.from,
    required this.to,
    required this.words,
    this.insertions = const [],
    this.jumps = const [],
  });

  /// Parses `<id>.ann.json`.
  static Result<Annotation> parse(String source) {
    try {
      final root = _object(jsonDecode(source), 'annotation');
      final speaker = _object(root['speaker'], 'speaker');
      final conditions = _object(root['conditions'], 'conditions');
      final expected = _object(root['expected'], 'expected');
      return Result.ok(
        Annotation(
          recordingId: _string(root['recordingId'], 'recordingId'),
          speaker: Speaker(
            id: _string(speaker['id'], 'speaker.id'),
            nativeLanguage: _string(
              speaker['nativeLanguage'],
              'speaker.nativeLanguage',
            ),
            gender: _string(speaker['gender'], 'speaker.gender'),
            ageGroup: _optionalString(speaker['ageGroup'], 'ageGroup'),
          ),
          device: _string(conditions['device'], 'conditions.device'),
          noise: _string(conditions['noise'], 'conditions.noise'),
          from: _key(expected['from'], 'expected.from'),
          to: _key(expected['to'], 'expected.to'),
          words: List.unmodifiable(
            _list(root['words'], 'words').map((w) {
              final word = _object(w, 'word');
              final correction = word['correction'] == null
                  ? null
                  : _object(word['correction'], 'correction');
              return AnnotatedWord(
                key: _key(word['wordKey'], 'wordKey'),
                status: _status(word['status']),
                heard: _optionalString(word['heard'], 'heard'),
                startMs: _optionalInt(word['startMs'], 'startMs'),
                endMs: _optionalInt(word['endMs'], 'endMs'),
                correctionAfterWords: _optionalInt(
                  correction?['afterWords'],
                  'correction.afterWords',
                ),
                correctionAfterMs: _optionalInt(
                  correction?['afterMs'],
                  'correction.afterMs',
                ),
              );
            }),
          ),
          insertions: _spans(root['insertions'], 'insertions'),
          jumps: _spans(root['jumps'], 'jumps'),
        ),
      );
    } on FormatException catch (e) {
      return Result.error(e);
    }
  }

  /// Recording id, also the file name stem.
  final String recordingId;

  /// The reader.
  final Speaker speaker;

  /// Phone class, for example `budget-android`.
  final String device;

  /// `quiet`, `noisy`, …
  final String noise;

  /// First expected word.
  final WordKey from;

  /// Last expected word.
  final WordKey to;

  /// Annotated expected words.
  final List<AnnotatedWord> words;

  /// Extra words.
  final List<AnnotatedSpan> insertions;

  /// Reading at other places of the Quran.
  final List<AnnotatedSpan> jumps;

  /// Group values for docs/tz КЧ-08.
  Map<String, String> get groups => {
        'nativeLanguage': speaker.nativeLanguage,
        'gender': speaker.gender,
        'device': device,
        'noise': noise,
      };
}

List<AnnotatedSpan> _spans(Object? value, String what) => List.unmodifiable(
      _list(value ?? const <Object?>[], what).map((s) {
        final span = _object(s, what);
        final after = span['afterWordKey'] ?? span['fromWordKey'];
        return AnnotatedSpan(
          startMs: _int(span['startMs'], '$what.startMs'),
          endMs: _int(span['endMs'], '$what.endMs'),
          afterWordKey:
              after == null ? null : _key(after, '$what.afterWordKey'),
          to: span['to'] == null ? null : _key(span['to'], '$what.to'),
        );
      }),
    );

WordStatus _status(Object? value) {
  for (final s in WordStatus.values) {
    if (s.name == value) return s;
  }
  throw FormatException('Unknown word status', value);
}

WordKey _key(Object? value, String what) {
  if (value is String) return WordKey.parse(value);
  throw FormatException('Expected a word key for $what', value);
}

Map<String, Object?> _object(Object? value, String what) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected an object for $what', value);
}

List<Object?> _list(Object? value, String what) {
  if (value is List<Object?>) return value;
  throw FormatException('Expected a list for $what', value);
}

String _string(Object? value, String what) {
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Expected a non-empty string for $what', value);
}

String? _optionalString(Object? value, String what) =>
    value == null ? null : _string(value, what);

int _int(Object? value, String what) {
  if (value is int) return value;
  throw FormatException('Expected an integer for $what', value);
}

int? _optionalInt(Object? value, String what) =>
    value == null ? null : _int(value, what);
