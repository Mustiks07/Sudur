import 'package:meta/meta.dart';

/// Identifies one word of the Quran as `surah:ayah:word`, all 1-based.
///
/// The same scheme as QUL word locations (docs/tz section 4.5).
@immutable
final class WordKey implements Comparable<WordKey> {
  /// Creates a key for [word] in [ayah] of [surah].
  const WordKey(this.surah, this.ayah, this.word)
      : assert(surah >= 1 && surah <= 114, 'surah must be in 1..114'),
        assert(ayah >= 1, 'ayah must be positive'),
        assert(word >= 1, 'word must be positive');

  /// Parses a key written as `surah:ayah:word`, for example `2:255:3`.
  ///
  /// Throws a [FormatException] if [value] is malformed.
  factory WordKey.parse(String value) {
    final parts = value.split(':');
    if (parts.length != 3) {
      throw FormatException('Expected surah:ayah:word', value);
    }
    return WordKey(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Surah number, 1..114.
  final int surah;

  /// Ayah number within the surah, starting at 1.
  final int ayah;

  /// Word number within the ayah, starting at 1.
  final int word;

  @override
  int compareTo(WordKey other) {
    if (surah != other.surah) return surah.compareTo(other.surah);
    if (ayah != other.ayah) return ayah.compareTo(other.ayah);
    return word.compareTo(other.word);
  }

  @override
  bool operator ==(Object other) =>
      other is WordKey &&
      other.surah == surah &&
      other.ayah == ayah &&
      other.word == word;

  @override
  int get hashCode => Object.hash(surah, ayah, word);

  @override
  String toString() => '$surah:$ayah:$word';
}
