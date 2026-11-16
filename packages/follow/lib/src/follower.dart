import 'package:contracts/contracts.dart';
import 'package:follow/src/alignment.dart';
import 'package:follow/src/follow_params.dart';
import 'package:follow/src/stable_words.dart';
import 'package:quran_text/quran_text.dart';

/// Follows the reader through a passage (docs/tz section 10.4).
///
/// Feed recognition results with [accept]; each call returns the events,
/// the alignment steps that became final and jump candidates. Works on
/// saved results without a phone (docs/tz СЛ-07).
///
/// The beam holds up to `beamSize` hypotheses about the position. A step
/// becomes final when every hypothesis agrees on it, or when
/// `openDelayWords` more stable words were heard and the place is not
/// ambiguous, or at the end of a speech segment. Final steps are never
/// undone: hypotheses that disagree are dropped. A word is revealed only
/// from a final match with similarity of at least `openThreshold`, so no
/// revealed word is ever taken back (docs/tz СЛ-08).
final class Follower {
  /// Creates a follower for the passage [from]..[to] of [text].
  ///
  /// [text] must have keys for [normalizer]. The reader is expected to start
  /// at [from] but may start anywhere (docs/tz СЛ-03).
  Follower({
    required QuranText text,
    required Normalizer normalizer,
    required WordKey from,
    required WordKey to,
    required FollowParams params,
  })  : _text = text,
        _normalizer = normalizer,
        _params = params,
        _passage = text.range(from, to),
        _stable = StableWords(
          normalizer: normalizer,
          confirmations: params.stableConfirmations,
        ) {
    _keys = [for (final w in _passage) text.searchKey(w.key, normalizer.id)];
  }

  final QuranText _text;
  final Normalizer _normalizer;
  final FollowParams _params;
  final List<Word> _passage;
  late final List<SearchKey> _keys;
  final StableWords _stable;

  final List<HeardWord> _heard = [];
  List<_Hypothesis> _beam = [const _Hypothesis(pos: 0, cost: 0)];
  bool _searching = false;

  _Node? _committed;
  int _committedHeard = -1;
  final Set<int> _revealed = {};
  WordKey? _lastConfident;

  int? _reportedPos;
  List<int> _reportedCandidates = const [];
  ({int wordIndex, int heardIndex})? _lastJump;

  /// Words of the passage, in order.
  List<Word> get passage => _passage;

  /// Processes one recognition result.
  FollowUpdate accept(RecognitionResult result) {
    final out = _Output(result.sessionId, result.audioEndMs);
    for (final token in _stable.accept(result)) {
      final heard = HeardWord(
        index: _heard.length,
        text: token.text,
        key: token.key,
        segmentId: result.segmentId,
        atMs: result.audioEndMs,
      );
      _heard.add(heard);
      _onWord(heard, out);
    }
    if (result.isFinal && !_searching) {
      final ambiguous = _ambiguousPositions().isNotEmpty;
      if (!ambiguous) _commit(out, flush: true);
    }
    return out.build();
  }

  /// Ends the session (docs/tz 10.6, `finishing`): no more words will come,
  /// so the rest of the best path becomes final unless the place is
  /// ambiguous. Words heard while the position was lost stay unaligned.
  FollowUpdate finish({required String sessionId, required int atMs}) {
    final out = _Output(sessionId, atMs);
    if (!_searching && _ambiguousPositions().isEmpty) {
      _commit(out, flush: true, finishing: true);
    }
    return out.build();
  }

  /// Applies [accept] to a stream, dropping empty updates.
  Stream<FollowUpdate> bind(Stream<RecognitionResult> results) =>
      results.map(accept).where((u) => !u.isEmpty);

  void _onWord(HeardWord heard, _Output out) {
    if (_searching) {
      _search(out);
      return;
    }
    _beam = _expand(heard);
    if (_isLost()) {
      _searching = true;
      _beam = const [];
      _reportedPos = null;
      _reportedCandidates = const [];
      if (_lastConfident != null) {
        out.events.add(
          PositionLost(
            sessionId: out.sessionId,
            atMs: out.atMs,
            lastConfidentWord: _lastConfident,
          ),
        );
      }
      _search(out);
      return;
    }
    _afterStep(out);
  }

