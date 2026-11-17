import 'package:contracts/contracts.dart';
import 'package:quran_text/src/ngram_index.dart';
import 'package:quran_text/src/normalizer.dart';
import 'package:quran_text/src/quran_text.dart';
import 'package:quran_text/src/search_key.dart';
import 'package:quran_text/src/search_key_cache.dart';
import 'package:quran_text/src/search_params.dart';
import 'package:quran_text/src/similarity.dart';
import 'package:quran_text/src/word.dart';

/// [QuranText] over words held in memory, with keys and an n-gram index
/// built once per normalizer.
///
/// The words are not copied or changed: keys live in separate lists.
final class InMemoryQuranText implements QuranText {
  /// Creates the text from [words] in reading order, building keys for each
  /// of [normalizers].
  ///
  /// [cachedKeys] are keys read from a [SearchKeyCache]: for a normalizer
  /// present there (one key per word) keys are not built again.
  InMemoryQuranText({
    required List<Word> words,
    required List<Normalizer> normalizers,
    required SearchParams params,
    Map<NormalizerId, List<SearchKey>> cachedKeys = const {},
  }) : _words = List.unmodifiable(words) {
    for (var i = 0; i < _words.length; i++) {
      if (i > 0 && _words[i - 1].key.compareTo(_words[i].key) >= 0) {
        throw ArgumentError.value(_words[i].key, 'words', 'not in order');
      }
      _positions[_words[i].key] = i;
    }
    for (final n in normalizers) {
      final cached = cachedKeys[n.id];
      if (cached != null && cached.length != _words.length) {
        throw ArgumentError.value(
          cached.length,
          'cachedKeys',
          'has ${cached.length} keys for ${_words.length} words',
        );
      }
      final keys = List<SearchKey>.unmodifiable(
        cached ?? _words.map((w) => n.keyOf(w.text)),
      );
      _keys[n.id] = keys;
      _indexes[n.id] = NgramIndex(keys, ngramSize: params.ngramSize);
      _vocabularies[n.id] = _Vocabulary(keys);
    }
  }

  final List<Word> _words;
  final Map<WordKey, int> _positions = {};
  final Map<NormalizerId, List<SearchKey>> _keys = {};
  final Map<NormalizerId, NgramIndex> _indexes = {};
  final Map<NormalizerId, _Vocabulary> _vocabularies = {};

  /// All loaded words in reading order.
  List<Word> get words => _words;

  @override
  bool contains(WordKey key) => _positions.containsKey(key);

  @override
  Word word(WordKey key) => _words[_position(key)];

  @override
  List<Word> range(WordKey from, WordKey to) {
    final start = _position(from);
    final end = _position(to);
    if (end < start) {
      throw ArgumentError.value(to, 'to', 'is before $from');
    }
    return _words.sublist(start, end + 1);
  }

  @override
  SearchKey searchKey(WordKey key, NormalizerId normalizer) =>
      _keysOf(normalizer)[_position(key)];

  /// Keys of all words for [normalizer], in reading order.
  List<SearchKey> keysFor(NormalizerId normalizer) => _keysOf(normalizer);

  @override
  List<SequenceMatch> findSequence(
    List<SearchKey> keys, {
    required NormalizerId normalizer,
    int maxResults = 10,
  }) {
    final index = _indexes[normalizer];
    if (index == null) {
      throw ArgumentError.value(normalizer, 'normalizer', 'unknown');
    }
    return [
      for (final hit in index.find(keys, maxResults: maxResults))
        SequenceMatch(
          start: _words[hit.start].key,
          matchedNgrams: hit.matchedNgrams,
        ),
    ];
  }

