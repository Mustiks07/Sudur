import 'package:check/src/check_params.dart';
import 'package:check/src/check_state_machine.dart';
import 'package:check/src/check_types.dart';
import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';

/// Finds reading mistakes on the alignment path of `follow` and keeps their
/// states (docs/tz 10.5, ПО-01…ПО-13).
///
/// Feed the final path of `follow` to [accept], pauses to [onPause], unreliable
/// audio to [markUnreliable], and call [finish] at the end of the session.
/// Each call returns new events and state changes; a state change is a new
/// `CheckEvent` with the same `eventId`. The recognized text in an event is
/// always as recognized (ПО-13).
final class Checker {
  /// Creates a checker for the passage [from]..[to] of [text].
  ///
  /// [normalizer] must be the one `follow` used. With [strict], confirmed
  /// omissions and substitutions make the session wait for the word
  /// (docs/tz ЭЧ-05).
  Checker({
    required QuranText text,
    required NormalizerId normalizer,
    required WordKey from,
    required WordKey to,
    required CheckParams params,
    required String sessionId,
    required ReadingVersions versions,
    bool strict = false,
  })  : _text = text,
        _normalizer = normalizer,
        _params = params,
        _sessionId = sessionId,
        _versions = versions,
        _strict = strict,
        _passage = text.range(from, to) {
    for (var i = 0; i < _passage.length; i++) {
      _index[_passage[i].key] = i;
    }
  }

  final QuranText _text;
  final NormalizerId _normalizer;
  final CheckParams _params;
  final String _sessionId;
  final ReadingVersions _versions;
  final bool _strict;
  final List<Word> _passage;
  final Map<WordKey, int> _index = {};

  int _nextPos = 0;
  int _lastHeardMs = 0;
  int _lastHeardIndex = -1;

  /// Heard index of the last word matched in the passage.
  int _lastMatchHeard = -1;
  AlignmentStep? _pendingInsert;
  int _ids = 0;
  final List<_Candidate> _open = [];
  final Map<String, _Candidate> _all = {};
  final List<UnreliableSpan> _unreliable = [];
  final List<int> _pauses = [];
  int? _poorSignalSinceMs;

  int? _waitPos;
  int _waitStartMs = 0;
  int _waitFails = 0;
  bool _hintOffered = false;

  /// Processes new final steps of the alignment path and jump candidates,
  /// as `follow` produced them for one recognition result.
  CheckUpdate accept({
    required List<AlignmentStep> path,
    List<JumpCandidate> jumps = const [],
  }) {
    final out = _Output();
    for (final step in path) {
      _onStep(step, out);
    }
    for (final jump in jumps) {
      _onJump(jump, out);
    }
    _resolveReady(out);
    _checkWaitTime(_lastHeardMs, out);
    return out.build();
  }

  /// A pause between words; a long pause inside an ayah is a hesitation
  /// signal, not a mistake (docs/tz 10.5).
  CheckUpdate onPause(SpeechPause pause) {
    final out = _Output();
    final duration = pause.durationMs;
    final inside = _nextPos > 0 &&
        _nextPos < _passage.length &&
        _sameAyah(_passage[_nextPos - 1].key, _passage[_nextPos].key);
    final median = _median(_pauses);
    if (inside &&
        duration > _params.hesitationPauseMs &&
        (median == null || duration > _params.hesitationTempoFactor * median)) {
      _signal(
        CheckKind.hesitation,
        [_nextPos],
        heard: '',
        startMs: pause.startMs,
        endMs: pause.endMs,
        out: out,
      );
    }
    _pauses.add(duration);
    return out.build();
  }

  /// Audio in [span] cannot be trusted: open candidates there become
  /// `unverified`, and later ones there are never confirmed.
  CheckUpdate markUnreliable(UnreliableSpan span) {
    final out = _Output(atMs: span.endMs);
    _markUnreliable(span, out);
    return out.build();
  }

  void _markUnreliable(UnreliableSpan span, _Output out) {
    _unreliable.add(span);
    for (final c in List.of(_open)) {
      if (span.overlaps(c.startMs, c.endMs)) {
        _move(c, CheckState.unverified, out);
      }
    }
  }

