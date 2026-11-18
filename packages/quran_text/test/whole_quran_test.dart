import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';

// The whole-Quran text fixture (ADR 0004), built by tools/content_build
// from Tanzil without changes. Places for tests are picked by keys and
// positions in this text; no Arabic is typed here.

const String textFixturePath = '../testing/fixtures/quran_text.json';
const Normalizer normalizer = Normalizer.builtIn;
const double minSimilarity = 0.4; // follow's simFloor default (docs/tz 12.4)
const double maxMeanCost = 0.6; // follow's lostCostThreshold default

/// [key] without the code point in its middle: a misheard letter.
SearchKey dropMiddle(SearchKey key) {
  final runes = key.value.runes.toList()..removeAt(key.value.runes.length ~/ 2);
  return SearchKey(String.fromCharCodes(runes));
}

void main() {
  late List<Word> words;
  late InMemoryQuranText quran;
  late List<SearchKey> keys;

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
      params: SearchParams.defaults,
    );
    keys = quran.keysFor(normalizer.id);
  });

  List<SimilarMatch> similar(List<SearchKey> query) => quran.findSimilar(
        query,
        normalizer: normalizer.id,
        minSimilarity: minSimilarity,
        maxMeanCost: maxMeanCost,
      );

  int at(WordKey key) => words.indexWhere((w) => w.key == key);

  test('loads the whole Quran in order: 6236 ayahs, 77 433 words', () {
    expect(words, hasLength(77433));
    expect(words.first.key, const WordKey(1, 1, 1));
    expect(words.last.key.surah, 114);
    expect({for (final w in words) (w.key.surah, w.key.ayah)}, hasLength(6236));
    for (var i = 0; i < words.length; i++) {
      expect(words[i].index, i + 1);
    }
  });

  test('rejects other formats', () {
    for (final bad in [
      '{"format": 1, "words": []}',
      '{"format": 2, "kind": "layout", "ayahs": []}',
      '{"format": 2, "kind": "text", "ayahs": [[1, 1, "x"]]}',
      'nope',
    ]) {
      expect(
        QuranTextJsonSource(bad).loadWords(),
        isA<Error<List<Word>>>(),
        reason: bad,
      );
    }
  });

  test('findSimilar: exact words of a far surah are found there', () {
    final start = at(const WordKey(2, 255, 3));
    final query = keys.sublist(start, start + 4);
    final matches = similar(query);
    expect(matches.first.start, const WordKey(2, 255, 3));
    expect(matches.first.meanCost, 0);
  });

  test('findSimilar: a letter lost in every word still finds the place', () {
    final start = at(const WordKey(36, 12, 2));
    SearchKey misheard(SearchKey k) =>
        k.value.runes.length >= 4 ? dropMiddle(k) : k;
    final query = keys.sublist(start, start + 4).map(misheard).toList();
    // Exact trigrams no longer match …
    expect(
      quran
          .findSequence(query, normalizer: normalizer.id)
          .where((m) => m.start == const WordKey(36, 12, 2)),
      isEmpty,
    );
    // … the similarity search still does.
    final matches = similar(query);
    expect(
      matches.map((m) => m.start),
      contains(const WordKey(36, 12, 2)),
    );
    expect(matches.first.meanCost, greaterThan(0));
  });

  test('findSimilar: a 5-letter word with one wrong letter at 0.8 (boundary)',
      () {
    // Regression (Astra, #21): the edit bound was floor((1 − 0.8) × 5) = 0
    // in floating point, so similarity exactly 0.8 was never found.
    // A 5-letter key of the canon; one letter replaced by a letter taken
    // from another canonical key.
    final start = keys.indexWhere(
      (k) => k.value.runes.length == 5 && k.value.runes.toSet().length == 5,
    );
    final runes = keys[start].value.runes.toList();
    final other =
        keys.expand((k) => k.value.runes).firstWhere((r) => !runes.contains(r));
    final wrong = SearchKey(
      String.fromCharCodes(
        [...runes.sublist(0, 2), other, ...runes.sublist(3)],
      ),
    );
    expect(similarity(wrong.value, keys[start].value), 0.8);
    final query = [wrong, ...keys.sublist(start + 1, start + 3)];
    final matches = quran.findSimilar(
      query,
      normalizer: normalizer.id,
      minSimilarity: 0.8,
      maxMeanCost: 0.2,
    );
    expect(matches.map((m) => m.start), contains(words[start].key));
  });

  test('findSimilar: a repeated ayah gives several places, best first', () {
    // A 4-word window that occurs more than once in surah 55.
    final surah = [
      for (var i = 0; i < words.length; i++)
        if (words[i].key.surah == 55) i,
    ];
    final windows = <String, List<int>>{};
    for (final i in surah) {
      if (i + 4 > words.length) continue;
      final w = keys.sublist(i, i + 4).map((k) => k.value).join(' ');
      (windows[w] ??= []).add(i);
    }
    final repeated = windows.values.firstWhere((v) => v.length > 2);
    final query = keys.sublist(repeated.first, repeated.first + 4);
    final matches = quran.findSimilar(
      query,
      normalizer: normalizer.id,
      minSimilarity: minSimilarity,
      maxMeanCost: maxMeanCost,
      maxResults: 100,
    );
    final exact = matches.where((m) => m.meanCost == 0).map((m) => m.start);
    expect(exact, containsAll([for (final i in repeated) words[i].key]));
  });

  test('findSimilar: words not from the Quran find nothing', () {
    expect(
      similar(const [SearchKey('qzx'), SearchKey('vwq'), SearchKey('zzkj')]),
      isEmpty,
    );
    expect(similar(const []), isEmpty);
  });

  test('cached keys are used as they are; a wrong count is refused', () {
    final cached = InMemoryQuranText(
      words: words,
      normalizers: [normalizer],
      params: SearchParams.defaults,
      cachedKeys: {normalizer.id: keys},
    );
    expect(cached.keysFor(normalizer.id), keys);
    expect(
      () => InMemoryQuranText(
        words: words,
        normalizers: [normalizer],
        params: SearchParams.defaults,
        cachedKeys: {normalizer.id: keys.sublist(1)},
      ),
      throwsArgumentError,
    );
  });
}
