import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:follow/follow.dart';
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

// Following over the whole-Quran text fixture (ADR 0004). Heard words are
// search keys of canonical words, picked by their place in the text, with
// letters dropped where a test needs mishearing. No Arabic is typed here.

const String textFixturePath = '../testing/fixtures/quran_text.json';
const Normalizer normalizer = Normalizer.builtIn;
const FollowParams params = FollowParams.defaults;

late List<Word> words;
late InMemoryQuranText quran;

int at(WordKey key) => words.indexWhere((w) => w.key == key);

List<Word> ayah(int surah, int number) => [
      for (final w in words)
        if (w.key.surah == surah && w.key.ayah == number) w,
    ];

List<Word> ayahs(int surah, int first, int last) => [
      for (var a = first; a <= last; a++) ...ayah(surah, a),
    ];

String heard(Word w) => quran.searchKey(w.key, normalizer.id).value;

/// [key] without its middle letter, for keys long enough to stay similar.
String misheard(String key) =>
    key.runes.length >= 5 ? dropLetter(key, key.runes.length ~/ 2) : key;

Follower follower(WordKey from, WordKey to) => Follower(
      text: quran,
      normalizer: normalizer,
      from: from,
      to: to,
      params: params,
    );

({List<WordKey> revealed, List<SessionEvent> events, List<JumpCandidate> jumps})
    run(Follower f, RecognitionScript script) {
  final events = <SessionEvent>[];
  final jumps = <JumpCandidate>[];
  for (final r in script.results) {
    final u = f.accept(r);
    events.addAll(u.events);
    jumps.addAll(u.jumps);
  }
  final last = script.results.last;
  events.addAll(
    f.finish(sessionId: last.sessionId, atMs: last.audioEndMs).events,
  );
  return (
    revealed: [
      for (final e in events)
        if (e is WordRevealed) e.word,
    ],
    events: events,
    jumps: jumps,
  );
}

void main() {
  setUpAll(() {
    words = switch (QuranTextJsonSource(
      File(textFixturePath).readAsStringSync(),
    ).loadWords()) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    quran = InMemoryQuranText(
      words: words,
      normalizers: [normalizer],
      params: SearchParams(ngramSize: params.ngramSize),
    );
  });

  const surah78 = (WordKey(78, 1, 1), WordKey(78, 40, 15));

  test('jump to a far surah: candidate there, nothing revealed outside', () {
    final f = follower(surah78.$1, surah78.$2);
    final script = RecognitionScript()
      ..segment([for (final w in ayahs(78, 1, 3)) heard(w)])
      ..segment([for (final w in ayah(2, 255).take(8)) heard(w)]);
    final r = run(f, script);
    expect(r.revealed, [for (final w in ayahs(78, 1, 3)) w.key]);
    expect(r.jumps, isNotEmpty);
    expect(r.jumps.first.to.surah, 2);
    expect(r.jumps.first.to.ayah, 255);
    expect(r.jumps.first.matchedNgrams, greaterThan(0));
  });

  test('jump with misheard letters is still found (similarity search)', () {
    final f = follower(surah78.$1, surah78.$2);
    final far = ayahs(36, 12, 13);
    final script = RecognitionScript()
      ..segment([for (final w in ayahs(78, 1, 3)) heard(w)])
      ..segment([for (final w in far) misheard(heard(w))]);
    final r = run(f, script);
    expect(r.revealed.every((k) => k.surah == 78), isTrue);
    expect(r.jumps, isNotEmpty);
    expect(r.jumps.first.to.surah, 36);
  });

  test('a similar ayah in another surah: a jump, not reveals in passage', () {
    // Find a 4-word window outside surah 78 that resembles a window later
    // in the passage but is not the same, so the passage fits clearly
    // worse than the look-alike itself.
    final keys = quran.keysFor(normalizer.id);
    final later = at(const WordKey(78, 20, 1));
    (int, int)? pair;
    for (var i = later; i + 4 <= at(surah78.$2) + 1 && pair == null; i++) {
      for (final m in quran.findSimilar(
        keys.sublist(i, i + 4),
        normalizer: normalizer.id,
        minSimilarity: params.simFloor,
        maxMeanCost: params.lostCostThreshold,
      )) {
        if (m.start.surah != 78 && m.meanCost >= params.ambiguityMargin) {
          pair = (i, at(m.start));
          break;
        }
      }
    }
    expect(pair, isNotNull, reason: 'surah 78 has a look-alike elsewhere');
    final (inside, outside) = pair!; // Checked just above.

    // The reader reads the start of the passage, then slips into the
    // look-alike of a later passage place.
    final f = follower(surah78.$1, surah78.$2);
    final script = RecognitionScript()
      ..segment([for (final w in ayahs(78, 1, 3)) heard(w)])
      ..segment(words.sublist(outside, outside + 4).map(heard).toList());
    final r = run(f, script);
    expect(r.revealed, [for (final w in ayahs(78, 1, 3)) w.key]);
    expect(
      r.revealed.where((k) => k.compareTo(words[inside].key) >= 0),
      isEmpty,
      reason: 'the look-alike place in the passage was not read',
    );
    expect(r.jumps, isNotEmpty);
    expect(r.jumps.first.to.surah, isNot(78));
  });

  test('repeated ayahs of surah 55: ambiguity, no false reveal', () {
    // Ayah 55:16 is repeated many times in the passage 55:1–55:30.
    final passage = (const WordKey(55, 1, 1), ayah(55, 30).last.key);
    final f = follower(passage.$1, passage.$2);
    final repeated = ayah(55, 16);
    final first = run(
      f,
      RecognitionScript()..segment(repeated.map(heard).toList()),
    );
    expect(first.revealed, isEmpty);
    final low = first.events.whereType<PositionUpdate>().last;
    expect(low.confidence, PositionConfidence.low);
    expect(low.candidates, isNotEmpty);
  });

  test('the next ayah tells repeated places apart, then words open', () {
    final passage = (const WordKey(55, 1, 1), ayah(55, 30).last.key);
    final f = follower(passage.$1, passage.$2);
    final read = [...ayah(55, 16), ...ayah(55, 17)];
    final r = run(f, RecognitionScript()..segment(read.map(heard).toList()));
    expect(r.revealed, [for (final w in read) w.key]);
    expect(r.jumps, isEmpty);
  });

  test('reading that is not from the Quran finds nothing', () {
    final f = follower(surah78.$1, surah78.$2);
    final r = run(
      f,
      RecognitionScript()..segment(['qzxw', 'vvqk', 'zzkj', 'xqqv', 'kkzz']),
    );
    expect(r.revealed, isEmpty);
    expect(r.jumps, isEmpty);
    expect(r.events.whereType<PositionLost>(), hasLength(1));
  });

  test('clean reading of surah 78 over the whole Quran: as before', () {
    final f = follower(surah78.$1, surah78.$2);
    final script = RecognitionScript();
    for (var a = 1; a <= 40; a++) {
      script
        ..segment(ayah(78, a).map(heard).toList())
        ..pause(800);
    }
    final r = run(f, script);
    expect(r.revealed, [for (final w in ayahs(78, 1, 40)) w.key]);
    expect(r.jumps, isEmpty);
  });
}