  /// The signal level changed (docs/tz 4.5, 10.5). From a level other
  /// than `ok` until the next `ok`, audio is unreliable: candidates there
  /// become `unverified`. The bad stretch starts at `sinceMs` if given.
  CheckUpdate onSignalQuality(SignalQuality quality) {
    final out = _Output(atMs: quality.atMs);
    final start = _poorSignalSinceMs;
    if (quality.level == SignalQualityLevel.ok) {
      if (start != null) {
        _poorSignalSinceMs = null;
        _markUnreliable(
          UnreliableSpan(
            startMs: start,
            endMs: quality.atMs,
            reason: UnreliableReason.poorSignal,
          ),
          out,
        );
      }
    } else if (start == null) {
      _poorSignalSinceMs = quality.sinceMs ?? quality.atMs;
    }
    return out.build();
  }

  /// Time passed without words: closes self-correction windows and may
  /// offer a hint in strict mode.
  CheckUpdate tick(int atMs) {
    final out = _Output(atMs: atMs);
    _resolveReady(out, nowMs: atMs);
    _checkWaitTime(atMs, out);
    return out.build();
  }

  /// The reader took a hint for [word].
  CheckUpdate onHint(WordKey word, int atMs) {
    final out = _Output(atMs: atMs);
    if (_waitPos != null && _passage[_waitPos!].key == word) {
      out.strict.add(StopWaiting(word: word, atMs: atMs, how: WaitEnd.hint));
      _waitPos = null;
    } // Checked for null in the condition.
    return out.build();
  }

  /// The reader disagrees with event [eventId] (docs/tz РБ-03): a confirmed
  /// mistake becomes `disputed`. Any other state is refused.
  Result<CheckUpdate> dispute(String eventId, int atMs) {
    final c = _all[eventId];
    if (c == null) {
      return Result.error(CheckTransitionException('Unknown event $eventId'));
    }
    if (!canMove(c.state, CheckState.disputed)) {
      return Result.error(
        CheckTransitionException(
          'Event $eventId is ${c.state.name}; only confirmed can be disputed',
        ),
      );
    }
    final out = _Output(atMs: atMs);
    _move(c, CheckState.disputed, out);
    return Result.ok(out.build());
  }

  /// End of the session: candidates without enough context become
  /// `unverified` (docs/tz 10.5).
  CheckUpdate finish(int atMs) {
    final out = _Output(atMs: atMs);
    _flushInsert(out);
    for (final c in List.of(_open)) {
      _move(c, CheckState.unverified, out);
    }
    return out.build();
  }

  // --- Steps -------------------------------------------------------------

  void _onStep(AlignmentStep step, _Output out) {
    final heard = step.heard;
    out.atMs = heard.atMs;
    switch (step.kind) {
      case AlignmentStepKind.insert:
        _flushInsert(out);
        _pendingInsert = step;
        _resetContext();
        _strictTry(matchedPos: null, strong: false, out: out);
      case AlignmentStepKind.unaligned:
        _flushInsert(out);
        _resetContext();
      case AlignmentStepKind.skip:
        final skipped = [for (final k in step.skipped) _pos(k)];
        final insert = _pendingInsert;
        _pendingInsert = null;
        var omitted = skipped;
        if (insert != null && skipped.isNotEmpty && skipped.first == _nextPos) {
          // An extra word right where a word was skipped: the reader said
          // another word instead of it.
          _create(
            CheckKind.substitution,
            [skipped.first],
            heard: insert.heard.text,
            startMs: insert.heard.atMs,
            endMs: insert.heard.atMs,
            createdHeard: insert.heard.index,
            out: out,
          );
          omitted = skipped.sublist(1);
        } else if (insert != null) {
          _insertion(insert, out);
        }
        for (final p in omitted) {
          _create(
            CheckKind.omission,
            [p],
            heard: '',
            startMs: _lastHeardMs,
            endMs: heard.atMs,
            createdHeard: heard.index,
            out: out,
          );
        }
        _onMatch(step, out, isBack: false);
      case AlignmentStepKind.match:
        _flushInsert(out, next: step);
        _onMatch(step, out, isBack: false);
      case AlignmentStepKind.back:
        _flushInsert(out);
        final pos = _pos(step.expected!); // Back steps always have one.
        final end = _nextPos > pos ? _nextPos : pos + 1;
        _signal(
          CheckKind.repetition,
          [for (var p = pos; p < end && p < _passage.length; p++) p],
          heard: heard.text,
          startMs: heard.atMs,
          endMs: heard.atMs,
          out: out,
        );
        _onMatch(step, out, isBack: true);
    }
    _lastHeardMs = heard.atMs;
    _lastHeardIndex = heard.index;
    _resolveReady(out);
  }

