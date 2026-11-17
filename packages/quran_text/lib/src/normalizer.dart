import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';
import 'package:quran_text/src/search_key.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// An inclusive range of Unicode code points to delete.
@immutable
final class CodePointRange {
  /// Creates a range [from]..[to], inclusive.
  const CodePointRange(this.from, this.to);

  /// First code point.
  final int from;

  /// Last code point.
  final int to;

  /// Whether [codePoint] is inside the range.
  bool contains(int codePoint) => codePoint >= from && codePoint <= to;
}

/// One row of the replacement table: every [from] becomes [to].
@immutable
final class Replacement {
  /// Creates a replacement.
  const Replacement(this.from, this.to);

  /// Text to find. Never empty.
  final String from;

  /// Text to put instead.
  final String to;
}

/// Error in a `normalizer.json` file.
final class NormalizerFormatException implements Exception {
  /// Creates the exception.
  const NormalizerFormatException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'NormalizerFormatException: $message';
}

/// Builds search keys from canonical words and recognized text by the rules
/// of `normalizer.json` (docs/tz sections 10.1, 12.3).
///
/// Steps, in order: Unicode NFC (if [nfc]); delete code points in
/// [removeRanges]; apply [replacements] in table order; delete
/// [wordSeparator] and spaces left inside a word. Everything is driven by
/// the table: there are no hidden rules.
///
/// The input string is never modified; a new key is returned.
@immutable
final class Normalizer {
  /// Creates a normalizer.
  const Normalizer({
    required this.id,
    required this.nfc,
    required this.removeRanges,
    required this.replacements,
    required this.wordSeparator,
  });

  /// The built-in normalizer of docs/tz section 10.1, used when a model
  /// package gives none: NFC; delete tatweel (U+0640), harakat
  /// (U+064B–U+0652) and Quranic annotation signs (U+06D6–U+06ED); delete
  /// spaces inside a word. It has no replacement table: alef variants,
  /// hamza, ى/ي and ة/ه are handled only by a model's table (step 4).
  static const Normalizer builtIn = Normalizer(
    id: NormalizerId('builtin-10.1'),
    nfc: true,
    removeRanges: [
      CodePointRange(0x0640, 0x0640),
      CodePointRange(0x064B, 0x0652),
      CodePointRange(0x06D6, 0x06ED),
    ],
    replacements: [],
    wordSeparator: ' ',
  );

  /// Parses `normalizer.json`:
  ///
  /// ```json
  /// {
  ///   "id": "quran-asr-small-1",
  ///   "nfc": true,
  ///   "removeRanges": [{"from": "064B", "to": "0652"}],
  ///   "replace": [{"from": "…", "to": "…"}],
  ///   "wordSeparator": " "
  /// }
  /// ```
  ///
  /// Code points are hexadecimal. `nfc` defaults to `true`.
  static Result<Normalizer> fromJson(String source) {
    try {
      final root = jsonDecode(source);
      if (root is! Map<String, Object?>) {
        throw const NormalizerFormatException('Expected a JSON object.');
      }
      final id = root['id'];
      final separator = root['wordSeparator'];
      final nfc = root['nfc'] ?? true;
      if (id is! String || id.isEmpty) {
        throw const NormalizerFormatException('"id" must be a string.');
      }
      if (separator is! String || separator.isEmpty) {
        throw const NormalizerFormatException(
          '"wordSeparator" must be a non-empty string.',
        );
      }
      if (nfc is! bool) {
        throw const NormalizerFormatException('"nfc" must be a boolean.');
      }
      return Result.ok(
        Normalizer(
          id: NormalizerId(id),
          nfc: nfc,
          removeRanges: List.unmodifiable(
            _objects(root['removeRanges'] ?? const <Object?>[], 'removeRanges')
                .map((r) {
              final from = _codePoint(r['from']);
              final to = _codePoint(r['to']);
              if (from > to) {
                throw NormalizerFormatException('Range $from > $to.');
              }
              return CodePointRange(from, to);
            }),
          ),
          replacements: List.unmodifiable(
            _objects(root['replace'] ?? const <Object?>[], 'replace').map((r) {
              final from = r['from'];
              final to = r['to'];
              if (from is! String || from.isEmpty || to is! String) {
                throw const NormalizerFormatException(
                  'Each "replace" row needs a non-empty "from" and a "to".',
                );
              }
              return Replacement(from, to);
            }),
          ),
          wordSeparator: separator,
        ),
      );
    } on FormatException catch (e) {
      return Result.error(e);
    } on NormalizerFormatException catch (e) {
      return Result.error(e);
    }
  }

  /// Identifier, stored with keys built by this normalizer.
  final NormalizerId id;

  /// Whether to apply Unicode NFC first.
  final bool nfc;

  /// Code points to delete.
  final List<CodePointRange> removeRanges;

  /// Replacement table, applied in order.
  final List<Replacement> replacements;

  /// Separator between words in recognized text.
  final String wordSeparator;

  /// Search key of one canonical word or one recognized token.
  SearchKey keyOf(String word) {
    var text = nfc ? unorm.nfc(word) : word;
    text = String.fromCharCodes(
      text.runes.where((r) => !removeRanges.any((range) => range.contains(r))),
    );
    for (final r in replacements) {
      text = text.replaceAll(r.from, r.to);
    }
    return SearchKey(
      text.replaceAll(wordSeparator, '').replaceAll(_space, ''),
    );
  }

  /// Splits recognized text into words and returns their non-empty keys.
  List<SearchKey> keysOfText(String recognized) => [
        for (final token in recognized.split(wordSeparator))
          if (keyOf(token) case final key when !key.isEmpty) key,
      ];
}

const String _space = ' ';

List<Map<String, Object?>> _objects(Object? value, String what) {
  if (value is! List<Object?>) {
    throw NormalizerFormatException('"$what" must be a list.');
  }
  return [
    for (final item in value)
      if (item is Map<String, Object?>)
        item
      else
        throw NormalizerFormatException('"$what" must hold objects.'),
  ];
}

int _codePoint(Object? value) {
  final parsed = value is String ? int.tryParse(value, radix: 16) : null;
  if (parsed == null || parsed < 0 || parsed > 0x10FFFF) {
    throw NormalizerFormatException('Bad code point: $value');
  }
  return parsed;
}
