import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:eval/eval.dart';
import 'package:test/test.dart';

// Hand-made annotations and outcomes with answers known in advance.

WordKey k(int word) => WordKey(78, 1, word);

Annotation annotation(
  Map<int, WordStatus> words, {
  Map<int, (int, int)> corrections = const {},
  String noise = 'quiet',
  List<AnnotatedSpan> insertions = const [],
  List<AnnotatedSpan> jumps = const [],
}) =>
    Annotation(
      recordingId: 'r',
      speaker: const Speaker(id: 'p1', nativeLanguage: 'kk', gender: 'f'),
      device: 'budget-android',
      noise: noise,
      from: k(1),
      to: k(words.length),
      words: [
        for (final e in words.entries)
          AnnotatedWord(
            key: k(e.key),
            status: e.value,
            correctionAfterWords: corrections[e.key]?.$1,
            correctionAfterMs: corrections[e.key]?.$2,
          ),
      ],
      insertions: insertions,
      jumps: jumps,
    );

var _ids = 0;

/// Versions every check event carries (ПО-11, ADR 0003).
const ReadingVersions versions = ReadingVersions(
  modelId: 'fake/scripted',
  modelVersion: '0',
  rulesVersion: 'test',
  textVersion: 'fixture',
);

CheckEvent event(
  CheckKind kind,
  CheckState state,
  List<int> words, {
  String? id,
  int startMs = 0,
  int endMs = 0,
}) =>
    CheckEvent(
      sessionId: 's',
      atMs: endMs,
      eventId: id ?? 'e${_ids++}',
      kind: kind,
      state: state,
      words: [for (final w in words) k(w)],
      expectedText: '',
      heardText: 'heard',
      audioStartMs: startMs,
      audioEndMs: endMs,
      versions: versions,
    );

Counts count(
  Annotation a, {
  Set<int> revealed = const {},
  List<CheckEvent>? events,
}) =>
    Counts.of(
      a,
      RecordingOutcome(
        revealed: {for (final w in revealed) k(w)},
        checkEvents: events,
      ),
      normalNoise: const {'quiet'},
      timeToleranceMs: 500,
    );

const WordStatus c = WordStatus.correct;
const WordStatus om = WordStatus.omitted;
const WordStatus sub = WordStatus.substituted;
const WordStatus sc = WordStatus.selfCorrected;
const WordStatus rep = WordStatus.repeated;
const WordStatus unc = WordStatus.unclear;

