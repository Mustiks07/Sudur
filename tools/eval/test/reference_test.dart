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

// The reference corpus of the CI quality gate (C09) is generated: the
// committed files must be exactly what the generator gives, so nobody edits
// them by hand.

void main() {
  test('the committed reference corpus is what the generator gives', () {
    final built = buildReferenceCorpus(loadText());
    final files = Directory(referenceCorpus)
        .listSync()
        .whereType<File>()
        .map((f) => p.basename(f.path))
        .toSet();
    expect(files, hasLength(built.length * 2));
    for (final r in built) {
      expect(
        File(p.join(referenceCorpus, '${r.id}.ann.json')).readAsStringSync(),
        '${const JsonEncoder.withIndent('  ').convert(r.annotationJson())}\n',
        reason: r.id,
      );
      expect(
        File(p.join(referenceCorpus, '${r.id}.$referenceModel.asr.jsonl'))
            .readAsStringSync(),
        asrJsonl(r),
        reason: r.id,
      );
    }
  });

  test('the model normalizer of the spec turns every word into model output',
      () {
    // Two independent implementations of docs/tz 12.3 agree on the whole
    // text: normalizer.json (quran_text) and modelLetters (testing).
    final text = loadText();
    final normalizer = loadModelNormalizer();
    for (final w in text.words) {
      expect(
        text.searchKey(w.key, normalizer.id).value,
        modelLetters(w.text),
        reason: '${w.key}',
      );
    }
  });

  test('the old normalizer (empty removeRanges) fails the gate', () {
    final config = switch (AcceptanceConfig.parse(
      File('config/acceptance.json').readAsStringSync(),
    )) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    final old = jsonDecode(File(modelNormalizerPath).readAsStringSync())
        as Map<String, Object?>
      ..['id'] = 'old-empty-ranges'
      ..['removeRanges'] = <Object?>[];
    final oldNormalizer = switch (Normalizer.fromJson(jsonEncode(old))) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    final words = loadText().words;
    final text = InMemoryQuranText(
      words: words,
      normalizers: [oldNormalizer],
      params: SearchParams.defaults,
    );
    final recordings = switch (loadCorpus(referenceCorpus, referenceModel)) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    final report = buildReport(
      model: referenceModel,
      config: config,
      baseline: baselineValuesFromJson(
        jsonDecode(File('reference/report.json').readAsStringSync())
            as Map<String, Object?>,
      ),
      recordings: [
        for (final r in recordings)
          (
            annotation: r.annotation,
            outcome: runRecording(
              r,
              text: text,
              normalizer: oldNormalizer,
              params: FollowParams.defaults,
              check: const CheckSetup(
                params: CheckParams.defaults,
                rulesVersion: 'test',
                textVersion: 'test',
              ),
            ),
          ),
      ],
    );
    // Words never open — what the owner saw on the phone.
    expect(report.metrics[Metric.followRevealedInPlace]!.value.value, 0);
    expect(
      report.regressions(config),
      contains(contains('КЧ-01')),
    );
  });

  test('the reference corpus is model output only', () {
    for (final r in buildReferenceCorpus(loadText())) {
      for (final x in r.script.results) {
        expect(isModelOutput(x.text), isTrue, reason: r.id);
      }
    }
  });

  test('the baseline report covers every metric the gate checks', () {
    final config = switch (AcceptanceConfig.parse(
      File('config/acceptance.json').readAsStringSync(),
    )) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    final baseline = baselineValuesFromJson(
      jsonDecode(File('reference/report.json').readAsStringSync())
          as Map<String, Object?>,
    );
    for (final m in config.maxDropPp.keys) {
      expect(baseline[m], isNotNull, reason: m.code);
    }
  });
}
