import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:quran_text/src/word.dart';

/// Where the canonical words come from.
abstract interface class QuranTextSource {
  /// Loads all available words in reading order.
  Result<List<Word>> loadWords();
}

/// Error in the content JSON.
final class ContentFormatException implements Exception {
  /// Creates the exception.
  const ContentFormatException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'ContentFormatException: $message';
}

/// Reads the JSON copy of the content database written by
/// `tools/content_build` (format 1), for example
/// `packages/testing/fixtures/content_p582_583.json`.
final class ContentJsonSource implements QuranTextSource {
  /// Creates a source over the JSON text [json].
  const ContentJsonSource(this.json);

  /// Supported value of the `format` field.
  static const int supportedFormat = 1;

  /// The JSON text.
  final String json;

  @override
  Result<List<Word>> loadWords() {
    try {
      final root = jsonDecode(json);
      if (root is! Map<String, Object?>) {
        throw const ContentFormatException('Expected a JSON object.');
      }
      if (root['format'] != supportedFormat) {
        throw ContentFormatException('Unsupported format ${root['format']}.');
      }
      final rows = root['words'];
      if (rows is! List<Object?>) {
        throw const ContentFormatException('"words" must be a list.');
      }
      return Result.ok(List.unmodifiable(rows.map(_word)));
    } on FormatException catch (e) {
      return Result.error(e);
    } on ContentFormatException catch (e) {
      return Result.error(e);
    }
  }

  Word _word(Object? row) {
    if (row is! Map<String, Object?>) {
      throw const ContentFormatException('Each word must be an object.');
    }
    int number(String field) {
      final value = row[field];
      if (value is int) return value;
      throw ContentFormatException('Word field "$field" must be an integer.');
    }

    final text = row['textUthmani'];
    if (text is! String || text.isEmpty) {
      throw const ContentFormatException('Word without "textUthmani".');
    }
    return Word(
      key: WordKey(number('surah'), number('ayah'), number('position')),
      index: number('wordIndex'),
      text: text,
    ); // Page and line of format 1 belong to the layout (ADR 0004).
  }
}
