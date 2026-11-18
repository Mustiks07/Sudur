import 'package:meta/meta.dart';
import 'package:quran_text/src/search_key.dart';
import 'package:quran_text/src/similarity.dart';
import 'package:quran_text/src/word.dart';

/// Parameters of [findSimilarPlaces]. All are tunables: none is fixed by the
/// spec, so they come from the build config of `tools/content_build`.
@immutable
final class SimilarPlaceParams {
  /// Creates parameters.
  const SimilarPlaceParams({
    required this.minPhraseWords,
    required this.minAyahWords,
    required this.wordSimilarity,
  });

  /// A shared phrase is a pair when it has at least this many words.
  final int minPhraseWords;

  /// A whole ayah repeated elsewhere is a pair when it has at least this
  /// many words (shorter than [minPhraseWords] is allowed: refrains).
  final int minAyahWords;

  /// Inside a phrase, a word may differ from its counterpart if their
  /// similarity is at least this; the phrase starts and ends on equal
  /// words.
  final double wordSimilarity;
}

/// Two similar places of the text, as inclusive ranges of word indexes
/// (`Word.index`, 1-based). Always `aFrom < bFrom`; the ranges do not
/// overlap.
@immutable
final class SimilarPlacePair {
  /// Creates a pair.
  const SimilarPlacePair({
    required this.aFrom,
    required this.aTo,
    required this.bFrom,
    required this.bTo,
    required this.wholeAyahs,
  });

  /// First word of the first place.
  final int aFrom;

  /// Last word of the first place.
  final int aTo;

  /// First word of the second place.
  final int bFrom;

  /// Last word of the second place.
  final int bTo;

  /// Both places are the same whole ayah(s).
  final bool wholeAyahs;

  /// Words in a place.
  int get length => aTo - aFrom + 1;

  @override
  bool operator ==(Object other) =>
      other is SimilarPlacePair &&
      other.aFrom == aFrom &&
      other.aTo == aTo &&
      other.bFrom == bFrom &&
      other.bTo == bTo;

  @override
  int get hashCode => Object.hash(aFrom, aTo, bFrom, bTo);

  @override
  String toString() => 'SimilarPlacePair($aFrom–$aTo ~ $bFrom–$bTo)';
}

/// Pairs of similar places in [words] by their search [keys] (one per word,
/// same order): repeated ayahs and shared phrases in different places
/// (docs/tz 12.2 `similar_pair`, УП-05). Derived data: the text itself is
/// only read.
///
/// 1. **Repeated ayahs:** ayahs whose keys are all equal, with at least
///    `minAyahWords` words, pair with each other.
/// 2. **Shared phrases:** every run of `minPhraseWords` equal keys seeds a
///    pair; it is extended both ways while the words are similar (at least
///    `wordSimilarity`) and trimmed to start and end on equal words. Each
///    maximal phrase is reported once; places that overlap are skipped.
///
/// Result is sorted by `aFrom`, then `bFrom`, without duplicates.
List<SimilarPlacePair> findSimilarPlaces(
  List<Word> words,
  List<SearchKey> keys,
  SimilarPlaceParams params,
) {
  if (keys.length != words.length) {
    throw ArgumentError('one key per word: ${keys.length} ≠ ${words.length}');
  }
  final k = [for (final key in keys) key.value];
  final pairs = <SimilarPlacePair>{};

  // Ayah spans: [first, last] positions in the list.
  final spans = <(int, int)>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i].key;
    if (i == 0 ||
        w.surah != words[i - 1].key.surah ||
        w.ayah != words[i - 1].key.ayah) {
      spans.add((i, i));
    } else {
      spans.last = (spans.last.$1, i);
    }
  }

  // 1. Repeated ayahs.
  final byText = <String, List<(int, int)>>{};
  for (final s in spans) {
    if (s.$2 - s.$1 + 1 < params.minAyahWords) continue;
    (byText[k.sublist(s.$1, s.$2 + 1).join('\u0000')] ??= []).add(s);
  }
  for (final group in byText.values) {
    for (var x = 0; x < group.length; x++) {
      for (var y = x + 1; y < group.length; y++) {
        pairs.add(_pair(words, group[x], group[y], wholeAyahs: true));
      }
    }
  }

  // 2. Shared phrases.
  final n = params.minPhraseWords;
  final seeds = <String, List<int>>{};
  for (var i = 0; i + n <= k.length; i++) {
    (seeds[k.sublist(i, i + n).join('\u0000')] ??= []).add(i);
  }
  bool alike(int i, int j) =>
      k[i] == k[j] || similarity(k[i], k[j]) >= params.wordSimilarity;
  final seen = <(int, int, int)>{};
  for (final places in seeds.values) {
    for (var x = 0; x < places.length; x++) {
      for (var y = x + 1; y < places.length; y++) {
        var a = places[x];
        var b = places[y];
        var end = n - 1; // Offset of the last word of the phrase.
        while (a > 0 && b - 1 > a + end && alike(a - 1, b - 1)) {
          a--;
          b--;
          end++;
        }
        while (b + end + 1 < k.length &&
            a + end + 1 < b &&
            alike(a + end + 1, b + end + 1)) {
          end++;
        }
        // Start and end on equal words.
        while (k[a] != k[b]) {
          a++;
          b++;
          end--;
        }
        while (k[a + end] != k[b + end]) {
          end--;
        }
        if (a + end >= b) continue; // Overlapping places.
        if (!seen.add((a, b, end))) continue;
        if (end + 1 < n) continue;
        pairs.add(_pair(words, (a, a + end), (b, b + end), wholeAyahs: false));
      }
    }
  }

  // A phrase that is exactly a repeated ayah pair is one pair.
  final result = <SimilarPlacePair>[];
  final byRange = <(int, int, int, int), SimilarPlacePair>{};
  for (final p in pairs) {
    final key = (p.aFrom, p.aTo, p.bFrom, p.bTo);
    final old = byRange[key];
    if (old == null || (p.wholeAyahs && !old.wholeAyahs)) byRange[key] = p;
  }
  result
    ..addAll(byRange.values)
    ..sort(
      (x, y) => x.aFrom != y.aFrom
          ? x.aFrom.compareTo(y.aFrom)
          : x.bFrom != y.bFrom
              ? x.bFrom.compareTo(y.bFrom)
              : x.aTo.compareTo(y.aTo),
    );
  return result;
}

SimilarPlacePair _pair(
  List<Word> words,
  (int, int) a,
  (int, int) b, {
  required bool wholeAyahs,
}) {
  final (first, second) = a.$1 < b.$1 ? (a, b) : (b, a);
  return SimilarPlacePair(
    aFrom: words[first.$1].index,
    aTo: words[first.$2].index,
    bFrom: words[second.$1].index,
    bTo: words[second.$2].index,
    wholeAyahs: wholeAyahs,
  );
}