  void _afterStep(_Output out) {
    final candidates = _ambiguousPositions();
    _reportPosition(candidates, out);
    _commit(out, flush: false, ambiguous: candidates.isNotEmpty);
  }

  // Beam expansion (docs/tz 10.4 table of transitions).
  List<_Hypothesis> _expand(HeardWord heard) {
    final p = _params;
    final next = <int, _Hypothesis>{};
    void add(
      _Hypothesis from,
      int pos,
      double cost,
      AlignmentStep step,
      int? expectedPos,
    ) {
      final candidate = _Hypothesis(
        pos: pos,
        cost: from.cost + cost,
        last: _Node(step: step, parent: from.last, expectedPos: expectedPos),
      );
      final known = next[pos];
      if (known == null || candidate.cost < known.cost) next[pos] = candidate;
    }

    for (final h in _beam) {
      final i = h.pos;
      if (i < _keys.length) {
        final s = similarity(heard.key.value, _keys[i].value);
        if (s >= p.simFloor) {
          add(
            h,
            i + 1,
            1 - s,
            _step(AlignmentStepKind.match, heard, 1 - s, i, s),
            i,
          );
        }
      }
      for (var k = 1; k <= p.maxSkip && i + k < _keys.length; k++) {
        final j = i + k;
        final s = similarity(heard.key.value, _keys[j].value);
        if (s < p.simFloor) continue;
        final cost = k * p.costSkip + 1 - s;
        add(
          h,
          j + 1,
          cost,
          _step(AlignmentStepKind.skip, heard, cost, j, s, skippedFrom: i),
          j,
        );
      }
      final backFrom = i - p.maxBack < 0 ? 0 : i - p.maxBack;
      for (var j = backFrom; j < i && j < _keys.length; j++) {
        final s = similarity(heard.key.value, _keys[j].value);
        if (s < p.simFloor) continue;
        final cost = p.costBack + 1 - s;
        add(
          h,
          j + 1,
          cost,
          _step(AlignmentStepKind.back, heard, cost, j, s),
          j,
        );
      }
      add(
        h,
        i,
        p.costInsert,
        AlignmentStep(
          kind: AlignmentStepKind.insert,
          heard: heard,
          cost: p.costInsert,
        ),
        null,
      );
    }
    final sorted = next.values.toList()..sort(_byCost);
    return sorted.take(p.beamSize).toList();
  }

  AlignmentStep _step(
    AlignmentStepKind kind,
    HeardWord heard,
    double cost,
    int expectedPos,
    double sim, {
    int? skippedFrom,
  }) =>
      AlignmentStep(
        kind: kind,
        heard: heard,
        cost: cost,
        expected: _passage[expectedPos].key,
        similarity: sim,
        skipped: skippedFrom == null
            ? const []
            : [
                for (var s = skippedFrom; s < expectedPos; s++) _passage[s].key,
              ],
      );

  bool _isLost() {
    if (_beam.isEmpty) return true;
    var sum = 0.0;
    var count = 0;
    for (var n = _beam.first.last;
        n != null && count < _params.lostWindowWords;
        n = n.parent) {
      sum += n.step.cost;
      count++;
    }
    return count > 0 && sum / count > _params.lostCostThreshold;
  }

  /// Positions of hypotheses that are another place of the passage (out of
  /// reach of a skip) but almost as cheap as the best (docs/tz СЛ-05).
  List<int> _ambiguousPositions() {
    if (_beam.isEmpty) return const [];
    final best = _beam.first;
    return [
      for (final h in _beam.skip(1))
        if ((h.pos - best.pos).abs() > _params.maxSkip &&
            h.cost - best.cost < _params.ambiguityMargin)
          h.pos,
    ];
  }

  void _reportPosition(List<int> candidates, _Output out) {
    final pos = _beam.first.pos;
    if (pos == 0) return;
    final ambiguous = candidates.isNotEmpty;
    final changed = pos != _reportedPos ||
        candidates.length != _reportedCandidates.length ||
        !candidates.every(_reportedCandidates.contains);
    if (!changed) return;
    _reportedPos = pos;
    _reportedCandidates = candidates;
    out.events.add(
      PositionUpdate(
        sessionId: out.sessionId,
        atMs: out.atMs,
        word: _passage[pos - 1].key,
        confidence:
            ambiguous ? PositionConfidence.low : PositionConfidence.high,
        candidates: [for (final c in candidates) _passage[c - 1].key],
      ),
    );
  }