  void _onMatch(AlignmentStep step, _Output out, {required bool isBack}) {
    _lastMatchHeard = step.heard.index;
    final pos = _pos(step.expected!); // Match, skip and back have one.
    final sim = step.similarity ?? 0;
    final heard = step.heard;
    final strong = sim >= _params.strongMatch;

    if (strong) {
      for (final c in List.of(_open)) {
        if ((c.kind == CheckKind.omission ||
                c.kind == CheckKind.substitution) &&
            c.positions.contains(pos) &&
            c.createdHeard < heard.index &&
            _windowOpen(c, heard.index, heard.atMs)) {
          _move(c, CheckState.corrected, out);
        }
      }
    }
    _strictTry(matchedPos: pos, strong: strong, out: out);

    if (isBack) {
      if (!strong) _resetContext();
    } else if (strong) {
      for (final c in _open) {
        c.context++;
      }
    } else {
      _resetContext();
      _create(
        CheckKind.substitution,
        [pos],
        heard: heard.text,
        startMs: heard.atMs,
        endMs: heard.atMs,
        createdHeard: heard.index,
        medium: sim >= _params.substitutionMax,
        out: out,
      );
    }
    _nextPos = pos + 1;
  }

  void _onJump(JumpCandidate jump, _Output out) {
    if (jump.matchedNgrams < 1 || jump.heard.length < _params.jumpMinWords) {
      return;
    }
    // Words heard after the last word read in the passage and before the
    // words that showed the jump are the start of the reading elsewhere,
    // not extra words: an extra-word candidate there would report the same
    // place twice. With real model output (bare letters) the first words
    // of a jump are often short and common, so the jump is seen a few
    // words late (found with model-output tests, docs/tz 12.3).
    final start = jump.heard.first.index;
    bool partOfJump(int heardIndex) =>
        heardIndex > _lastMatchHeard && heardIndex < start;
    if (_pendingInsert case final pending?
        when partOfJump(pending.heard.index)) {
      _pendingInsert = null;
    }
    for (final open in List.of(_open)) {
      if (open.kind == CheckKind.insertion && partOfJump(open.createdHeard)) {
        _move(open, CheckState.unverified, out);
      }
    }
    final from = jump.from;
    final c = _create(
      CheckKind.jump,
      [if (from != null && _index.containsKey(from)) _index[from]!],
      heard: [for (final h in jump.heard) h.text].join(' '),
      startMs: jump.heard.first.atMs,
      endMs: jump.heard.last.atMs,
      createdHeard: jump.heard.last.index,
      jumpTo: jump.to,
      out: out,
    ); // Key checked by containsKey.
    // Decided at once: jumpMinWords words matched there in a row. On
    // unreliable audio (bad signal, deviceTooSlow) it is not confirmed.
    _move(
      c,
      _isUnreliable(c) ? CheckState.unverified : CheckState.confirmed,
      out,
    );
  }

  void _flushInsert(_Output out, {AlignmentStep? next}) {
    final insert = _pendingInsert;
    if (insert == null) return;
    _pendingInsert = null;
    if (next != null && _skippedThenCorrected(insert, next, out)) return;
    _insertion(insert, out);
  }

