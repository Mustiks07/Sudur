import 'package:meta/meta.dart';
import 'package:quran_text/src/search_key.dart';

/// A candidate place for a searched sequence.
@immutable
final class IndexHit {
  /// Creates a hit.
  const IndexHit({required this.start, required this.matchedNgrams});

  /// Position in the indexed key list where the first searched key would
  /// stand.
  final int start;

  /// How many n-grams of the query matched at this alignment.
  final int matchedNgrams;
}

/// Index of [ngramSize] consecutive keys → positions (docs/tz section 10.1).
final class NgramIndex {
  /// Indexes [keys], a sequence of word keys in reading order.
  NgramIndex(List<SearchKey> keys, {required this.ngramSize})
      : assert(ngramSize > 0, 'ngramSize must be positive'),
        _length = keys.length {
    for (var i = 0; i + ngramSize <= keys.length; i++) {
      (_positions[_ngram(keys, i)] ??= []).add(i);
    }
  }

  /// Number of keys in one n-gram.
  final int ngramSize;

  final int _length;
  final Map<String, List<int>> _positions = {};

  /// Number of distinct n-grams.
  int get size => _positions.length;

  /// Places whose n-grams match [query], best first.
  ///
  /// Every n-gram of the query votes for the alignment where it occurs; the
  /// alignments with the most votes win, ties go to the earlier place. A
  /// query shorter than [ngramSize] finds nothing.
  List<IndexHit> find(List<SearchKey> query, {required int maxResults}) {
    final votes = <int, int>{};
    for (var offset = 0; offset + ngramSize <= query.length; offset++) {
      final positions = _positions[_ngram(query, offset)];
      if (positions == null) continue;
      for (final p in positions) {
        final start = p - offset;
        votes[start] = (votes[start] ?? 0) + 1;
      }
    }
    final hits = [
      for (final e in votes.entries)
        IndexHit(
          start: e.key.clamp(0, _length - 1),
          matchedNgrams: e.value,
        ),
    ]..sort((a, b) {
        final byVotes = b.matchedNgrams.compareTo(a.matchedNgrams);
        return byVotes != 0 ? byVotes : a.start.compareTo(b.start);
      });
    return hits.take(maxResults).toList();
  }

  // Keys never contain U+0000, so it safely joins them.
  String _ngram(List<SearchKey> keys, int from) => [
        for (var i = from; i < from + ngramSize; i++) keys[i].value,
      ].join('\u0000');
}
