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

  group('ADR 0003', () {
    const versions = ReadingVersions(
      modelId: 'abdou/quran-asr-small',
      modelVersion: '1.0.0',
      rulesVersion: '1',
      textVersion: '0.1.0',
    );

    test('ReadingVersions compares by value and writes check_event JSON', () {
      expect(
        versions,
        const ReadingVersions(
          modelId: 'abdou/quran-asr-small',
          modelVersion: '1.0.0',
          rulesVersion: '1',
          textVersion: '0.1.0',
        ),
      );
      expect(versions.toJson(), {
        'model': 'abdou/quran-asr-small@1.0.0',
        'rules': '1',
        'text': '0.1.0',
      });
    });

    test('CheckEvent carries versions (ПО-11)', () {
      const event = CheckEvent(
        sessionId: 's',
        atMs: 10,
        eventId: 'e1',
        kind: CheckKind.omission,
        state: CheckState.preliminary,
        words: [WordKey(78, 1, 1)],
        expectedText: '',
        heardText: '',
        audioStartMs: 0,
        audioEndMs: 10,
        versions: versions,
      );
      expect(event.versions.rulesVersion, '1');
    });

    test('SignalQuality is a session event; optional fields may be absent', () {
      const quality = SignalQuality(
        sessionId: 's',
        atMs: 3000,
        level: SignalQualityLevel.tooQuiet,
      );
      expect(quality, isA<SessionEvent>());
      expect(quality.sinceMs, isNull);
      expect(SignalQualityLevel.values.map((l) => l.name), [
        'ok',
        'tooQuiet',
        'clipping',
        'noisy',
      ]);
    });

    test('an alignment step keeps the heard word as recognized', () {
      const heard = HeardWord(
        index: 0,
        text: 'as heard',
        key: SearchKey('key'),
        segmentId: 1,
        atMs: 400,
      );
      const step = AlignmentStep(
        kind: AlignmentStepKind.match,
        heard: heard,
        cost: 0,
        expected: WordKey(78, 1, 1),
        similarity: 1,
      );
      expect(step.heard.text, 'as heard');
      expect(step.heard.key.isEmpty, isFalse);
      expect(step.skipped, isEmpty);
    });
  });
}