  /// The reader skipped the expected word, said the word after it, and at
  /// once went back to the skipped word. `follow` sees an extra word that
  /// equals the word after the expected one, then a match of the expected
  /// word: this is an omission corrected by the reader (docs/tz ПО-05).
  bool _skippedThenCorrected(
    AlignmentStep insert,
    AlignmentStep next,
    _Output out,
  ) {
    final ahead = _nextPos + 1;
    if (ahead >= _passage.length ||
        next.kind != AlignmentStepKind.match ||
        next.expected != _passage[_nextPos].key ||
        (next.similarity ?? 0) < _params.strongMatch ||
        !_matches(insert.heard, ahead)) {
      return false;
    }
    _create(
      CheckKind.omission,
      [_nextPos],
      heard: '',
      startMs: _lastHeardMs,
      endMs: insert.heard.atMs,
      createdHeard: insert.heard.index,
      out: out,
    ); // Corrected by the match that follows (self-correction rule).
    return true;
  }

  bool _matches(HeardWord heard, int pos) =>
      similarity(
        heard.key.value,
        _text.searchKey(_passage[pos].key, _normalizer).value,
      ) >=
      _params.strongMatch;

  /// An extra word: a repetition if it matches a neighboring expected word,
  /// otherwise an insertion candidate (docs/tz 10.5).
  void _insertion(AlignmentStep insert, _Output out) {
    final heard = insert.heard;
    final neighbors = [
      for (final p in [_nextPos - 1, _nextPos])
        if (p >= 0 && p < _passage.length) p,
    ];
    final repeats = neighbors.where((p) => _matches(heard, p));
    if (repeats.isNotEmpty) {
      _signal(
        CheckKind.repetition,
        [repeats.first],
        heard: heard.text,
        startMs: heard.atMs,
        endMs: heard.atMs,
        out: out,
      );
      return;
    }
    _create(
      CheckKind.insertion,
      [if (neighbors.isNotEmpty) neighbors.last],
      heard: heard.text,
      startMs: heard.atMs,
      endMs: heard.atMs,
      createdHeard: heard.index,
      out: out,
    );
  }

  // --- Candidates --------------------------------------------------------

  _Candidate _create(
    CheckKind kind,
    List<int> positions, {
    required String heard,
    required int startMs,
    required int endMs,
    required int createdHeard,
    required _Output out,
    bool medium = false,
    WordKey? jumpTo,
  }) {
    final c = _Candidate(
      id: '$_sessionId-c${_ids++}',
      kind: kind,
      positions: positions,
      heard: heard,
      startMs: startMs,
      endMs: endMs,
      createdHeard: createdHeard,
      createdMs: endMs,
      medium: medium,
      jumpTo: jumpTo,
    );
    _all[c.id] = c;
    _open.add(c);
    _emit(c, out);
    return c;
  }

  /// Signals (repetition, hesitation) are not mistakes and have no life
  /// cycle: they are emitted once, as `confirmed` observations.
  void _signal(
    CheckKind kind,
    List<int> positions, {
    required String heard,
    required int startMs,
    required int endMs,
    required _Output out,
  }) {
    final c = _Candidate(
      id: '$_sessionId-c${_ids++}',
      kind: kind,
      positions: positions,
      heard: heard,
      startMs: startMs,
      endMs: endMs,
      createdHeard: _lastHeardIndex,
      createdMs: endMs,
      state: CheckState.confirmed,
    );
    _all[c.id] = c;
    _emit(c, out);
  }

  void _move(_Candidate c, CheckState to, _Output out) {
    if (!canMove(c.state, to)) {
      throw StateError('Forbidden ${c.state.name} → ${to.name} for ${c.id}');
    }
    c.state = to;
    if (to != CheckState.preliminary) _open.remove(c);
    _emit(c, out);
    if (to == CheckState.confirmed &&
        _strict &&
        _waitPos == null &&
        (c.kind == CheckKind.omission || c.kind == CheckKind.substitution) &&
        c.positions.isNotEmpty) {
      _waitPos = c.positions.first;
      _waitStartMs = out.atMs;
      _waitFails = 0;
      _hintOffered = false;
      out.strict.add(
        WaitForWord(word: _passage[c.positions.first].key, atMs: out.atMs),
      );
    }
  }

  /// Confirms (or leaves unverified) candidates with enough context whose
  /// self-correction window is closed.
  void _resolveReady(_Output out, {int? nowMs}) {
    final now = nowMs ?? _lastHeardMs;
    for (final c in List.of(_open)) {
      if (c.context < _params.confirmContextWords) continue;
      if (_windowOpen(c, _lastHeardIndex, now)) continue;
      _move(
        c,
        c.medium || _isUnreliable(c)
            ? CheckState.unverified
            : CheckState.confirmed,
        out,
      );
    }
  }

