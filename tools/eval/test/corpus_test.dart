import 'dart:convert';
import 'dart:io';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:eval/eval.dart';
import 'package:follow/follow.dart';
import 'package:path/path.dart' as p;
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

import '../tool/build_reference.dart';

// End-to-end: synthetic recordings built from the canon of surah 78 (P03
// fixture) go through files, follow and the report. Heard words are search
// keys of canonical words; nothing is typed.

const String fixturePath =
    '../../packages/testing/fixtures/content_p582_583.json';
// The model's normalizer.json from docs/tz 12.3; heard words are model
// output (29 bare letters), not canonical keys.
final Normalizer normalizer = loadModelNormalizer();
const String model = 'synthetic';

void main() {
  late InMemoryQuranText quran;
  late AcceptanceConfig config;
  late Directory dir;

  setUpAll(() {
    final words = switch (ContentJsonSource(
      File(fixturePath).readAsStringSync(),
    ).loadWords()) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    quran = InMemoryQuranText(
      words: words,
      normalizers: [normalizer],
      params: SearchParams.defaults,
    );
    config = switch (AcceptanceConfig.parse(
      File('config/acceptance.json').readAsStringSync(),
    )) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('eval'));
  tearDown(() => dir.deleteSync(recursive: true));

  List<Word> ayahs(int first, int last) => quran.words
      .where(
        (w) => w.key.surah == 78 && w.key.ayah >= first && w.key.ayah <= last,
      )
      .toList();
  String heard(Word w) => modelLetters(w.text);

  void save(SyntheticRecording r) {
    File(p.join(dir.path, '${r.id}.ann.json'))
        .writeAsStringSync(jsonEncode(r.annotationJson()));
    File(p.join(dir.path, '${r.id}.$model.asr.jsonl')).writeAsStringSync(
      r.script.results
          .map((x) => jsonEncode(recognitionResultToJson(x)))
          .join('\n'),
    );
  }

  /// Reads [words] ayah by ayah; [omit] word keys are not read.
  SyntheticRecording reading(
    String id,
    String person,
    List<Word> words, {
    Set<WordKey> omit = const {},
    Map<WordKey, String> substitute = const {},
    Map<WordKey, String> selfCorrect = const {},
    String language = 'kk',
    String gender = 'f',
    String device = 'budget-android',
    String noise = 'quiet',
  }) {
    final r = SyntheticRecording(
      modelOutput: true,
      id: id,
      speakerId: person,
      from: '${words.first.key}',
      to: '${words.last.key}',
      nativeLanguage: language,
      gender: gender,
      device: device,
      noise: noise,
    );
    int? ayah;
    for (final w in words) {
      if (ayah != null && w.key.ayah != ayah) r.endSegment();
      ayah = w.key.ayah;
      final wrong = substitute[w.key];
      final misread = selfCorrect[w.key];
      if (omit.contains(w.key)) {
        r.omitted('${w.key}');
      } else if (wrong != null) {
        r.substituted('${w.key}', wrong);
      } else if (misread != null) {
        r.selfCorrected('${w.key}', misread, heard(w));
      } else {
        r.correct('${w.key}', heard(w));
      }
    }
    return r;
  }

  Report evaluate({bool withCheck = false, AcceptanceConfig? using}) {
    final recordings = switch (loadCorpus(dir.path, model)) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    return buildReport(
      model: model,
      config: using ?? config,
      recordings: [
        for (final r in recordings)
          (
            annotation: r.annotation,
            outcome: runRecording(
              r,
              text: quran,
              normalizer: normalizer,
              params: FollowParams.defaults,
              check: withCheck
                  ? const CheckSetup(
                      params: CheckParams.defaults,
                      rulesVersion: 'test',
                      textVersion: 'fixture',
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  /// A key of surah 78 not similar (below simFloor) to [w] or the words
  /// around it, so the reader clearly said another word.
  String unrelatedTo(Word w) {
    final surah = [
      for (final x in quran.words)
        if (x.key.surah == 78) x,
    ];
    final i = surah.indexOf(w);
    final around = surah.sublist(i - 8 < 0 ? 0 : i - 8, i + 6);
    return surah.map(heard).firstWhere(
          (k) => around.every(
            (a) => similarity(k, heard(a)) < FollowParams.defaults.simFloor,
          ),
        );
  }

  /// [w]'s key with one middle letter dropped: a near miss to self-correct.
  String nearMiss(Word w) {
    final k = heard(w);
    return dropLetter(k, k.runes.length ~/ 2);
  }

  test('ASR JSONL round-trips every field', () {
    final script = RecognitionScript()..segment(['a', 'b']);
    final line = jsonEncode(recognitionResultToJson(script.results.last));
    final back = switch (parseAsrJsonl('$line\n\n')) {
      Ok(:final value) => value.single,
      Error(:final error) => throw error,
    };
    expect(
      recognitionResultToJson(back),
      recognitionResultToJson(
        script.results.last,
      ),
    );
    expect(parseAsrJsonl('{"x": 1}'), isA<Error<List<RecognitionResult>>>());
  });

  test('clean readings by several people: following passes, mode В', () {
    save(reading('r1', 'p1', ayahs(1, 10)));
    save(reading('r2', 'p2', ayahs(11, 20), language: 'ru'));
    save(reading('r3', 'p1', ayahs(21, 30)));
    final report = evaluate();
    expect(report.recordings, 3);
    expect(report.people, 2);
    final inPlace = report.metrics[Metric.followRevealedInPlace]!;
    expect(inPlace.value.value, 1.0);
    expect(inPlace.status, Status.pass);
    expect(report.metrics[Metric.followRevealedNotRead]!.value.value, 0.0);
    // Check (S04) does not run yet: its metrics have no data.
    expect(report.metrics[Metric.precision]!.status, Status.noData);
    expect(report.mode, ReleaseMode.v);
  });

  test('omitted words: not revealed, and not counted as missed reveals', () {
    final words = ayahs(12, 16);
    final omit = {words[3].key, words[9].key};
    save(reading('r1', 'p1', words, omit: omit));
    final report = evaluate();
    final inPlace = report.metrics[Metric.followRevealedInPlace]!.value;
    expect(inPlace.denominator, words.length - omit.length);
    expect(inPlace.value, 1.0);
    expect(report.metrics[Metric.followRevealedNotRead]!.value.numerator, 0);
  });

  test('with check: known mistakes found in every required group → mode А', () {
    // Three people cover every required group of КЧ-08 (acceptance.json):
    // ru/kk/uz, m/f, budget-android/mid-android/iphone, quiet/noisy — and
    // each group value has at least one confirmed mistake.
    final a = ayahs(1, 12);
    final b = ayahs(13, 24);
    final c = ayahs(25, 36);
    save(reading('r1', 'p1', a, omit: {a[5].key, a[20].key}));
    save(
      reading(
        'r2',
        'p2',
        b,
        substitute: {b[6].key: unrelatedTo(b[6])},
        language: 'ru',
        gender: 'm',
        device: 'mid-android',
        noise: 'noisy',
      ),
    );
    save(
      reading(
        'r3',
        'p3',
        c,
        omit: {c[20].key},
        selfCorrect: {c[8].key: nearMiss(c[8])},
        language: 'uz',
        device: 'iphone',
      ),
    );
    final report = evaluate(withCheck: true);
    double? value(Metric m) => report.metrics[m]!.value.value;
    expect(value(Metric.precision), 1.0);
    expect(report.metrics[Metric.precision]!.value.denominator, 4);
    expect(value(Metric.omissionRecall), 1.0);
    expect(value(Metric.substitutionRecall), 1.0);
    expect(value(Metric.falseAlarmsPer1000), 0.0);
    expect(value(Metric.selfCorrectionRecall), 1.0);
    expect(value(Metric.refusalRate), 0.0);
    expect(value(Metric.followRevealedInPlace), 1.0);
    expect(report.missingGroups, isEmpty);
    for (final MapEntry(:key, value: required)
        in config.requiredGroups.entries) {
      for (final v in required) {
        expect(report.groupStatuses[key]![v], Status.pass, reason: '$key=$v');
      }
    }
    expect(report.mode, ReleaseMode.a);
    expect(report.passed, isTrue);
  });

  test('required groups missing from the corpus: no data, never mode А', () {
    // Only women, budget Android, quiet — every present group passes, yet
    // men, noise, other phones and languages are not checked at all.
    final a = ayahs(1, 12);
    final b = ayahs(13, 24);
    save(
      reading(
        'r1',
        'p1',
        a,
        omit: {a[5].key, a[20].key},
        selfCorrect: {a[12].key: nearMiss(a[12])},
      ),
    );
    save(reading('r2', 'p2', b, substitute: {b[6].key: unrelatedTo(b[6])}));
    final report = evaluate(withCheck: true);
    // Every overall metric passes: only the missing groups keep А out.
    for (final MapEntry(key: m, value: r) in report.metrics.entries) {
      expect(r.status, Status.pass, reason: m.name);
    }
    expect(report.groupStatuses['gender']!['f'], Status.pass);
    expect(report.groupStatuses['gender']!['m'], Status.noData);
    expect(report.groupStatuses['noise']!['noisy'], Status.noData);
    expect(report.groupRecordings['gender']!['m'], 0);
    expect(
      report.missingGroups,
      containsAll([
        'nativeLanguage=ru',
        'nativeLanguage=uz',
        'gender=m',
        'device=mid-android',
        'device=iphone',
        'noise=noisy',
      ]),
    );
    expect(report.mode, isNot(ReleaseMode.a));
    expect(report.passed, isFalse);
    expect(report.toMarkdown(), contains('Нет записей в обязательных группах'));
    final json = report.toJson();
    expect(json['missingGroups'], contains('gender=m'));

    // The bug: checking only the groups found in the corpus (no required
    // values) passed this very corpus as mode А.
    final onlyPresent = switch (AcceptanceConfig.parse(
      File('config/acceptance.json').readAsStringSync().replaceAllMapped(
            RegExp(r'"(nativeLanguage|gender|device|noise)": \[[^\]]*\]'),
            (m) => '"${m[1]}": []',
          ),
    )) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    expect(evaluate(withCheck: true, using: onlyPresent).mode, ReleaseMode.a);
  });

  test('a recording without recognition results does not disable check', () {
    final a = ayahs(1, 12);
    save(reading('r1', 'p1', a, omit: {a[5].key}));
    final silent = reading('r2', 'p2', ayahs(13, 14));
    File(p.join(dir.path, 'r2.ann.json'))
        .writeAsStringSync(jsonEncode(silent.annotationJson()));
    File(p.join(dir.path, 'r2.$model.asr.jsonl')).writeAsStringSync('');
    final report = evaluate(withCheck: true);
    expect(report.recordings, 2);
    expect(report.metrics[Metric.precision]!.value.value, 1.0);
    expect(report.metrics[Metric.omissionRecall]!.value.value, 1.0);
  });

  test('a group without any mistake has no precision: not mode А', () {
    final a = ayahs(1, 12);
    save(reading('r1', 'p1', a, omit: {a[5].key}));
    save(reading('r2', 'p2', ayahs(13, 20), language: 'ru'));
    final report = evaluate(withCheck: true);
    expect(report.metrics[Metric.precision]!.status, Status.pass);
    expect(report.groupStatuses['nativeLanguage']!['ru'], Status.noData);
    expect(report.mode, ReleaseMode.b);
  });

  test('without check its metrics have no data', () {
    final a = ayahs(1, 6);
    save(reading('r1', 'p1', a, omit: {a[5].key}));
    final report = evaluate();
    expect(report.metrics[Metric.precision]!.status, Status.noData);
    expect(report.metrics[Metric.omissionRecall]!.status, Status.noData);
  });

  test('check events carry the versions of the run (ПО-11)', () {
    final words = ayahs(1, 8);
    final recording = reading('r1', 'p1', words, omit: {words[5].key});
    save(recording);
    final loaded = switch (loadCorpus(dir.path, model)) {
      Ok(:final value) => value.single,
      Error(:final error) => throw error,
    };
    final outcome = runRecording(
      loaded,
      text: quran,
      normalizer: normalizer,
      params: FollowParams.defaults,
      check: const CheckSetup(
        params: CheckParams.defaults,
        rulesVersion: 'rules-7',
        textVersion: 'text-3',
      ),
    );
    final events = outcome.checkEvents!; // Check ran.
    expect(events, isNotEmpty);
    for (final e in events) {
      expect(e.versions.rulesVersion, 'rules-7');
      expect(e.versions.textVersion, 'text-3');
      expect(e.versions.modelId, scriptedRecognizerInfo.modelId);
    }
  });

  test('a missing ASR file is an error, not a silent skip', () {
    final r = reading('r1', 'p1', ayahs(1, 2));
    File(p.join(dir.path, 'r1.ann.json'))
        .writeAsStringSync(jsonEncode(r.annotationJson()));
    expect(loadCorpus(dir.path, model), isA<Error<List<CorpusRecording>>>());
  });
}
