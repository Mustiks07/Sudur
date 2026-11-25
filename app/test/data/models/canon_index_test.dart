import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/data/models/canon_index.dart';

import '../../test_helpers/fixture_canon.dart';

final String _text = fixtureQuranText();
String _ayahPassages(String text) => ayahPassages(text);

void main() {
  late CanonIndex index;

  setUpAll(() => index = fixtureCanon());

  test('the whole text: 114 surahs, 6236 ayahs, 77 433 words', () {
    expect(index.wordCount, 77433);
    expect(
      [for (var s = 1; s <= 114; s++) index.ayahsOf(s).length]
          .reduce((a, b) => a + b),
      6236,
    );
    expect(index.ayahsOf(78), hasLength(40));
  });

  test('word index and word key are inverse', () {
    for (final i in [1, 2, 29, 30, 77433, 40000]) {
      expect(index.indexOf(index.keyOf(i)), i);
    }
    expect(index.keyOf(1), const WordKey(1, 1, 1));
    expect(index.keyOf(77433).surah, 114);
    final first78 = index.ayahsOf(78).first.firstWordIndex;
    expect(index.keyOf(first78), const WordKey(78, 1, 1));
    expect(() => index.keyOf(0), throwsRangeError);
    expect(() => index.indexOf(const WordKey(1, 8, 1)), throwsRangeError);
  });

  test('passages of a surah stay inside it and cover it', () {
    final ayahs = index.ayahsOf(78);
    final passages = index.passagesOf(78);
    expect(passages.first.fromWordIndex, ayahs.first.firstWordIndex);
    expect(passages.last.toWordIndex, ayahs.last.lastWordIndex);
    for (final p in passages) {
      expect(index.keyOf(p.fromWordIndex).surah, 78);
      expect(index.keyOf(p.toWordIndex).surah, 78);
    }
  });

  test('passages built from another text are refused', () {
    final derived = jsonDecode(_ayahPassages(_text)) as Map<String, Object?>;
    derived['textCanonSha256'] = '0' * 64;
    expect(
      () => CanonIndex.parse(_text, jsonEncode(derived)),
      throwsFormatException,
    );
  });

  test('passages with a gap are refused', () {
    final derived = jsonDecode(_ayahPassages(_text)) as Map<String, Object?>;
    (derived['passages']! as List<Object?>).removeAt(3);
    expect(
      () => CanonIndex.parse(_text, jsonEncode(derived)),
      throwsFormatException,
    );
  });

  test('similar pairs give the other place of an overlapping range', () {
    final derived = jsonDecode(_ayahPassages(_text)) as Map<String, Object?>;
    derived['similarPairs'] = [
      [10, 14, 500, 504],
    ];
    final withPairs = CanonIndex.parse(_text, jsonEncode(derived));
    expect(withPairs.similarTo(12, 20), [(500, 504)]);
    expect(withPairs.similarTo(501, 501), [(10, 14)]);
    expect(withPairs.similarTo(15, 20), isEmpty);
    expect(withPairs.ayahOf(1).ayah, 1);
  });
}
