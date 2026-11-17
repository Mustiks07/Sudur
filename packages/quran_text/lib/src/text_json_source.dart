import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:quran_text/src/content_json_source.dart';
import 'package:quran_text/src/word.dart';

/// Reads the whole-Quran text JSON written by `tools/content_build`
/// (format 2, `kind: "text"`, ADR 0004), for example
/// `packages/testing/fixtures/quran_text.json`: one `[surah, ayah, [words]]`
/// per ayah, word indexes following from the order.
final class QuranTextJsonSource implements QuranTextSource {
  /// Creates a source over the JSON text [json].
  const QuranTextJsonSource(this.json);

  /// Supported value of the `format` field.
  static const int supportedFormat = 2;

  /// The JSON text.
  final String json;

  @override
  Result<List<Word>> loadWords() {
    try {
      final root = jsonDecode(json);
      if (root is! Map<String, Object?> ||
          root['format'] != supportedFormat ||
          root['kind'] != 'text') {
        throw const ContentFormatException(
          'Expected the text JSON (format 2, kind "text").',
        );
      }
      final ayahs = root['ayahs'];
      if (ayahs is! List<Object?>) {
        throw const ContentFormatException('"ayahs" must be a list.');
      }
      final words = <Word>[];
      for (final entry in ayahs) {
        if (entry
            case [final int surah, final int ayah, final List<Object?> texts]) {
          for (var i = 0; i < texts.length; i++) {
            final text = texts[i];
            if (text is! String || text.isEmpty) {
              throw ContentFormatException('Empty word in $surah:$ayah.');
            }
            words.add(
              Word(
                key: WordKey(surah, ayah, i + 1),
                index: words.length + 1,
                text: text,
              ),
            );
          }
        } else {
          throw const ContentFormatException(
            'Each ayah must be [surah, ayah, [words]].',
          );
        }
      }
      return Result.ok(List.unmodifiable(words));
    } on FormatException catch (e) {
      return Result.error(e);
    } on ContentFormatException catch (e) {
      return Result.error(e);
    }
  }
}
