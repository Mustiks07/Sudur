import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:content_build/content_build.dart';
import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';

/// Builds the derived data (default passages, similar places) from the
/// text fixtures, without the network, and prints a report.
///
/// From the repository root:
/// `dart run tools/content_build/bin/derive.dart --out packages/testing/fixtures/derived.json`
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'text',
      defaultsTo: 'packages/testing/fixtures/quran_text.json',
      help: 'Whole-Quran text (format 2).',
    )
    ..addOption(
      'pages',
      defaultsTo: 'packages/testing/fixtures/content_p582_583.json',
      help: 'Pages with layout (format 1), for the page rules.',
    )
    ..addOption(
      'params',
      defaultsTo: 'tools/content_build/config/derived.json',
    )
    ..addOption('lines-per-page', defaultsTo: '15')
    ..addOption('out', help: 'Write derived.json here.')
    ..addFlag('report', defaultsTo: true, help: 'Print counts and examples.');
  final args = parser.parse(arguments);

  final textJson = File(args.option('text')!).readAsStringSync(); // Default.
  final words = switch (QuranTextJsonSource(textJson).loadWords()) {
    Ok(:final value) => value,
    Error(:final error) => throw error,
  };
  final params = DerivedParams.fromJson(
    File(args.option('params')!).readAsStringSync(), // Default.
  );
  final derived = deriveContent(
    ayahs: ayahSpansOf(words),
    words: words,
    layout: layoutPlacesFromJson(
      File(args.option('pages')!).readAsStringSync(), // Default.
    ),
    linesPerPage: int.parse(args.option('lines-per-page')!), // Default.
    params: params,
  );
  final canon = switch (jsonDecode(textJson)) {
    {'contentVersion': {'canonSha256': final String sum}} => sum,
    _ => 'unknown',
  };
  final json = derived.toJson(canonSha256: canon);
  if (args.option('out') case final out?) {
    File(out).writeAsStringSync(json);
  }
  if (args.flag('report')) {
    stdout
        .write(derivedReport(derived, words, bytes: utf8.encode(json).length));
  }
}