void main() {
  group('following metrics', () {
    test('КЧ-01: correct and repeated words revealed, among them', () {
      final a = annotation({1: c, 2: c, 3: rep, 4: c, 5: om});
      final n = count(a, revealed: {1, 2, 3});
      expect(Metric.followRevealedInPlace.ratioIn(n), (3, 4));
      expect(Metric.followRevealedInPlace.valueIn(n), 0.75);
    });

    test('КЧ-02: revealed words that were not read, among revealed', () {
      final a = annotation({1: c, 2: om, 3: sub, 4: c});
      // Word 9 is not in the annotation at all.
      final n = count(a, revealed: {1, 2, 3, 4, 9});
      expect(Metric.followRevealedNotRead.ratioIn(n), (3, 5));
    });

    test('unclear words are left out everywhere', () {
      final a = annotation({1: c, 2: unc});
      final n = count(a, revealed: {1, 2});
      expect(Metric.followRevealedInPlace.ratioIn(n), (1, 1));
      expect(Metric.followRevealedNotRead.ratioIn(n), (0, 1));
    });

    test('no correct words: КЧ-01 has no data', () {
      final n = count(annotation({1: om, 2: om}));
      expect(Metric.followRevealedInPlace.valueIn(n), isNull);
      expect(Metric.followRevealedNotRead.valueIn(n), isNull);
    });
  });

  group('check metrics', () {
    test('no check run: every check metric has no data', () {
      final n = count(annotation({1: c, 2: om}), revealed: {1});
      for (final m in Metric.values.where((m) => m.needsCheck)) {
        expect(m.valueIn(n), isNull, reason: m.name);
      }
      expect(Metric.followRevealedInPlace.valueIn(n), 1);
    });

    test('КЧ-03 precision and КЧ-05 false alarms', () {
      final a = annotation({1: c, 2: om, 3: c, 4: sub, 5: c});
      final n = count(
        a,
        events: [
          event(CheckKind.omission, CheckState.confirmed, [2]), // true
          event(CheckKind.substitution, CheckState.confirmed, [4]), // true
          event(CheckKind.substitution, CheckState.confirmed, [3]), // false
          event(CheckKind.omission, CheckState.preliminary, [5]), // ignored
          event(CheckKind.repetition, CheckState.confirmed, [1]), // signal
        ],
      );
      expect(Metric.precision.ratioIn(n), (2, 3));
      // 1 false alarm on 3 correctly read words → 333.3 per 1000.
      expect(Metric.falseAlarmsPer1000.valueIn(n), closeTo(333.33, 0.01));
    });

    test('the last state of an event counts', () {
      final a = annotation({1: c, 2: om});
      final n = count(
        a,
        events: [
          event(CheckKind.omission, CheckState.preliminary, [1], id: 'x'),
          event(CheckKind.omission, CheckState.unverified, [1], id: 'x'),
        ],
      );
      expect(Metric.precision.valueIn(n), isNull); // nothing confirmed
      expect(Metric.refusalRate.ratioIn(n), (1, 2));
    });

    test('КЧ-04: recall of omissions and substitutions, separately', () {
      final a = annotation({1: om, 2: om, 3: sub, 4: sub, 5: sub, 6: c});
      final n = count(
        a,
        events: [
          event(CheckKind.omission, CheckState.confirmed, [1]),
          event(CheckKind.substitution, CheckState.confirmed, [3, 4]),
          event(CheckKind.omission, CheckState.unverified, [2]),
        ],
      );
      expect(Metric.omissionRecall.ratioIn(n), (1, 2));
      expect(Metric.substitutionRecall.ratioIn(n), (2, 3));
    });

    test('КЧ-04: the kind must match; the other kind finds nothing', () {
      final a = annotation({1: om, 2: sub, 3: c});
      final n = count(
        a,
        events: [
          event(CheckKind.substitution, CheckState.confirmed, [1]),
          event(CheckKind.omission, CheckState.confirmed, [2]),
        ],
      );
      expect(Metric.omissionRecall.ratioIn(n), (0, 1));
      expect(Metric.substitutionRecall.ratioIn(n), (0, 1));
      // Both still mark a real mistake, so precision is not hurt.
      expect(Metric.precision.ratioIn(n), (2, 2));
    });

    test('events on unclear words are left out of the error metrics', () {
      final a = annotation({1: unc, 2: c, 3: c});
      final n = count(
        a,
        events: [
          event(CheckKind.substitution, CheckState.confirmed, [1]),
          event(CheckKind.omission, CheckState.unverified, [1]),
        ],
      );
      expect(Metric.precision.valueIn(n), isNull); // nothing judged
      expect(Metric.falseAlarmsPer1000.valueIn(n), 0);
      expect(Metric.refusalRate.ratioIn(n), (0, 2));
    });

    test('no mistakes at all: precision and recall have no data', () {
      final n = count(annotation({1: c, 2: c}), events: const []);
      expect(Metric.precision.valueIn(n), isNull);
      expect(Metric.omissionRecall.valueIn(n), isNull);
      expect(Metric.substitutionRecall.valueIn(n), isNull);
      expect(Metric.falseAlarmsPer1000.valueIn(n), 0);
      expect(Metric.refusalRate.valueIn(n), 0);
    });

    test('КЧ-06 counts only recordings of normal quality', () {
      final events = [
        event(CheckKind.substitution, CheckState.unverified, [1]),
      ];
      final quiet = count(annotation({1: c, 2: c}), events: events);
      final noisy = count(
        annotation({1: c, 2: c}, noise: 'noisy'),
        events: events,
      );
      expect(Metric.refusalRate.ratioIn(quiet), (1, 2));
      expect(Metric.refusalRate.ratioIn(noisy), (0, 0));
      expect(Metric.refusalRate.valueIn(quiet + noisy), 0.5);
    });

    test('self-correction after the window: the confirmed mistake stands', () {
      // Word 1 corrected at once (in the window), word 2 three words later
      // (outside the default window of 2 words): a new attempt.
      final a = annotation(
        {1: sc, 2: sc, 3: c},
        corrections: {1: (1, 400), 2: (3, 1200)},
      );
      final n = count(
        a,
        events: [
          event(CheckKind.substitution, CheckState.confirmed, [1]),
          event(CheckKind.substitution, CheckState.confirmed, [2]),
        ],
      );
      // Word 1: should have been `corrected` → false alarm. Word 2: true.
      expect(Metric.precision.ratioIn(n), (1, 2));
      // Only the in-window correction can be caught as a correction.
      expect(Metric.selfCorrectionRecall.ratioIn(n), (0, 1));
      // A wider window from thresholds.json makes both in-window.
      final wide = Counts.of(
        a,
        RecordingOutcome(
          revealed: const {},
          checkEvents: [
            event(CheckKind.substitution, CheckState.confirmed, [2]),
          ],
        ),
        normalNoise: const {'quiet'},
        timeToleranceMs: 0,
        window: CorrectionWindow.of(
          CheckParams.fromJson(const {'selfCorrectionWords': 3}),
        ),
      );
      expect(Metric.precision.ratioIn(wide), (0, 1));
    });

    test('КЧ-07: self-corrections found as corrected', () {
      final a = annotation({1: sc, 2: sc, 3: c});
      final n = count(
        a,
        events: [
          event(CheckKind.substitution, CheckState.corrected, [1]),
          event(CheckKind.substitution, CheckState.confirmed, [2]),
        ],
      );
      expect(Metric.selfCorrectionRecall.ratioIn(n), (1, 2));
      // A confirmed mistake on a self-corrected word is not a true one.
      expect(Metric.precision.ratioIn(n), (0, 1));
    });

    test('insertions and jumps are matched by time with tolerance', () {
      final a = annotation(
        {1: c, 2: c},
        insertions: const [AnnotatedSpan(startMs: 1000, endMs: 1400)],
        jumps: const [AnnotatedSpan(startMs: 5000, endMs: 6000)],
      );
      final n = count(
        a,
        events: [
          event(
            CheckKind.insertion,
            CheckState.confirmed,
            [2],
            startMs: 1800,
            endMs: 2000,
          ), // 400 ms after the span: within 500 ms
          event(
            CheckKind.jump,
            CheckState.confirmed,
            [2],
            startMs: 5200,
            endMs: 5600,
          ),
          event(
            CheckKind.insertion,
            CheckState.confirmed,
            [1],
            startMs: 3000,
            endMs: 3200,
          ), // no extra word there
        ],
      );
      expect(Metric.precision.ratioIn(n), (2, 3));
    });

    test('counts add up across recordings', () {
      final a = count(
        annotation({1: om, 2: c}),
        events: [
          event(CheckKind.omission, CheckState.confirmed, [1]),
        ],
      );
      final b = count(annotation({1: om, 2: c}), events: const []);
      expect(Metric.omissionRecall.ratioIn(a + b), (1, 2));
      expect((a + b).hasCheck, isTrue);
      expect((a + count(annotation({1: c}))).hasCheck, isFalse);
    });
  });
}