  /// Whether [c]'s audio overlaps a stretch that cannot be trusted
  /// (docs/tz 10.5 «Плохой сигнал»): no candidate there is confirmed.
  /// An open stretch of poor signal (no `ok` yet) counts too.
  bool _isUnreliable(_Candidate c) {
    final poorSince = _poorSignalSinceMs;
    return _unreliable.any((s) => s.overlaps(c.startMs, c.endMs)) ||
        (poorSince != null && c.endMs >= poorSince);
  }

  /// The self-correction window is open while neither
  /// `selfCorrectionWords` heard words nor `selfCorrectionMs` have passed.
  bool _windowOpen(_Candidate c, int heardIndex, int atMs) =>
      heardIndex - c.createdHeard <= _params.selfCorrectionWords &&
      atMs - c.createdMs <= _params.selfCorrectionMs;

  void _resetContext() {
    for (final c in _open) {
      c.context = 0;
    }
  }

  // --- Strict behavior ----------------------------------------------------

  void _strictTry({
    required int? matchedPos,
    required bool strong,
    required _Output out,
  }) {
    final wait = _waitPos;
    if (wait == null) return;
    if (strong && matchedPos == wait) {
      out.strict.add(
        StopWaiting(
          word: _passage[wait].key,
          atMs: out.atMs,
          how: WaitEnd.read,
        ),
      );
      _waitPos = null;
      return;
    }
    _waitFails++;
    if (_waitFails >= _params.strictMaxFails) _offerHint(out);
  }

  void _checkWaitTime(int atMs, _Output out) {
    if (_waitPos == null) return;
    if (atMs - _waitStartMs >= _params.strictMaxWaitMs) _offerHint(out);
  }

  void _offerHint(_Output out) {
    final wait = _waitPos;
    if (wait == null || _hintOffered) return;
    _hintOffered = true;
    out.strict.add(OfferHint(word: _passage[wait].key, atMs: out.atMs));
  }

  // --- Helpers -------------------------------------------------------------

  void _emit(_Candidate c, _Output out) {
    out.events.add(
      CheckEvent(
        sessionId: _sessionId,
        atMs: out.atMs,
        eventId: c.id,
        kind: c.kind,
        state: c.state,
        words: [for (final p in c.positions) _passage[p].key],
        expectedText: [for (final p in c.positions) _passage[p].text].join(' '),
        heardText: c.heard,
        audioStartMs: c.startMs,
        audioEndMs: c.endMs,
        jumpTo: c.jumpTo,
        versions: _versions,
      ),
    );
  }

  int _pos(WordKey key) {
    final p = _index[key];
    if (p == null) {
      throw ArgumentError.value(key, 'key', 'not in the passage');
    }
    return p;
  }

  static bool _sameAyah(WordKey a, WordKey b) =>
      a.surah == b.surah && a.ayah == b.ayah;

  static double? _median(List<int> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid].toDouble()
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}

final class _Candidate {
  _Candidate({
    required this.id,
    required this.kind,
    required this.positions,
    required this.heard,
    required this.startMs,
    required this.endMs,
    required this.createdHeard,
    required this.createdMs,
    this.medium = false,
    this.jumpTo,
    this.state = CheckState.preliminary,
  });

  final String id;
  final CheckKind kind;
  final List<int> positions;
  final String heard;
  final int startMs;
  final int endMs;
  final int createdHeard;
  final int createdMs;

  /// Similarity between `substitutionMax` and `strongMatch`: never a
  /// confirmed mistake, only "could not verify" (docs/tz 10.5).
  final bool medium;
  final WordKey? jumpTo;
  CheckState state;

  /// Strong forward matches since creation, reset by a weak step.
  int context = 0;
}

final class _Output {
  _Output({this.atMs = 0});

  int atMs;
  final List<CheckEvent> events = [];
  final List<StrictSignal> strict = [];

  CheckUpdate build() => CheckUpdate(
        events: List.unmodifiable(events),
        strict: List.unmodifiable(strict),
      );
}
