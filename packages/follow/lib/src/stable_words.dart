import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';

/// A recognized token with its search key.
typedef Token = ({String text, SearchKey key});

/// Turns partial and final recognition results into new stable words
/// (docs/tz СЛ-08, 10.4 «Устойчивая часть»).
///
/// A word of a partial result is stable when the last
/// `stableConfirmations` partial results of the segment agree on it; every
/// word of the final result is stable. Each stable word is returned once.
///
/// Partial results of a long segment may cover only its end (docs/tz 10.3).
/// Such results are stitched to the words already taken by their overlap.
final class StableWords {
  /// Creates a tracker.
  StableWords({required Normalizer normalizer, required int confirmations})
      : _normalizer = normalizer,
        _confirmations = confirmations;

  final Normalizer _normalizer;
  final int _confirmations;

  int? _segmentId;
  int _segmentStartMs = 0;
  bool _segmentClosed = false;
  final List<Token> _taken = [];
  final List<({List<Token> tokens, int startMs})> _partials = [];

  /// Returns tokens of [result] that became stable and were not returned
  /// before.
  List<Token> accept(RecognitionResult result) {
    if (result.segmentId != _segmentId) {
      _segmentId = result.segmentId;
      _segmentStartMs = result.audioStartMs;
      _segmentClosed = false;
      _taken.clear();
      _partials.clear();
    }
    if (_segmentClosed) return const [];

    final tokens = tokenize(result.text);
    final slid = result.audioStartMs > _segmentStartMs;
    if (result.isFinal) {
      _segmentClosed = true;
      return _take(tokens, slid: slid);
    }

    _partials.add((tokens: tokens, startMs: result.audioStartMs));
    if (_partials.length > _confirmations) _partials.removeAt(0);
    if (_partials.length < _confirmations) return const [];

    var stableLength = tokens.length;
    for (final other in _partials.take(_partials.length - 1)) {
      final agreed = _agreedPrefix(
        other.tokens,
        tokens,
        sameWindow: other.startMs == result.audioStartMs,
      );
      if (agreed < stableLength) stableLength = agreed;
    }
    return _take(tokens.sublist(0, stableLength), slid: slid);
  }

  /// Splits recognized text by the model's separator, keeping each
  /// non-empty token as recognized next to its key.
  List<Token> tokenize(String text) => [
        for (final part in text.split(_normalizer.wordSeparator))
          if (_normalizer.keyOf(part) case final key when !key.isEmpty)
            (text: part, key: key),
      ];

  List<Token> _take(List<Token> stable, {required bool slid}) {
    final start = slid ? _overlapEnd(stable) : _taken.length;
    if (start >= stable.length) return const [];
    final fresh = stable.sublist(start);
    _taken.addAll(fresh);
    return fresh;
  }

  /// Index in [stable] right after the longest tail of the taken words that
  /// starts [stable]. With no overlap at all every word is new.
  int _overlapEnd(List<Token> stable) {
    final longest =
        _taken.length < stable.length ? _taken.length : stable.length;
    for (var k = longest; k > 0; k--) {
      var same = true;
      for (var t = 0; t < k && same; t++) {
        same = _taken[_taken.length - k + t].key == stable[t].key;
      }
      if (same) return k;
    }
    return 0;
  }

  /// Number of leading words of [current] that [previous] also has. For
  /// results of the same audio window this is the common prefix; when the
  /// window slid, the start of [current] is first aligned somewhere inside
  /// [previous], because the window dropped words at the front.
  static int _agreedPrefix(
    List<Token> previous,
    List<Token> current, {
    required bool sameWindow,
  }) {
    var best = 0;
    final offsets = sameWindow ? 1 : previous.length;
    for (var offset = 0; offset < offsets; offset++) {
      var n = 0;
      while (offset + n < previous.length &&
          n < current.length &&
          previous[offset + n].key == current[n].key) {
        n++;
      }
      if (n > best) best = n;
    }
    return best;
  }
}
