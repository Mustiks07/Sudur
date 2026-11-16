import 'package:contracts/contracts.dart';
import 'package:quran_text/src/ngram_index.dart';
import 'package:quran_text/src/normalizer.dart';
import 'package:quran_text/src/quran_text.dart';
import 'package:quran_text/src/search_key.dart';
import 'package:quran_text/src/search_params.dart';
import 'package:quran_text/src/word.dart';

/// [QuranText] over words held in memory, with keys and an n-gram index
/// built once per normalizer.
///
/// The words are not copied or changed: keys live in separate lists.
final class InMemoryQuranText implements QuranText {
  /// Creates the text from [words] in reading order, building keys for each
  /// of [normalizers].
  InMemoryQuranText({
    required List<Word> words,
    required List<Normalizer> normalizers,
    required SearchParams params,
  }) : _words = List.unmodifiable(words) {
    for (var i = 0; i < _words.length; i++) {
      if (i > 0 && _words[i - 1].key.compareTo(_words[i].key) >= 0) {
        throw ArgumentError.value(_words[i].key, 'words', 'not in order');
      }
      _positions[_words[i].key] = i;
    }
    for (final n in normalizers) {
      final keys = List<SearchKey>.unmodifiable(
        _words.map((w) => n.keyOf(w.text)),
      );
      _keys[n.id] = keys;
      _indexes[n.id] = NgramIndex(keys, ngramSize: params.ngramSize);
    }
  }

  final List<Word> _words;
  final Map<WordKey, int> _positions = {};
  final Map<NormalizerId, List<SearchKey>> _keys = {};
  final Map<NormalizerId, NgramIndex> _indexes = {};

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
