import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:follow/follow.dart';
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

// Recognition results are built from the canon of surah 78 (P03 fixture):
// the heard words are the search keys of canonical words, with skips,
// repeats and letter distortions. No Arabic text is typed here.

const String fixturePath = '../testing/fixtures/content_p582_583.json';
const Normalizer normalizer = Normalizer.builtIn;
const WordKey surahStart = WordKey(78, 1, 1);

late InMemoryQuranText quran;

Follower follower({WordKey from = surahStart, WordKey? to}) => Follower(
      text: quran,
      normalizer: normalizer,
      from: from,
      to: to ?? ayah(78, 40).last.key,
      params: FollowParams.defaults,
    );

/// Heard form of canonical words: their search keys.
List<String> heard(Iterable<Word> words) => [
      for (final w in words) quran.searchKey(w.key, normalizer.id).value,
    ];

List<Word> ayah(int surah, int number) => quran.words
    .where((w) => w.key.surah == surah && w.key.ayah == number)
    .toList();

List<Word> ayahs(int surah, int first, int last) => [
      for (var a = first; a <= last; a++) ...ayah(surah, a),
    ];

/// Runs [script] through a new follower and collects everything.
({
  List<WordKey> revealed,
  List<SessionEvent> events,
  List<AlignmentStep> path,
  List<JumpCandidate> jumps
}) run(RecognitionScript script, {Follower? using}) {
  final f = using ?? follower();
  final events = <SessionEvent>[];
  final path = <AlignmentStep>[];
  final jumps = <JumpCandidate>[];
  for (final r in script.results) {
    final u = f.accept(r);
    events.addAll(u.events);
    path.addAll(u.path);
    jumps.addAll(u.jumps);
  }
  return (
    revealed: [
      for (final e in events)
        if (e is WordRevealed) e.word,
    ],
    events: events,
    path: path,
    jumps: jumps,
  );
}

