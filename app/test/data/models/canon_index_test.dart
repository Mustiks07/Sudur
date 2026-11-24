import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/data/models/canon_index.dart';

final String _text = File('../packages/testing/fixtures/quran_text.json')
    .readAsStringSync();

// The derived passages of D01 (#23). Until #23 is merged the fixture is not
// on main; tests build an index with one passage per ayah instead.
String _ayahPassages(String text) {
  final root = jsonDecode(text) as Map<String, Object?>;
  final version = root['contentVersion']! as Map<String, Object?>;
  var next = 1;
  return jsonEncode(<String, Object?>{
    'format': 1,
    'kind': 'derived',
    'textCanonSha256': version['canonSha256'],
    'passages': <Object?>[
      for (final ayah in root['ayahs']! as List<Object?>)
        <int>[next, (next += _wordsOf(ayah)) - 1],
    ],
  });
}

int _wordsOf(Object? ayah) =>
    ((ayah! as List<Object?>)[2]! as List<Object?>).length;

void main() {
  late CanonIndex index;

  setUpAll(() {
    final derived = File('../packages/testing/fixtures/derived.json');
    index = CanonIndex.parse(
      _text,
      derived.existsSync() ? derived.readAsStringSync() : _ayahPassages(_text),
    );
  });

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
}