  /// Makes steps final and reveals words (docs/tz 10.4 «Когда открывать»).
  void _commit(
    _Output out, {
    required bool flush,
    bool ambiguous = false,
    bool finishing = false,
  }) {
    if (_beam.isEmpty) return;
    final best = _beam.first;
    final lastHeard = _heard.length - 1;

    var target = _consensusHeard(best);
    if (!ambiguous) {
      final int delayed;
      if (finishing) {
        delayed = lastHeard;
      } else if (flush) {
        delayed = _confidentHeard(best);
      } else {
        delayed = lastHeard - _params.openDelayWords;
      }
      if (delayed > target) target = delayed;
    }
    if (target <= _committedHeard) return;

    final steps = <_Node>[];
    for (var n = best.last; n != null && n != _committed; n = n.parent) {
      if (n.step.heard.index <= target) steps.add(n);
    }
    for (final node in steps.reversed) {
      out.path.add(node.step);
      final pos = node.expectedPos;
      final sim = node.step.similarity;
      if (pos != null && sim != null && sim >= _params.openThreshold) {
        _lastConfident = _passage[pos].key;
        if (_revealed.add(pos)) {
          out.events.add(
            WordRevealed(
              sessionId: out.sessionId,
              atMs: out.atMs,
              word: _passage[pos].key,
              reason: RevealReason.heard,
            ),
          );
        }
      }
    }
    _committed = steps.first;
    _committedHeard = target;
    _beam = [
      for (final h in _beam)
        if (_contains(h, _committed)) h,
    ];
  }

  /// Heard index of the end of the confident part of [best]: the steps after
  /// the committed ones up to the first step that is not a plain forward
  /// match with similarity of at least `openThreshold` (a skip and a repeat
  /// can look alike until the next words). At the end of a segment only
  /// this part is made final; a doubtful tail waits for the next words.
  int _confidentHeard(_Hypothesis best) {
    final pending = <_Node>[];
    for (var n = best.last; n != null && n != _committed; n = n.parent) {
      pending.add(n);
    }
    var confident = _committedHeard;
    for (final n in pending.reversed) {
      final sim = n.step.similarity;
      if (n.step.kind != AlignmentStepKind.match ||
          sim == null ||
          sim < _params.openThreshold) {
        break;
      }
      confident = n.step.heard.index;
    }
    return confident;
  }

  /// Heard index of the newest step every hypothesis shares.
  int _consensusHeard(_Hypothesis best) {
    for (var n = best.last; n != null && n != _committed; n = n.parent) {
      if (_beam.every((h) => _contains(h, n))) return n.step.heard.index;
    }
    return _committedHeard;
  }

  static bool _contains(_Hypothesis h, _Node? node) {
    if (node == null) return true;
    var n = h.last;
    while (n != null && n.step.heard.index > node.step.heard.index) {
      n = n.parent;
    }
    return identical(n, node);
  }

  /// Lost position: search the passage, then the whole Quran
  /// (docs/tz 10.4 «Потеря позиции», СЛ-04).
  void _search(_Output out) {
    final p = _params;
    // Words that waited too long are given up as unaligned.
    while (_heard.length - 1 - _committedHeard > p.lostWindowWords) {
      final heard = _heard[_committedHeard + 1];
      _committed = _Node(
        step: AlignmentStep(
          kind: AlignmentStepKind.unaligned,
          heard: heard,
          cost: p.costInsert,
        ),
        parent: _committed,
        expectedPos: null,
      );
      _committedHeard++;
      out.path.add(_committed!.step); // Just assigned above.
    }
    final pending = _heard.sublist(_committedHeard + 1);
    if (pending.length < p.ngramSize) return;
    final window = pending.sublist(pending.length - p.ngramSize);

    final places = _scanPassage(window);
    if (places.isNotEmpty) {
      _anchor(pending, window, places);
      _searching = false;
      _afterStep(out);
      return;
    }

    final matches = _text.findSequence(
      [for (final w in window) w.key],
      normalizer: _normalizer.id,
      maxResults: p.beamSize,
    );
    final outside = matches.where(
      (m) =>
          m.start.compareTo(_passage.first.key) < 0 ||
          m.start.compareTo(_passage.last.key) > 0,
    );
    if (outside.isEmpty) return;
    final jump = outside.first;
    final wordIndex = _text.word(jump.start).index;
    final last = _lastJump;
    _lastJump = (wordIndex: wordIndex, heardIndex: window.first.index);
    if (last != null &&
        wordIndex - last.wordIndex == window.first.index - last.heardIndex) {
      return; // Still reading on at the place already reported.
    }
    out.jumps.add(
      JumpCandidate(
        from: _lastConfident,
        to: jump.start,
        heard: window,
        matchedNgrams: jump.matchedNgrams,
      ),
    );
  }