void main() {
  setUpAll(() {
    final words = switch (ContentJsonSource(
      File(fixturePath).readAsStringSync(),
    ).loadWords()) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    quran = InMemoryQuranText(
      words: words,
      normalizers: [normalizer],
      params: SearchParams.defaults,
    );
  });

  test('clean reading: every word revealed once, in order', () {
    final script = RecognitionScript();
    for (var a = 1; a <= 40; a++) {
      script
        ..segment(heard(ayah(78, a)))
        ..pause(800);
    }
    final r = run(script);
    expect(r.revealed, [for (final w in ayahs(78, 1, 40)) w.key]);
    expect(r.events.whereType<PositionLost>(), isEmpty);
    expect(r.path.every((s) => s.kind == AlignmentStepKind.match), isTrue);
    expect(r.path, hasLength(173));
  });

  test('start from ayah 5: revealing starts at ayah 5', () {
    final script = RecognitionScript();
    for (var a = 5; a <= 10; a++) {
      script.segment(heard(ayah(78, a)));
    }
    final r = run(script);
    expect(r.revealed, [for (final w in ayahs(78, 5, 10)) w.key]);
    expect(r.jumps, isEmpty);
  });

  test('position never found: PositionLost with no last word, once', () {
    // Reading surah 79 while the passage is surah 78.
    final r = run(RecognitionScript()..segment(heard(ayahs(79, 1, 5))));
    final lost = r.events.whereType<PositionLost>().toList();
    expect(lost, hasLength(1));
    expect(lost.single.lastConfidentWord, isNull);
    expect(r.revealed, isEmpty);
  });

  test('start in the middle: PositionLost with no last word, then found', () {
    final r = run(RecognitionScript()..segment(heard(ayahs(78, 20, 22))));
    expect(r.events.first, isA<PositionLost>());
    expect((r.events.first as PositionLost).lastConfidentWord, isNull);
    expect(r.events.whereType<PositionLost>(), hasLength(1));
    expect(r.revealed, [for (final w in ayahs(78, 20, 22)) w.key]);
  });

  test('repeat of the previous 3 words: position goes back, no new reveals',
      () {
    final words = ayahs(78, 6, 9);
    final read = [...words.sublist(0, 6), ...words.sublist(3)];
    final r = run(RecognitionScript()..segment(heard(read)));
    expect(r.revealed, [for (final w in words) w.key]);
    final back = r.path.where((s) => s.kind == AlignmentStepKind.back);
    expect(back.single.expected, words[3].key);
    final positions = [
      for (final e in r.events)
        if (e is PositionUpdate) e.word,
    ];
    expect(positions, contains(words[3].key));
  });

  test('skip of one word: later words revealed, the skipped one is not', () {
    final words = ayahs(78, 12, 14);
    final skipped = words[4];
    final read = [...words.take(4), ...words.skip(5)];
    final r = run(RecognitionScript()..segment(heard(read)));
    expect(r.revealed, [
      for (final w in words)
        if (w != skipped) w.key,
    ]);
    final skip = r.path.singleWhere((s) => s.kind == AlignmentStepKind.skip);
    expect(skip.skipped, [skipped.key]);
    expect(skip.expected, words[5].key);
  });

  test('jump to another surah: candidate for check, nothing revealed there',
      () {
    final script = RecognitionScript()
      ..segment(heard(ayahs(78, 1, 3)))
      ..segment(heard(ayahs(79, 1, 4)));
    final r = run(script);
    expect(r.revealed, [for (final w in ayahs(78, 1, 3)) w.key]);
    expect(r.revealed.every((k) => k.surah == 78), isTrue);
    expect(r.jumps, isNotEmpty);
    final jump = r.jumps.first;
    // The candidate points where its heard words start, inside surah 79.
    expect(jump.to.surah, 79);
    expect(
      quran.range(jump.to, quran.words.last.key).take(jump.heard.length).map(
            (w) => quran.searchKey(w.key, normalizer.id),
          ),
      jump.heard.map((h) => h.key),
    );
    // Words heard there are given to check as unaligned, not revealed.
    expect(
      r.path.where((s) => s.kind == AlignmentStepKind.unaligned),
      isNotEmpty,
    );
    expect(r.jumps.first.from, ayah(78, 3).last.key);
    final lost = r.events.whereType<PositionLost>().single;
    expect(lost.lastConfidentWord, ayah(78, 3).last.key);
    // Consecutive words at the same place are reported once.
    expect(r.jumps, hasLength(1));
  });

  test('changing partial results: no word revealed and then taken back', () {
    final words = heard(ayahs(78, 1, 10));
    final unrelated = heard(ayah(78, 38));
    final script = RecognitionScript();
    final partials = <List<String>>[];
    for (var n = 1; n <= words.length; n++) {
      // The newest word of every partial is first misheard as an unrelated
      // word, then corrected in the next partial.
      partials
        ..add([...words.sublist(0, n - 1), unrelated[n % unrelated.length]])
        ..add(words.sublist(0, n));
    }
    script.segmentWithPartials(partials, words);
    final r = run(script);
    expect(r.revealed, [for (final w in ayahs(78, 1, 10)) w.key]);
    expect(r.path.map((s) => s.heard.text), words);
  });

  test('long pause inside an ayah keeps the position', () {
    final words = ayah(78, 38);
    final script = RecognitionScript()
      ..segment(heard(words.take(6)))
      ..pause(20000)
      ..segment(heard(words.skip(6)));
    final r = run(script, using: follower(from: words.first.key));
    expect(r.revealed, [for (final w in words) w.key]);
    expect(r.events.whereType<PositionLost>(), isEmpty);
  });

  test('sliding partial windows of a long segment are stitched', () {
    final words = ayahs(78, 17, 25);
    final script = RecognitionScript()
      ..slidingSegment(heard(words), windowWords: 8);
    final r = run(script);
    expect(r.revealed, [for (final w in words) w.key]);
    expect(r.path, hasLength(words.length));
  });

  test('distorted letters: words still revealed, heard text kept as heard', () {
    final words = ayah(78, 38);
    final read = heard(words);
    // Every long word loses its second letter.
    String distort(String h) => h.runes.length >= 5 ? dropLetter(h, 1) : h;
    final distorted = read.map(distort).toList();
    final r = run(RecognitionScript()..segment(distorted));
    expect(r.revealed, [for (final w in words) w.key]);
    expect(r.path.map((s) => s.heard.text), distorted); // ПО-13
  });

  test('one word repeated several times: revealed once, reading goes on', () {
    final words = ayahs(78, 6, 7);
    final read = heard(words);
    final stutter = [...read.take(3), read[2], read[2], ...read.skip(3)];
    final r = run(
      RecognitionScript()..segment(stutter),
      using: follower(from: words.first.key),
    );
    expect(r.revealed, [for (final w in words) w.key]);
    expect(r.events.whereType<PositionLost>(), isEmpty);
  });

  test('a different word instead of the expected one is not revealed', () {
    final words = ayahs(78, 12, 14);
    final read = heard(words);
    // Word 5 replaced by the key of a word that is not similar to it.
    final other = heard(ayah(78, 38)).firstWhere(
      (k) => similarity(k, read[4]) < FollowParams.defaults.simFloor,
    );
    read[4] = other;
    final r = run(RecognitionScript()..segment(read));
    expect(r.revealed, isNot(contains(words[4].key)));
    expect(r.revealed, containsAll(words.skip(5).map((w) => w.key)));
    final step = r.path.firstWhere((s) => s.heard.text == other);
    expect(step.heard.text, other); // ПО-13: kept as heard.
  });

  test('works on a stream from the fake recognizer', () async {
    final script = RecognitionScript()..segment(heard(ayahs(78, 1, 2)));
    final recognizer = FakeSpeechRecognizer(
      script.results,
      info: scriptedRecognizerInfo,
    );
    final updates = follower().bind(recognizer.results).toList();
    await recognizer.play();
    final revealed = [
      for (final u in await updates)
        for (final e in u.events)
          if (e is WordRevealed) e.word,
    ];
    expect(revealed, [for (final w in ayahs(78, 1, 2)) w.key]);
  });

  group('ambiguity (synthetic passage, Latin placeholders)', () {
    // A phrase "aa bb cc" stands twice; "dd" follows only the first one.
    const tokens = [
      'jj',
      'kk',
      'aa',
      'bb',
      'cc',
      'dd',
      'ee',
      'ff',
      'gg',
      'aa',
      'bb',
      'cc',
      'hh',
      'ii',
    ];
    late InMemoryQuranText synthetic;
    late Follower f;

    setUp(() {
      synthetic = InMemoryQuranText(
        words: [
          for (var i = 0; i < tokens.length; i++)
            Word(
              key: WordKey(1, 1, i + 1),
              index: i + 1,
              text: tokens[i],
              page: 1,
              line: 1,
            ),
        ],
        normalizers: [normalizer],
        params: SearchParams.defaults,
      );
      f = Follower(
        text: synthetic,
        normalizer: normalizer,
        from: const WordKey(1, 1, 1),
        to: WordKey(1, 1, tokens.length),
        params: FollowParams.defaults,
      );
    });

    test('both places are kept until a distinguishing word', () {
      final script = RecognitionScript()
        ..segment(['aa', 'bb', 'cc'])
        ..segment(['dd', 'ee']);
      final firstSegment = script.results.indexWhere((r) => r.isFinal) + 1;
      final before = <SessionEvent>[];
      final after = <SessionEvent>[];
      for (final (i, r) in script.results.indexed) {
        (i < firstSegment ? before : after).addAll(f.accept(r).events);
      }

      expect(before.whereType<WordRevealed>(), isEmpty);
      final low = before.whereType<PositionUpdate>().last;
      expect(low.confidence, PositionConfidence.low);
      expect({
        low.word,
        ...low.candidates,
      }, {
        const WordKey(1, 1, 5),
        const WordKey(1, 1, 12),
      });

      expect([
        for (final e in after)
          if (e is WordRevealed) e.word,
      ], [
        for (var w = 3; w <= 7; w++) WordKey(1, 1, w),
      ]);
      expect(
        after.whereType<PositionUpdate>().last.confidence,
        PositionConfidence.high,
      );
    });
  });
}
