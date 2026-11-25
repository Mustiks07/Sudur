import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/data/repositories/reading_repository.dart';

import '../../test_helpers/fixture_canon.dart';

void main() {
  final text = fixtureQuranText();
  final index = fixtureCanon();

  test('a passage comes from the canon unchanged, ayah by ayah', () {
    final first = index.ayahsOf(78).first;
    final fifth = index.ayahsOf(78)[4];
    final from = index.keyOf(first.firstWordIndex);
    final to = index.keyOf(fifth.lastWordIndex);

    final passage = readPassageText(text, from, to);

    expect(passage.ayahs.map((a) => a.ayah), [1, 2, 3, 4, 5]);
    expect(passage.words.first, from);
    expect(passage.words.last, to);
    expect(
      passage.words,
      hasLength(fifth.lastWordIndex - first.firstWordIndex + 1),
    );
    expect(
      passage.ayahs.expand((a) => a.words).every((w) => w.text.isNotEmpty),
      isTrue,
    );
    expect(passage.textVersion, startsWith('tanzil-'));
  });

  test('a passage in the middle of an ayah keeps only its words', () {
    final passage = readPassageText(
      text,
      const WordKey(2, 255, 3),
      const WordKey(2, 255, 5),
    );
    expect(passage.words, const [
      WordKey(2, 255, 3),
      WordKey(2, 255, 4),
      WordKey(2, 255, 5),
    ]);
  });

  test('a range that is not in the text is refused', () {
    expect(
      () =>
          readPassageText(text, const WordKey(1, 8, 1), const WordKey(1, 9, 1)),
      throwsFormatException,
    );
  });
}