  @override
  List<SimilarMatch> findSimilar(
    List<SearchKey> keys, {
    required NormalizerId normalizer,
    required double minSimilarity,
    required double maxMeanCost,
    int maxResults = 10,
  }) {
    final vocabulary = _vocabularies[normalizer];
    final all = _keys[normalizer];
    if (vocabulary == null || all == null) {
      throw ArgumentError.value(normalizer, 'normalizer', 'unknown');
    }
    final m = keys.length;
    if (m == 0 || maxResults <= 0) return const [];

    // Similar distinct keys for every searched word.
    final similar = [
      for (final k in keys) vocabulary.similarTo(k.value, minSimilarity),
    ];
    if (similar.any((s) => s.isEmpty)) return const [];

    // Start from the word with the fewest places in the text.
    var anchor = 0;
    var fewest = vocabulary.placeCount(similar[0].keys);
    for (var t = 1; t < m; t++) {
      final count = vocabulary.placeCount(similar[t].keys);
      if (count < fewest) {
        fewest = count;
        anchor = t;
      }
    }

    final matches = <SimilarMatch>[];
    final seen = <int>{};
    for (final key in similar[anchor].keys) {
      for (final p in vocabulary.places(key)) {
        final start = p - anchor;
        if (start < 0 || start + m > all.length || !seen.add(start)) continue;
        var sum = 0.0;
        var fits = true;
        for (var t = 0; t < m && fits; t++) {
          final sim = similar[t][all[start + t].value];
          if (sim == null) {
            fits = false;
          } else {
            sum += 1 - sim;
          }
        }
        if (fits && sum / m <= maxMeanCost) {
          matches.add(
            SimilarMatch(start: _words[start].key, meanCost: sum / m),
          );
        }
      }
    }
    matches.sort((a, b) {
      final byCost = a.meanCost.compareTo(b.meanCost);
      return byCost != 0 ? byCost : a.start.compareTo(b.start);
    });
    return matches.take(maxResults).toList();
  }

  int _position(WordKey key) {
    final position = _positions[key];
    if (position == null) {
      throw ArgumentError.value(key, 'key', 'not in the loaded text');
    }
    return position;
  }

  List<SearchKey> _keysOf(NormalizerId normalizer) {
    final keys = _keys[normalizer];
    if (keys == null) {
      throw ArgumentError.value(normalizer, 'normalizer', 'unknown');
    }
    return keys;
  }
}

/// Distinct keys of a text with their places, bucketed by length so that a
/// similarity search skips keys whose length alone rules them out, and
/// compares the rest with a distance bound.
final class _Vocabulary {
  _Vocabulary(List<SearchKey> keys) {
    for (var i = 0; i < keys.length; i++) {
      (_places[keys[i].value] ??= []).add(i);
    }
    for (final key in _places.keys) {
      final runes = key.runes.toList();
      (_byLength[runes.length] ??= []).add((key, runes));
    }
  }

  final Map<String, List<int>> _places = {};
  final Map<int, List<(String, List<int>)>> _byLength = {};

  /// Places of [key] in reading order.
  List<int> places(String key) => _places[key] ?? const [];

  /// Total places of [keys].
  int placeCount(Iterable<String> keys) =>
      keys.fold(0, (n, k) => n + places(k).length);

  /// Distinct keys with similarity of at least [minSimilarity] to [key],
  /// with that similarity.
  ///
  /// similarity = 1 − distance / longer ≥ min means distance ≤
  /// (1 − min) × longer: lengths further apart than that are skipped, and
  /// each comparison stops as soon as the distance is known to exceed it.
  Map<String, double> similarTo(String key, double minSimilarity) {
    final runes = key.runes.toList();
    final length = runes.length;
    final result = <String, double>{};
    for (final MapEntry(key: other, value: bucket) in _byLength.entries) {
      final longer = other > length ? other : length;
      final maxDistance = ((1 - minSimilarity) * longer).floor();
      if ((other - length).abs() > maxDistance) continue;
      for (final (candidate, candidateRunes) in bucket) {
        final d = boundedLevenshtein(runes, candidateRunes, maxDistance);
        if (d == null) continue;
        final s = longer == 0 ? 1.0 : 1 - d / longer;
        if (s >= minSimilarity) result[candidate] = s;
      }
    }
    return result;
  }
}
