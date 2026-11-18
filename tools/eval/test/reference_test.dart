import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:eval/eval.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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
