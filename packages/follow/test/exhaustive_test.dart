import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:follow/follow.dart';
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

// Sweeps over the whole of surah 78 (P03 fixture). Heard words are search
// keys of canonical words; nothing is typed.

const String fixturePath = '../testing/fixtures/content_p582_583.json';
const Normalizer normalizer = Normalizer.builtIn;

void main() {
  late InMemoryQuranText quran;
  late List<Word> surah;

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
    surah = words.where((w) => w.key.surah == 78).toList();
  });

  String key(Word w) => quran.searchKey(w.key, normalizer.id).value;

  List<WordKey> revealedBy(List<List<String>> segments) {
    final script = RecognitionScript();
    for (final s in segments) {
      script
        ..segment(s)
        ..pause(1000);
    }
    final f = Follower(
      text: quran,
      normalizer: normalizer,
      from: surah.first.key,
      to: surah.last.key,
      params: FollowParams.defaults,
    );
    final last = script.results.last;
    final events = [
      for (final r in script.results) ...f.accept(r).events,
      ...f.finish(sessionId: last.sessionId, atMs: last.audioEndMs).events,
    ];
    return [
      for (final e in events)
        if (e is WordRevealed) e.word,
    ];
  }

  List<List<String>> byAyah(List<Word> words) {
    final segments = <List<String>>[];
    int? ayah;
    for (final w in words) {
      if (w.key.ayah != ayah) segments.add([]);
      ayah = w.key.ayah;
      segments.last.add(key(w));
    }
    return segments;
  }

  test('starting at any ayah reveals exactly the words read', () {
    for (var a = 1; a <= 40; a++) {
      final read = surah.where((w) => w.key.ayah >= a).toList();
      expect(
        revealedBy(byAyah(read)),
        [for (final w in read) w.key],
        reason: 'start at 78:$a',
      );
    }
  });

  test('skipping any one word reveals all the others, never it', () {
    final failures = <String>[];
    for (var i = 1; i < surah.length - 1; i++) {
      final read = [...surah.take(i), ...surah.skip(i + 1)];
      final revealed = revealedBy(byAyah(read));
      if (revealed.contains(surah[i].key)) {
        failures.add('${surah[i].key}: skipped word revealed');
      }
      final missing = read.where((w) => !revealed.contains(w.key)).toList();
      if (missing.isNotEmpty) {
        failures
            .add('${surah[i].key}: not revealed ${missing.map((w) => w.key)}');
      }
    }
    expect(failures, isEmpty);
  });

  test('repeating the previous 3 words anywhere adds no reveals', () {
    final failures = <String>[];
    for (var i = 3; i < surah.length; i++) {
      final read = [...surah.take(i), ...surah.skip(i - 3)];
      final revealed = revealedBy([
        [for (final w in read) key(w)],
      ]);
      if (revealed.join() != surah.map((w) => w.key).join()) {
        failures.add('repeat before ${surah[i].key}');
      }
    }
    expect(failures, isEmpty);
  });

  test('a word with one lost letter is still revealed in place', () {
    final failures = <String>[];
    for (var i = 0; i < surah.length; i++) {
      final k = key(surah[i]);
      if (k.runes.length < 5) continue; // Too short to stay similar.
      String heardAt(int j) => j == i ? dropLetter(k, 1) : key(surah[j]);
      final read = [for (var j = 0; j < surah.length; j++) heardAt(j)];
      final revealed = revealedBy([read]);
      if (revealed.join() != surah.map((w) => w.key).join()) {
        failures.add('${surah[i].key}');
      }
    }
    expect(failures, isEmpty);
  });
}
