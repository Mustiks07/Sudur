import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:contracts/contracts.dart';
import 'package:eval/eval.dart';
import 'package:follow/follow.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:quran_text/quran_text.dart';

/// Evaluates following (and checking) on a folder of annotated recordings.
///
/// From the repository root:
/// `dart run tools/eval/bin/eval.dart --corpus <folder> --model <id>`
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'corpus',
      help: 'Folder with <id>.ann.json and <id>.<model>.asr.jsonl.',
    )
    ..addOption('model', help: 'Model id in the .asr.jsonl file names.')
    ..addOption(
      'content',
      help: 'Content JSON from tools/content_build.',
      defaultsTo: 'packages/testing/fixtures/content_p582_583.json',
    )
    ..addOption('normalizer', help: 'normalizer.json of the model package.')
    ..addOption('thresholds', help: 'thresholds.json of the model package.')
    ..addOption(
      'acceptance',
      help: 'Acceptance thresholds and bootstrap settings.',
      defaultsTo: 'tools/eval/config/acceptance.json',
    )
    ..addOption('out', help: 'Report folder. Default: build/eval/<model>.')
    ..addOption('baseline', help: 'Previous report.json to compare with.')
    ..addFlag(
      'ci',
      negatable: false,
      help: 'Exit with 1 if a metric dropped more than allowed vs baseline.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n${parser.usage}');
    exitCode = 64;
    return;
  }
  final corpus = args.option('corpus');
  final model = args.option('model');
  if (args.flag('help') || corpus == null || model == null) {
    stdout.writeln(parser.usage);
    if (!args.flag('help')) exitCode = 64;
    return;
  }

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(
    (r) => (r.level >= Level.SEVERE ? stderr : stdout).writeln(
      '${r.level.name.toLowerCase()}: ${r.message}',
    ),
  );
  final log = Logger('eval');

  try {
    final config = _unwrap(
      AcceptanceConfig.parse(_read(args.option('acceptance'))),
    );
    final normalizerPath = args.option('normalizer');
    final normalizer = normalizerPath == null
        ? Normalizer.builtIn
        : _unwrap(Normalizer.fromJson(_read(normalizerPath)));
    final thresholdsPath = args.option('thresholds');
    final params = thresholdsPath == null
        ? FollowParams.defaults
        : FollowParams.fromJson(_jsonObject(_read(thresholdsPath)));
    final words = _unwrap(
      ContentJsonSource(_read(args.option('content'))).loadWords(),
    );
    final text = InMemoryQuranText(
      words: words,
      normalizers: [normalizer],
      params: SearchParams(ngramSize: params.ngramSize),
    );
    final recordings = _unwrap(loadCorpus(corpus, model));
    log.info('${recordings.length} recordings');

    final evaluated = [
      for (final r in recordings)
        (
          annotation: r.annotation,
          outcome: runRecording(
            r,
            text: text,
            normalizer: normalizer,
            params: params,
          ),
        ),
    ];
    final baselinePath = args.option('baseline');
    final report = buildReport(
      model: model,
      recordings: evaluated,
      config: config,
      baseline: baselinePath == null
          ? null
          : baselineValuesFromJson(_jsonObject(_read(baselinePath))),
    );

    final out = args.option('out') ?? p.join('build', 'eval', model);
    Directory(out).createSync(recursive: true);
    File(p.join(out, 'report.json')).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
    );
    File(p.join(out, 'report.md')).writeAsStringSync(report.toMarkdown());
    log.info(
      'release mode ${report.mode.letter}; '
      '${report.passed ? 'passed' : 'not passed'}; report in $out',
    );

    if (args.flag('ci')) {
      if (baselinePath == null) {
        log.severe('--ci needs --baseline');
        exitCode = 64;
        return;
      }
      final drops = report.regressions(config)..forEach(log.severe);
      if (drops.isNotEmpty) exitCode = 1;
    }
  } on _Failure catch (e) {
    log.severe(e.message);
    exitCode = 1;
  }
}

final class _Failure implements Exception {
  const _Failure(this.message);
  final String message;
}

T _unwrap<T>(Result<T> result) => switch (result) {
      Ok(:final value) => value,
      Error(:final error) => throw _Failure('$error'),
    };

String _read(String? path) {
  if (path == null) throw const _Failure('Missing path');
  try {
    return File(path).readAsStringSync();
  } on FileSystemException catch (e) {
    throw _Failure('Cannot read $path: ${e.message}');
  }
}

Map<String, Object?> _jsonObject(String source) {
  try {
    final value = jsonDecode(source);
    if (value is Map<String, Object?>) return value;
    throw const _Failure('Expected a JSON object');
  } on FormatException catch (e) {
    throw _Failure('Bad JSON: ${e.message}');
  }
}
