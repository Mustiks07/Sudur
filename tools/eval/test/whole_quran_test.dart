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

// S03: synthetic recordings with jumps across the whole Quran (ADR 0004
// text fixture). Heard words are search keys of canonical words, picked by
// their place in the text; nothing is typed.

const String textPath = '../../packages/testing/fixtures/quran_text.json';
const String pagesPath =
    '../../packages/testing/fixtures/content_p582_583.json';
const Normalizer normalizer = Normalizer.builtIn;
const String model = 'synthetic';

InMemoryQuranText load(String path) {
  final words = switch (loadContentWords(File(path).readAsStringSync())) {
    Ok(:final value) => value,
    Error(:final error) => throw error,
  };
  return InMemoryQuranText(
    words: words,
    normalizers: [normalizer],
    params: SearchParams.defaults,
  );
}

void main() {
  late InMemoryQuranText quran;
  late InMemoryQuranText pages;
  late AcceptanceConfig config;
  late Directory dir;

  setUpAll(() {
    quran = load(textPath);
    pages = load(pagesPath);
    config = switch (AcceptanceConfig.parse(
      File('config/acceptance.json').readAsStringSync(),
    )) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('eval-quran'));
  tearDown(() => dir.deleteSync(recursive: true));

  List<Word> ayah(int surah, int number) => [
        for (final w in quran.words)
          if (w.key.surah == surah && w.key.ayah == number) w,
      ];
  List<Word> ayahs(int surah, int first, int last) => [
        for (var a = first; a <= last; a++) ...ayah(surah, a),
      ];
  String heard(Word w) => quran.searchKey(w.key, normalizer.id).value;
  String misheard(Word w) {
    final k = heard(w);
    return k.runes.length >= 5 ? dropLetter(k, k.runes.length ~/ 2) : k;
  }

  void save(SyntheticRecording r) {
    File(p.join(dir.path, '${r.id}.ann.json'))
        .writeAsStringSync(jsonEncode(r.annotationJson()));
    File(p.join(dir.path, '${r.id}.$model.asr.jsonl')).writeAsStringSync(
      r.script.results
          .map((x) => jsonEncode(recognitionResultToJson(x)))
          .join('\n'),
    );
  }

  /// Reads [before] ayah by ayah, jumps to [elsewhere] (heard via [say]),
  /// comes back and reads [after]. The expected range is [before]+[after].
  SyntheticRecording withJump(
    String id,
    String person,
    List<Word> before,
    List<Word> elsewhere,
    List<Word> after, {
    String Function(Word)? say,
  }) {
    final r = SyntheticRecording(
      id: id,
      speakerId: person,
      from: '${before.first.key}',
      to: '${after.isEmpty ? before.last.key : after.last.key}',
    );
    void read(List<Word> words) {
      int? current;
      for (final w in words) {
        if (current != null && w.key.ayah != current) r.endSegment();
        current = w.key.ayah;
        r.correct('${w.key}', heard(w));
      }
      r.endSegment();
    }

    read(before);
    if (elsewhere.isNotEmpty) {
      r
        ..jumped(
          '${before.last.key}',
          '${elsewhere.first.key}',
          elsewhere.map(say ?? heard).toList(),
        )
        ..endSegment();
    }
    read(after);
    return r;
  }

  SyntheticRecording clean(String id, String person, List<Word> words) =>
      withJump(id, person, words, const [], const []);

  Report evaluate(InMemoryQuranText text, {bool withCheck = true}) {
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
              text: text,
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

  test('the content loader reads both fixture formats', () {
    expect(quran.words, hasLength(77433));
    expect(pages.words.first.key, const WordKey(78, 1, 1));
    expect(
      contentTextVersion(File(textPath).readAsStringSync()),
      isNot('unknown'),
    );
  });

  test('jumps across the Quran: nothing revealed there, jumps confirmed', () {
    // A far surah, misheard letters, and coming back to the passage.
    save(
      withJump(
        'j1',
        'p1',
        ayahs(78, 1, 3),
        ayah(2, 255).take(8).toList(),
        ayahs(78, 4, 10),
      ),
    );
    save(
      withJump(
        'j2',
        'p2',
        ayahs(78, 20, 22),
        ayahs(36, 12, 13),
        ayahs(78, 23, 28),
        say: misheard,
      ),
    );
    save(clean('c1', 'p3', ayahs(78, 30, 40)));
    final report = evaluate(quran);
    double? value(Metric m) => report.metrics[m]!.value.value;
    expect(value(Metric.followRevealedInPlace), 1.0);
    expect(value(Metric.followRevealedNotRead), 0.0);
    expect(report.metrics[Metric.precision]!.value.numerator, greaterThan(0));
    expect(value(Metric.precision), 1.0);
    expect(value(Metric.falseAlarmsPer1000), 0.0);
  });

  test('a look-alike ayah in another surah: no reveal in the passage', () {
    // A 4-word window outside surah 78 that resembles a window later in the
    // passage (from 78:20) but is not the same.
    final keys = quran.keysFor(normalizer.id);
    final surah = ayahs(78, 1, 40);
    final start = quran.words.indexOf(surah.first);
    final later = surah.indexWhere((w) => w.key == const WordKey(78, 20, 1));
    List<Word>? lookAlike;
    late Word inside;
    for (var i = later; i + 4 <= surah.length && lookAlike == null; i++) {
      for (final m in quran.findSimilar(
        keys.sublist(start + i, start + i + 4),
        normalizer: normalizer.id,
        minSimilarity: FollowParams.defaults.simFloor,
        maxMeanCost: FollowParams.defaults.lostCostThreshold,
      )) {
        if (m.start.surah != 78 &&
            m.meanCost >= FollowParams.defaults.ambiguityMargin) {
          final at = quran.words.indexWhere((w) => w.key == m.start);
          lookAlike = quran.words.sublist(at, at + 4);
          inside = surah[i];
          break;
        }
      }
    }
    expect(lookAlike, isNotNull, reason: 'surah 78 has a look-alike elsewhere');
    save(
      withJump(
        'l1',
        'p1',
        ayahs(78, 1, 3),
        lookAlike!, // Checked just above.
        ayahs(78, 4, 10),
      ),
    );
    final report = evaluate(quran);
    expect(report.metrics[Metric.followRevealedInPlace]!.value.value, 1.0);
    expect(
      report.metrics[Metric.followRevealedNotRead]!.value.value,
      0.0,
      reason: 'words from ${inside.key} on were not read',
    );
    expect(report.metrics[Metric.falseAlarmsPer1000]!.value.value, 0.0);
  });

  test('repeated ayahs of surah 55: clean reading revealed in place', () {
    save(clean('r55', 'p1', ayahs(55, 1, 30)));
    final report = evaluate(quran);
    expect(report.metrics[Metric.followRevealedInPlace]!.value.value, 1.0);
    expect(report.metrics[Metric.followRevealedNotRead]!.value.value, 0.0);
    expect(report.metrics[Metric.falseAlarmsPer1000]!.value.value, 0.0);
  });

  test('КЧ-01 and КЧ-02 on surah 78 are not worse with the whole Quran', () {
    save(clean('c1', 'p1', ayahs(78, 1, 13)));
    save(clean('c2', 'p2', ayahs(78, 14, 27)));
    save(clean('c3', 'p3', ayahs(78, 28, 40)));
    save(
      withJump(
        'j1',
        'p1',
        ayahs(78, 1, 3),
        ayahs(79, 1, 4),
        ayahs(78, 4, 8),
      ),
    );
    final onPages = evaluate(pages);
    final onQuran = evaluate(quran);
    for (final m in [
      Metric.followRevealedInPlace,
      Metric.followRevealedNotRead,
    ]) {
      expect(
        onQuran.metrics[m]!.value.value,
        onPages.metrics[m]!.value.value,
        reason: m.name,
      );
      expect(onQuran.metrics[m]!.status, Status.pass, reason: m.name);
    }
  });
}
