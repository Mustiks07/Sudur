import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';

// Rules are tested on Latin placeholders and single code points written as
// numbers: no Quran text is typed here.
String cp(int codePoint) => String.fromCharCode(codePoint);

Normalizer parse(String json) => switch (Normalizer.fromJson(json)) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };

void main() {
  group('built-in normalizer (docs/tz 10.1)', () {
    const n = Normalizer.builtIn;

    test('step 1: applies NFC', () {
      // e + combining acute → precomposed é.
      expect(n.keyOf('e${cp(0x0301)}').value, cp(0x00E9));
    });

    test('step 2: deletes tatweel U+0640', () {
      expect(n.keyOf('a${cp(0x0640)}b').value, 'ab');
    });

    test('step 3: deletes harakat U+064B–U+0652, both ends included', () {
      for (final c in [0x064B, 0x064E, 0x0652]) {
        expect(n.keyOf('a${cp(c)}b').value, 'ab', reason: c.toRadixString(16));
      }
      expect(n.keyOf('a${cp(0x0653)}b').value, 'a${cp(0x0653)}b');
    });

    test('step 3: deletes Quranic signs U+06D6–U+06ED', () {
      for (final c in [0x06D6, 0x06DC, 0x06ED]) {
        expect(n.keyOf('a${cp(c)}b').value, 'ab', reason: c.toRadixString(16));
      }
      expect(n.keyOf('a${cp(0x06EE)}b').value, 'a${cp(0x06EE)}b');
    });

    test('step 4: has no replacement table of its own', () {
      expect(n.replacements, isEmpty);
    });

    test('step 5: deletes spaces left inside a word', () {
      // A word with an attached pause mark: "a" + space + mark.
      expect(n.keyOf('a ${cp(0x06D6)}').value, 'a');
    });

    test('splits recognized text and drops empty keys', () {
      expect(
        n.keysOfText('ab ${cp(0x06D6)} c${cp(0x064E)}d').map((k) => k.value),
        ['ab', 'cd'],
      );
    });
  });

  group('normalizer.json (docs/tz 12.3)', () {
    test('applies every rule of the table in order', () {
      final n = parse('''
        {
          "id": "test-1",
          "nfc": false,
          "removeRanges": [{"from": "0078", "to": "0079"}],
          "replace": [{"from": "ab", "to": "c"}, {"from": "c", "to": "d"}],
          "wordSeparator": "|"
        }
      ''');
      expect(n.id, const NormalizerId('test-1'));
      // x and y removed, then ab → c → d (order matters).
      expect(n.keyOf('axby').value, 'd');
      expect(n.keyOf('e${cp(0x0301)}').value, 'e${cp(0x0301)}');
      expect(n.keysOfText('ab|zz||y').map((k) => k.value), ['d', 'zz']);
    });

    test('nfc defaults to true, tables default to empty', () {
      final n = parse('{"id": "t", "wordSeparator": " "}');
      expect(n.nfc, isTrue);
      expect(n.keyOf('e${cp(0x0301)}').value, cp(0x00E9));
    });

    test('rejects malformed files', () {
      const reversedRange = '[{"from": "0652", "to": "064B"}]';
      const emptyReplace = '[{"from": "", "to": ""}]';
      for (final bad in [
        '[]',
        '{"wordSeparator": " "}',
        '{"id": "t", "wordSeparator": ""}',
        '{"id": "t", "wordSeparator": " ", "removeRanges": [{"from": "zz"}]}',
        '{"id": "t", "wordSeparator": " ", "removeRanges": $reversedRange}',
        '{"id": "t", "wordSeparator": " ", "replace": $emptyReplace}',
        'not json',
      ]) {
        expect(Normalizer.fromJson(bad), isA<Error<Normalizer>>(), reason: bad);
      }
    });

    test('never changes its input', () {
      const input = 'a b';
      Normalizer.builtIn.keyOf(input);
      expect(input, 'a b');
    });
  });
}
