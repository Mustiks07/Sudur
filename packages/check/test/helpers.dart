import 'dart:io';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:follow/follow.dart';
import 'package:quran_text/quran_text.dart';
import 'package:testing/testing.dart';

// Recognition results are built from the canon of surah 78 (P03 fixture):
// heard words are search keys of canonical words, with skips, repeats and
// letter distortions. No Arabic text is typed in tests.

const String fixturePath = '../testing/fixtures/content_p582_583.json';
const Normalizer normalizer = Normalizer.builtIn;
const CheckVersions versions = CheckVersions(
  modelId: 'fake/scripted',
  modelVersion: '0',
  rulesVersion: 'test',
  textVersion: 'fixture',
);

final InMemoryQuranText quran = () {
  final words = switch (ContentJsonSource(
    File(fixturePath).readAsStringSync(),
  ).loadWords()) {
    Ok(:final value) => value,
    Error(:final error) => throw error,
  };
  return InMemoryQuranText(
    words: words,
    normalizers: [normalizer],
    params: SearchParams.defaults,
  );
}();

/// Words of surah 78.
final List<Word> surah78 = [
  for (final w in quran.words)
    if (w.key.surah == 78) w,
];

List<Word> ayah(int surah, int number) => [
      for (final w in quran.words)
        if (w.key.surah == surah && w.key.ayah == number) w,
    ];

List<Word> ayahs(int surah, int first, int last) => [
      for (var a = first; a <= last; a++) ...ayah(surah, a),
    ];

/// Heard form of a canonical word: its search key.
String heard(Word w) => quran.searchKey(w.key, normalizer.id).value;

/// [w]'s key with letters dropped so that its similarity to the key is in
/// [low, high): a misreading built from the canon.
String misread(Word w, {required double low, required double high}) {
  final key = heard(w);
  for (var drop = 1; drop < key.runes.length; drop++) {
    var s = key;
    for (var i = 0; i < drop; i++) {
      s = dropLetter(s, s.runes.length ~/ 2);
    }
    final sim = similarity(s, key);
    if (sim >= low && sim < high) return s;
  }
  throw StateError('No misreading of ${w.key} in [$low, $high)');
}

/// A canonical key not similar (below `simFloor`) to [w] and to the words
/// around it, so following treats it as an extra word.
String unrelatedTo(Word w) {
  final i = surah78.indexOf(w);
  final around = surah78.sublist(
    i - 8 < 0 ? 0 : i - 8,
    i + 6 > surah78.length ? surah78.length : i + 6,
  );
  for (final candidate in surah78) {
    final key = heard(candidate);
    if (around.every(
      (a) => similarity(key, heard(a)) < FollowParams.defaults.simFloor,
    )) {
      return key;
    }
  }
  throw StateError('No unrelated word for ${w.key}');
}

/// Result of running follow and check over a script.
typedef Run = ({
  List<CheckEvent> events,
  List<StrictSignal> strict,
  Checker checker,
});

/// Runs [script] through `follow` and `check` for the passage
/// [from]..[to], then finishes both, like a session does.
Run runCheck(
  RecognitionScript script, {
  WordKey? from,
  WordKey? to,
  bool strict = false,
  void Function(Checker checker, RecognitionResult result)? afterEach,
  bool finish = true,
}) {
  final first = from ?? surah78.first.key;
  final last = to ?? surah78.last.key;
  final follower = Follower(
    text: quran,
    normalizer: normalizer,
    from: first,
    to: last,
    params: FollowParams.defaults,
  );
  final checker = Checker(
    text: quran,
    normalizer: normalizer.id,
    from: first,
    to: last,
    params: CheckParams.defaults,
    sessionId: 's',
    versions: versions,
    strict: strict,
  );
  final events = <CheckEvent>[];
  final signals = <StrictSignal>[];
  CheckUpdate feed(FollowUpdate u) => checker.accept(
        path: [for (final s in u.path) toPathStep(s)],
        jumps: [for (final j in u.jumps) toJumpInput(j)],
      );
  void take(CheckUpdate u) {
    events.addAll(u.events.map((o) => o.event));
    signals.addAll(u.strict);
  }

  for (final r in script.results) {
    take(feed(follower.accept(r)));
    afterEach?.call(checker, r);
  }
  if (finish) {
    final end = script.results.isEmpty ? 0 : script.results.last.audioEndMs;
    take(feed(follower.finish(sessionId: 's', atMs: end)));
    take(checker.finish(end));
  }
  return (events: events, strict: signals, checker: checker);
}

/// The last state of every event, by id.
Map<String, CheckEvent> finals(List<CheckEvent> events) => {
      for (final e in events) e.eventId: e,
    };

/// Final events of [kind] in [state].
List<CheckEvent> finalOf(
  List<CheckEvent> events,
  CheckKind kind,
  CheckState state,
) =>
    [
      for (final e in finals(events).values)
        if (e.kind == kind && e.state == state) e,
    ];

/// Final confirmed mistakes (omission, substitution, insertion, jump).
List<CheckEvent> confirmedMistakes(List<CheckEvent> events) => [
      for (final e in finals(events).values)
        if (e.state == CheckState.confirmed &&
            e.kind != CheckKind.repetition &&
            e.kind != CheckKind.hesitation)
          e,
    ];

/// A script with one segment per ayah: each heard key is paired with the
/// expected word it stands for (to know where ayahs end).
RecognitionScript byAyah(List<(Word, String)> reading) {
  final script = RecognitionScript();
  final segment = <String>[];
  int? ayahNo;
  for (final (word, key) in reading) {
    if (ayahNo != null && word.key.ayah != ayahNo) {
      script
        ..segment(List.of(segment))
        ..pause(800);
      segment.clear();
    }
    ayahNo = word.key.ayah;
    segment.add(key);
  }
  if (segment.isNotEmpty) script.segment(segment);
  return script;
}

/// Clean reading of [words].
List<(Word, String)> clean(List<Word> words) => [
      for (final w in words) (w, heard(w)),
    ];

/// Whether skipping word [i] of [words] is unambiguous for following: the
/// word read next is not similar (below `simFloor`) to the skipped word or
/// to any word within `maxBack` before it, so neither a weak match nor a
/// repetition can explain it better than a skip.
bool cleanSkip(List<Word> words, int i) {
  const p = FollowParams.defaults;
  if (i < 1 || i + 1 >= words.length) return false;
  final next = heard(words[i + 1]);
  final from = i - p.maxBack < 0 ? 0 : i - p.maxBack;
  return [
    for (var j = from; j <= i; j++) words[j],
  ].every((w) => similarity(next, heard(w)) < p.simFloor);
}

/// What the session does: copy follow's output into check's input types.
PathWord toPathWord(HeardWord h) =>
    PathWord(index: h.index, text: h.text, key: h.key, atMs: h.atMs);

/// See [toPathWord].
PathStep toPathStep(AlignmentStep s) => PathStep(
      kind: PathStepKind.values.byName(s.kind.name),
      heard: toPathWord(s.heard),
      expected: s.expected,
      similarity: s.similarity,
      skipped: s.skipped,
    );

/// See [toPathWord].
JumpInput toJumpInput(JumpCandidate j) => JumpInput(
      from: j.from,
      to: j.to,
      heard: [for (final h in j.heard) toPathWord(h)],
      matchedNgrams: j.matchedNgrams,
    );