  /// Passage places where [window] fits word by word: (start, mean cost).
  List<(int, double)> _scanPassage(List<HeardWord> window) {
    final p = _params;
    final places = <(int, double)>[];
    for (var j = 0; j + window.length <= _keys.length; j++) {
      var sum = 0.0;
      var fits = true;
      for (var t = 0; t < window.length && fits; t++) {
        final s = similarity(window[t].key.value, _keys[j + t].value);
        fits = s >= p.simFloor;
        sum += 1 - s;
      }
      final mean = sum / window.length;
      if (fits && mean <= p.lostCostThreshold) places.add((j, mean));
    }
    places.sort((a, b) {
      final byCost = a.$2.compareTo(b.$2);
      return byCost != 0 ? byCost : a.$1.compareTo(b.$1);
    });
    return places.take(p.beamSize).toList();
  }

  void _anchor(
    List<HeardWord> pending,
    List<HeardWord> window,
    List<(int, double)> places,
  ) {
    var prefix = _committed;
    for (final heard in pending.take(pending.length - window.length)) {
      prefix = _Node(
        step: AlignmentStep(
          kind: AlignmentStepKind.unaligned,
          heard: heard,
          cost: _params.costInsert,
        ),
        parent: prefix,
        expectedPos: null,
      );
    }
    final beam = <_Hypothesis>[];
    for (final (start, _) in places) {
      var node = prefix;
      var cost = 0.0;
      for (var t = 0; t < window.length; t++) {
        final pos = start + t;
        final s = similarity(window[t].key.value, _keys[pos].value);
        cost += 1 - s;
        node = _Node(
          step: _step(AlignmentStepKind.match, window[t], 1 - s, pos, s),
          parent: node,
          expectedPos: pos,
        );
      }
      beam.add(_Hypothesis(pos: start + window.length, cost: cost, last: node));
    }
    _beam = beam..sort(_byCost);
  }

  /// Cheapest first; at equal cost the one further on, because the reader
  /// moves forward and a heard word that matched beats one taken as extra.
  static int _byCost(_Hypothesis a, _Hypothesis b) {
    final byCost = a.cost.compareTo(b.cost);
    return byCost != 0 ? byCost : b.pos.compareTo(a.pos);
  }
}

/// One step in a hypothesis' history; histories share their prefixes.
final class _Node {
  _Node({required this.step, required this.parent, required this.expectedPos});

  final AlignmentStep step;
  final _Node? parent;

  /// Passage index of the matched word, if any.
  final int? expectedPos;
}

/// A position hypothesis of the beam.
final class _Hypothesis {
  const _Hypothesis({required this.pos, required this.cost, this.last});

  /// Index of the next expected passage word.
  final int pos;

  /// Accumulated cost.
  final double cost;

  /// Newest step of the history.
  final _Node? last;
}

final class _Output {
  _Output(this.sessionId, this.atMs);

  final String sessionId;
  final int atMs;
  final List<SessionEvent> events = [];
  final List<AlignmentStep> path = [];
  final List<JumpCandidate> jumps = [];

  FollowUpdate build() => FollowUpdate(
        events: List.unmodifiable(events),
        path: List.unmodifiable(path),
        jumps: List.unmodifiable(jumps),
      );
}
