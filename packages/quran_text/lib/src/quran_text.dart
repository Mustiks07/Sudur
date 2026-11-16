import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';
import 'package:quran_text/src/search_key.dart';
import 'package:quran_text/src/word.dart';

/// A place found by [QuranText.findSequence].
@immutable
final class SequenceMatch {
  /// Creates a match.
  const SequenceMatch({required this.start, required this.matchedNgrams});

  /// Word where the first searched key would stand.
  final WordKey start;

  /// How many n-grams of the query matched here; more is better.
  final int matchedNgrams;

  @override
  String toString() => 'SequenceMatch($start, $matchedNgrams)';
}

/// Canonical text, search keys and sequence search (docs/tz section 10.1).
abstract interface class QuranText {
  /// Whether [key] is in the loaded text.
  bool contains(WordKey key);

  /// The word at [key]. Throws [ArgumentError] if [contains] is false.
  Word word(WordKey key);

  /// Words from [from] to [to], inclusive, in reading order. Throws
  /// [ArgumentError] if either end is missing or [to] is before [from].
  List<Word> range(WordKey from, WordKey to);

  /// Technical key of the word at [key] for [normalizer]. Never show it to
  /// the user. Throws [ArgumentError] for an unknown word or normalizer.
  SearchKey searchKey(WordKey key, NormalizerId normalizer);

  /// Places of [keys] (consecutive recognized words), best first, found
  /// through the n-gram index of [normalizer].
  List<SequenceMatch> findSequence(
    List<SearchKey> keys, {
    required NormalizerId normalizer,
    int maxResults = 10,
  });
}
