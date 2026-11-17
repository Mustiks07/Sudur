import 'dart:io';
import 'dart:math';

import 'package:contracts/contracts.dart';
import 'package:eval/eval.dart';
import 'package:test/test.dart';

AcceptanceConfig loadConfig() => switch (AcceptanceConfig.parse(
      File('config/acceptance.json').readAsStringSync(),
    )) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };

/// A recording of [person] reading words 1..[correct] of 78:1 correctly
/// and revealing [revealed] of them; no checking.
EvaluatedRecording recording(
  String person, {
  required int correct,
  required int revealed,
  String language = 'kk',
}) =>
    (
      annotation: Annotation(
        recordingId: '$person-r',
        speaker: Speaker(id: person, nativeLanguage: language, gender: 'm'),
        device: 'budget-android',
        noise: 'quiet',
        from: const WordKey(78, 1, 1),
        to: WordKey(78, 1, correct),
        words: [
          for (var w = 1; w <= correct; w++)
            AnnotatedWord(key: WordKey(78, 1, w), status: WordStatus.correct),
        ],
      ),
      outcome: RecordingOutcome(
        revealed: {for (var w = 1; w <= revealed; w++) WordKey(78, 1, w)},
      ),
    );

void main() {
  late AcceptanceConfig config;
  setUpAll(() => config = loadConfig());

  group('release mode (docs/tz 5.3)', () {
    Map<Metric, Status> all(Status s) => {for (final m in Metric.values) m: s};

    test('А when everything passes, including groups', () {
      expect(releaseMode(all(Status.pass), [Status.pass]), ReleaseMode.a);
    });

    test('Б when precision and false alarms pass but recall does not', () {
      final s = all(Status.pass)..[Metric.omissionRecall] = Status.fail;
      expect(releaseMode(s, const []), ReleaseMode.b);
      expect(
        releaseMode(all(Status.pass), [Status.fail]),
        ReleaseMode.b,
        reason: 'a failing group also keeps А out',
      );
    });

    test('В when precision fails or has no data', () {
      expect(
        releaseMode(all(Status.pass)..[Metric.precision] = Status.fail, []),
        ReleaseMode.v,
      );
      expect(
        releaseMode(
          all(Status.noData)
            ..[Metric.followRevealedInPlace] = Status.pass
            ..[Metric.followRevealedNotRead] = Status.pass,
          [],
        ),
        ReleaseMode.v,
      );
    });

    test('Г when following fails', () {
      expect(
        releaseMode(
          all(Status.pass)..[Metric.followRevealedNotRead] = Status.fail,
          [],
        ),
        ReleaseMode.g,
      );
    });
  });

  group('bootstrap by people (КЧ-09)', () {
    test('one person: the interval is the point value', () {
      final c = Counts.of(
        recording('p1', correct: 10, revealed: 9).annotation,
        recording('p1', correct: 10, revealed: 9).outcome,
        normalNoise: const {'quiet'},
        timeToleranceMs: 0,
      );
      final ci = bootstrapByPeople(
        [c],
        samples: 50,
        confidence: 0.95,
        random: Random(1),
      );
      expect(ci[Metric.followRevealedInPlace], (0.9, 0.9));
      expect(ci.containsKey(Metric.precision), isFalse);
    });

    test('resamples people, so the interval spans their rates', () {
      Counts of(EvaluatedRecording r) => Counts.of(
            r.annotation,
            r.outcome,
            normalNoise: const {'quiet'},
            timeToleranceMs: 0,
          );
      // One person with many words and a low rate, one with few words and a
      // high rate: resampling by people moves the pooled rate a lot.
      final people = [
        of(recording('p1', correct: 100, revealed: 50)),
        of(recording('p2', correct: 10, revealed: 10)),
      ];
      final (low, high) = bootstrapByPeople(
        people,
        samples: 500,
        confidence: 0.95,
        random: Random(7),
      )[Metric.followRevealedInPlace]!; // Has data in every sample.
      expect(low, 0.5);
      expect(high, 1.0);
    });

    test('the same seed gives the same report', () {
      final recs = [
        recording('p1', correct: 20, revealed: 19),
        recording('p2', correct: 20, revealed: 20),
        recording('p3', correct: 20, revealed: 17),
      ];
      String run() => buildReport(
            model: 'm',
            recordings: recs,
            config: config,
          ).toJson().toString();
      expect(run(), run());
    });
  });

  group('report', () {
    test('groups, statuses, and check metrics without data', () {
      final report = buildReport(
        model: 'm',
        recordings: [
          recording('p1', correct: 50, revealed: 50),
          recording('p2', correct: 50, revealed: 49, language: 'ru'),
        ],
        config: config,
      );
      expect(report.people, 2);
      final inPlace = report.metrics[Metric.followRevealedInPlace]!;
      expect(inPlace.value.value, 0.99);
      expect(inPlace.status, Status.pass);
      expect(report.metrics[Metric.precision]!.status, Status.noData);
      expect(report.mode, ReleaseMode.v);
      expect(report.groups['nativeLanguage']!.keys, ['kk', 'ru']);
      expect(
        report.groups['nativeLanguage']!['ru']![Metric.followRevealedInPlace]!
            .value,
        0.98,
      );
      final md = report.toMarkdown();
      expect(md, contains('Режим выпуска: **В**'));
      expect(md, contains('нет данных'));
      expect(md, contains('≥ 98.0%'));
    });

    test('compares with a baseline and catches regressions (5.5)', () {
      final before = buildReport(
        model: 'm',
        recordings: [recording('p1', correct: 100, revealed: 100)],
        config: config,
      );
      final baseline = baselineValuesFromJson(before.toJson());
      expect(baseline[Metric.followRevealedInPlace], 1.0);
      expect(baseline[Metric.precision], isNull);

      final slightlyWorse = buildReport(
        model: 'm',
        recordings: [recording('p1', correct: 100, revealed: 99)],
        config: config,
        baseline: baseline,
      );
      expect(
        slightlyWorse.changes[Metric.followRevealedInPlace],
        closeTo(-1, 1e-9),
      );
      expect(slightlyWorse.regressions(config), isEmpty); // 1 p.p. allowed

      final worse = buildReport(
        model: 'm',
        recordings: [recording('p1', correct: 100, revealed: 97)],
        config: config,
        baseline: baseline,
      );
      expect(worse.regressions(config).single, contains('КЧ-01'));
      expect(worse.toMarkdown(), contains('-3.00 п. п.'));
    });

    test('config rejects a threshold without bounds', () {
      final bad = File('config/acceptance.json')
          .readAsStringSync()
          .replaceFirst('"precision": { "min": 0.95 }', '"precision": {}');
      expect(AcceptanceConfig.parse(bad), isA<Error<AcceptanceConfig>>());
    });
  });
}
