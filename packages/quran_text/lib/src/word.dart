import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';

/// One word of the canonical text with its place in the mushaf.
///
/// [text] is the canon: show it, never change it. Comparison uses
/// search keys from a normalizer instead.
@immutable
final class Word {
  /// Creates a word.
  const Word({
    required this.key,
    required this.index,
    required this.text,
    required this.page,
    required this.line,
  });

  /// Location `surah:ayah:word`.
  final WordKey key;

  /// Global 1-based index of the word in the Quran (`word_index`).
  final int index;

  /// Canonical Uthmani text, exactly as in the content database.
  final String text;

  /// Mushaf page.
  final int page;

  /// Line on the page.
  final int line;

  @override
  bool operator ==(Object other) =>
      other is Word &&
      other.key == key &&
      other.index == index &&
      other.text == text &&
      other.page == page &&
      other.line == line;

  @override
  int get hashCode => Object.hash(key, index, text, page, line);

  @override
  String toString() => 'Word($key, #$index, p$page:$line)';
}
