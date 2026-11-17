import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:eval/eval.dart';
import 'package:follow/follow.dart';
import 'package:path/path.dart' as p;
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

// End-to-end: synthetic recordings built from the canon of surah 78 (P03
// fixture) go through files, follow and the report. Heard words are search
// keys of canonical words; nothing is typed.

const String fixturePath =
    '../../packages/testing/fixtures/content_p582_583.json';
const Normalizer normalizer = Normalizer.builtIn;
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
  String heard(Word w) => quran.searchKey(w.key, normalizer.id).value;

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
    String language = 'kk',
  }) {
    final r = SyntheticRecording(
      id: id,
      speakerId: person,
      from: '${words.first.key}',
      to: '${words.last.key}',
      nativeLanguage: language,
    );
    int? ayah;
    for (final w in words) {
      if (ayah != null && w.key.ayah != ayah) r.endSegment();
      ayah = w.key.ayah;
      if (omit.contains(w.key)) {
        r.omitted('${w.key}');
      } else {
        r.correct('${w.key}', heard(w));
      }
    }
    return r;
  }

  Report evaluate() {
    final recordings = switch (loadCorpus(dir.path, model)) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    return buildReport(
      model: model,
      config: config,
      recordings: [
        for (final r in recordings)
          (
            annotation: r.annotation,
            outcome: runRecording(
              r,
              text: quran,
              normalizer: normalizer,
              params: FollowParams.defaults,
            ),
          ),
      ],
    );
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

  test('a missing ASR file is an error, not a silent skip', () {
    final r = reading('r1', 'p1', ayahs(1, 2));
    File(p.join(dir.path, 'r1.ann.json'))
        .writeAsStringSync(jsonEncode(r.annotationJson()));
    expect(loadCorpus(dir.path, model), isA<Error<List<CorpusRecording>>>());
  });
}
