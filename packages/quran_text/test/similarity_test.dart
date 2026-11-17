import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';

void main() {
  group('levenshtein', () {
    test('counts edits', () {
      expect(levenshtein('kitten', 'sitting'), 3);
      expect(levenshtein('', 'abc'), 3);
      expect(levenshtein('abc', ''), 3);
      expect(levenshtein('abc', 'abc'), 0);
    });

    test('counts code points, not UTF-16 units', () {
      // One astral character differs from another by one edit.
      expect(levenshtein('a\u{1F600}', 'a\u{1F601}'), 1);
    });
  });

  group('similarity (docs/tz 10.1)', () {
    test('equal strings → 1', () {
      expect(similarity('abc', 'abc'), 1);
    });

    test('two empty strings → 1, one empty → 0', () {
      expect(similarity('', ''), 1);
      expect(similarity('', 'abc'), 0);
      expect(similarity('abc', ''), 0);
    });

    test('nothing in common → 0', () {
      expect(similarity('abc', 'xyz'), 0);
    });

    test('1 − distance / longer length', () {
      expect(similarity('abcd', 'abxd'), closeTo(0.75, 1e-9));
      expect(similarity('ab', 'abcd'), closeTo(0.5, 1e-9));
    });

    test('is symmetric', () {
      expect(similarity('abc', 'abcde'), similarity('abcde', 'abc'));
    });
  });

  group('boundedLevenshtein', () {
    List<int> r(String s) => s.runes.toList();

    test('equals levenshtein within the bound, null beyond it', () {
      const pairs = [
        ('kitten', 'sitting'),
        ('', 'abc'),
        ('abc', ''),
        ('abc', 'abc'),
        ('abcdef', 'azcdxf'),
        ('flaw', 'lawn'),
      ];
      for (final (a, b) in pairs) {
        final d = levenshtein(a, b);
        for (var bound = 0; bound <= 7; bound++) {
          expect(
            boundedLevenshtein(r(a), r(b), bound),
            d <= bound ? d : null,
            reason: '$a/$b within $bound',
          );
        }
      }
    });
  });
}
