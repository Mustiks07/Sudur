import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';

/// One word of the canonical text and its place in the Quran.
///
/// [text] is the canon: show it, never change it. Comparison uses
/// search keys from a normalizer instead. The page layout (page, line,
/// glyph) is not part of the text: it lives in the layout package
/// (ADR 0004) and only for pages that have one.
@immutable
final class Word {
  /// Creates a word.
  const Word({
    required this.key,
    required this.index,
    required this.text,
  });

  /// Location `surah:ayah:word`.
  final WordKey key;

  /// Global 1-based index of the word in the Quran (`word_index`).
  final int index;

  /// Canonical Uthmani text, exactly as in the content database.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is Word &&
      other.key == key &&
      other.index == index &&
      other.text == text;

  @override
  int get hashCode => Object.hash(key, index, text);

  @override
  String toString() => 'Word($key, #$index)';
}
