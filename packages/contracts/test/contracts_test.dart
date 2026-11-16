import 'package:contracts/contracts.dart';
import 'package:test/test.dart';

void main() {
  group('WordKey', () {
    test('parses and prints surah:ayah:word', () {
      final key = WordKey.parse('2:255:3');
      expect(key, equals(const WordKey(2, 255, 3)));
      expect(key.toString(), equals('2:255:3'));
    });

    test('orders by surah, then ayah, then word', () {
      final keys = [
        const WordKey(2, 1, 1),
        const WordKey(1, 7, 9),
        const WordKey(1, 7, 2),
      ]..sort();
      expect(keys.map((k) => k.toString()), ['1:7:2', '1:7:9', '2:1:1']);
    });

    test('rejects malformed input', () {
      expect(() => WordKey.parse('2:255'), throwsFormatException);
    });
  });

  group('Result', () {
    test('ok and error are distinguished by pattern matching', () {
      const results = <Result<int>>[
        Result.ok(1),
        Result.error(FormatException()),
      ];
      final described = results.map(
        (r) => switch (r) {
          Ok(:final value) => 'ok $value',
          Error() => 'error',
        },
      );
      expect(described, ['ok 1', 'error']);
    });
  });
}
