import 'dart:convert';
import 'dart:io';

import 'package:content_build/content_build.dart';
import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';

// Derived data built from the committed text fixtures (Tanzil, unchanged).
// Places are found by word keys; no Arabic is typed here.

const String fixtures = '../../packages/testing/fixtures';
const int linesPerPage = 15;

void main() {
  late List<Word> words;
  late List<AyahSpan> ayahs;
  late Map<int, WordPlace> layout;
  late DerivedParams params;
  late DerivedContent derived;
  late List<SearchKey> keys;

  setUpAll(() {
    words = switch (QuranTextJsonSource(
      File('$fixtures/quran_text.json').readAsStringSync(),
    ).loadWords()) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    ayahs = ayahSpansOf(words);
    layout = layoutPlacesFromJson(
      File('$fixtures/content_p582_583.json').readAsStringSync(),
    );
    params = DerivedParams.fromJson(
      File('config/derived.json').readAsStringSync(),
    );
    derived = deriveContent(
      ayahs: ayahs,
      words: words,
      layout: layout,
      linesPerPage: linesPerPage,
      params: params,
    );
    keys = InMemoryQuranText(
      words: words,
      normalizers: [Normalizer.builtIn],
      params: SearchParams.defaults,
    ).keysFor(Normalizer.builtIn.id);
  });

  WordKey key(int index) => words[index - 1].key;

  group('default passages', () {
    test('cover all 6236 ayahs without gaps or overlaps', () {
      expect(ayahs, hasLength(6236));
      var next = 1;
      for (final p in derived.passages) {
        expect(p.from, next, reason: 'passage ${key(p.from)}');
        expect(p.to, greaterThanOrEqualTo(p.from));
        next = p.to + 1;
      }
      expect(next - 1, words.length);
      // Passages start and end on ayah boundaries.
      final starts = {for (final a in ayahs) a.firstWordIndex};
      final ends = {for (final a in ayahs) a.lastWordIndex};
      for (final p in derived.passages) {
        expect(starts, contains(p.from));
        expect(ends, contains(p.to));
      }
    });

    test('never across a surah, at most passageMaxAyahs ayahs', () {
      for (final p in derived.passages) {
        expect(key(p.from).surah, key(p.to).surah);
        final count = ayahs
            .where((a) => a.firstWordIndex >= p.from && a.lastWordIndex <= p.to)
            .length;
        expect(count, inInclusiveRange(1, params.passageMaxAyahs));
      }
    });

    test('without layout: at most half a page in words, a long ayah alone', () {
      for (final p in derived.passages) {
        if (layout.containsKey(p.from)) continue;
        final inside = ayahs
            .where((a) => a.firstWordIndex >= p.from && a.lastWordIndex <= p.to)
            .toList();
        final words = p.to - p.from + 1;
        if (inside.length > 1) {
          expect(words, lessThanOrEqualTo(params.halfPageWords));
        }
      }
      for (final a in ayahs.where((a) => a.wordCount > params.halfPageWords)) {
        expect(
          derived.passages,
          contains((from: a.firstWordIndex, to: a.lastWordIndex)),
          reason: 'long ayah ${a.surah}:${a.ayah}',
        );
      }
    });

    test('with layout (pages 582–583): one page, at most half of its lines',
        () {
      final maxLines = (linesPerPage * params.pageFraction).floor();
      final onPages = derived.passages.where((p) => layout.containsKey(p.from));
      expect(onPages, isNotEmpty);
      for (final p in onPages) {
        final first = layout[p.from]!; // Checked by the filter.
        final last = layout[p.to];
        expect(last, isNotNull, reason: 'whole passage in the layout');
        expect(last!.page, first.page); // Just checked.
        expect(last.line - first.line + 1, lessThanOrEqualTo(maxLines));
      }
    });

    test('a short surah is split evenly, not 5 + 1', () {
      // Surah 1 has 7 ayahs: two passages of 4 and 3 ayahs.
      final fatiha = derived.passages.where((p) => key(p.from).surah == 1);
      expect(fatiha, hasLength(2));
      expect(key(fatiha.first.to).ayah, 4);
    });
  });

  group('similar places', () {
    List<int> refrainAyahs(int surah, int sample) {
      final sampleSpan =
          ayahs.firstWhere((a) => a.surah == surah && a.ayah == sample);
      List<String> keysOf(AyahSpan a) => [
            for (var w = a.firstWordIndex; w <= a.lastWordIndex; w++)
              keys[w - 1].value,
          ];
      final refrain = keysOf(sampleSpan);
      return [
        for (final a in ayahs)
          if (a.surah == surah &&
              a.wordCount == refrain.length &&
              keysOf(a).join() == refrain.join())
            a.firstWordIndex,
      ];
    }

    void expectAllLinked(List<int> starts, int length) {
      bool covers(int from, int to, int start) =>
          from <= start && to >= start + length - 1;
      for (var x = 0; x < starts.length; x++) {
        for (var y = x + 1; y < starts.length; y++) {
          expect(
            derived.pairs.any(
              (p) =>
                  covers(p.aFrom, p.aTo, starts[x]) &&
                  covers(p.bFrom, p.bTo, starts[y]),
            ),
            isTrue,
            reason: '${key(starts[x])} ~ ${key(starts[y])}',
          );
        }
      }
    }

    test('every repeat of the refrain of surah 55 is paired', () {
      // The refrain is ayah 55:13; it stands 31 times in the surah.
      final starts = refrainAyahs(55, 13);
      expect(starts, hasLength(31));
      final length =
          ayahs.firstWhere((a) => a.surah == 55 && a.ayah == 13).wordCount;
      expectAllLinked(starts, length);
    });

    test('every repeat of the refrain of surah 77 is paired', () {
      // Ayah 77:15, ten times in the surah; three words — a whole-ayah pair.
      final starts = refrainAyahs(77, 15);
      expect(starts, hasLength(10));
      expectAllLinked(starts, 3);
    });

    test('pairs are ordered, unique and do not overlap', () {
      final seen = <(int, int, int, int)>{};
      for (final p in derived.pairs) {
        expect(p.aFrom, lessThan(p.bFrom));
        expect(p.aTo, lessThan(p.bFrom), reason: 'no overlap');
        expect(p.aTo - p.aFrom, p.bTo - p.bFrom);
        expect(seen.add((p.aFrom, p.aTo, p.bFrom, p.bTo)), isTrue);
        // The mirror pair is never stored.
        expect(seen.contains((p.bFrom, p.bTo, p.aFrom, p.aTo)), isFalse);
      }
    });

    test('places start and end on equal keys and are long enough', () {
      for (final p in derived.pairs) {
        expect(keys[p.aFrom - 1], keys[p.bFrom - 1]);
        expect(keys[p.aTo - 1], keys[p.bTo - 1]);
        if (!p.wholeAyahs) {
          expect(p.length, greaterThanOrEqualTo(params.similar.minPhraseWords));
        }
      }
    });

    test('text that never repeats gives no pairs', () {
      final unique = [
        for (var i = 0; i < 12; i++)
          Word(key: WordKey(1, 1, i + 1), index: i + 1, text: 'w$i'),
      ];
      expect(
        findSimilarPlaces(
          unique,
          [for (final w in unique) SearchKey(w.text)],
          params.similar,
        ),
        isEmpty,
      );
    });
  });

  test('the committed derived.json is what the build gives', () {
    final canon = switch (jsonDecode(
      File('$fixtures/quran_text.json').readAsStringSync(),
    )) {
      {'contentVersion': {'canonSha256': final String sum}} => sum,
      _ => fail('no canon checksum'),
    };
    expect(
      derived.toJson(canonSha256: canon),
      File('$fixtures/derived.json').readAsStringSync(),
    );
    final json = jsonDecode(File('$fixtures/derived.json').readAsStringSync())
        as Map<String, Object?>;
    expect(json['verified'], isFalse);
  });

  test('a broken derived.json config is a clear error', () {
    expect(
      () => DerivedParams.fromJson('{"passageMaxAyahs": "5"}'),
      throwsA(isA<ContentBuildException>()),
    );
    expect(
      () => DerivedParams.fromJson('{'),
      throwsA(isA<ContentBuildException>()),
    );
  });
}
