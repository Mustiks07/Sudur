import 'dart:typed_data';

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

  group('ADR 0005', () {
    const versions = ReadingVersions(
      modelId: 'model',
      modelVersion: '1',
      rulesVersion: '2',
      textVersion: '3',
    );

    test('screen commands carry the fields from section 4.5', () {
      const start = StartSession(
        fromWordKey: WordKey(78, 1, 1),
        toWordKey: WordKey(78, 2, 3),
        mode: SessionMode.recall,
        behavior: SessionBehavior.strict,
      );
      expect(start.fromWordKey, const WordKey(78, 1, 1));
      expect(start.toWordKey, const WordKey(78, 2, 3));
      expect(start.mode, SessionMode.recall);
      expect(start.behavior, SessionBehavior.strict);
      expect(const Pause(), isA<SessionCommand>());
      expect(const Resume(), isA<SessionCommand>());
      expect(const Stop(), isA<SessionCommand>());
      expect(
        const RequestHint(kind: HintKind.wholeAyah).kind,
        HintKind.wholeAyah,
      );
      expect(const DisputeEvent(eventId: 'e1').eventId, 'e1');
    });

    test('new session events carry their required fields', () {
      const started = SessionStarted(
        sessionId: 's1',
        atMs: 0,
        fromWordKey: WordKey(78, 1, 1),
        toWordKey: WordKey(78, 1, 5),
        mode: SessionMode.supported,
        versions: versions,
      );
      const hint = HintGiven(
        sessionId: 's1',
        atMs: 1200,
        kind: HintKind.word,
        wordKey: WordKey(78, 1, 2),
      );
      const changed = CheckStateChanged(
        sessionId: 's1',
        atMs: 1300,
        eventId: 'e1',
        from: CheckState.preliminary,
        to: CheckState.confirmed,
        reason: 'contextConfirmed',
      );
      const finished = SessionFinished(
        sessionId: 's1',
        atMs: 2000,
        words: [
          SessionWordResult(
            wordKey: WordKey(78, 1, 1),
            outcome: SessionWordOutcome.read,
          ),
        ],
        eventIds: ['e1'],
        durationMs: 2000,
        audioWasSuitable: true,
      );
      expect(started.versions, versions);
      expect(hint.kind, HintKind.word);
      expect(changed.to, CheckState.confirmed);
      expect(finished.words.single.outcome, SessionWordOutcome.read);
      expect(finished.audioWasSuitable, isTrue);
    });

    test('audio input is typed and keeps absolute frame time', () {
      final samples = Float32List.fromList([0.1, -0.1]);
      final frame = SessionAudioFrame(
        atMs: 30,
        segmentId: 4,
        samples: samples,
        sampleRateHz: 16000,
        startMs: 20,
        endMs: 30,
      );
      const quality = SignalQuality(
        sessionId: 's1',
        atMs: 30,
        level: SignalQualityLevel.ok,
      );
      expect(frame, isA<SessionAudioEvent>());
      expect(frame.startMs, 20);
      expect(frame.endMs, 30);
      expect(quality, isA<SessionAudioEvent>());
      expect(
        const SessionAudioSegmentOpened(
          atMs: 500,
          segmentId: 4,
          pauseBeforeMs: 300,
        ).pauseBeforeMs,
        300,
      );
    });

    test('word outcomes exactly cover the section 10.6 summary', () {
      expect(SessionWordOutcome.values.map((value) => value.name), [
        'read',
        'readWithHint',
        'error',
        'corrected',
        'unverified',
        'notRead',
      ]);
    });
  });
}
