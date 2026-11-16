import 'dart:io';

import 'package:args/args.dart';
import 'package:content_build/content_build.dart';
import 'package:contracts/contracts.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Builds a content package from scratch.
///
/// From the repository root:
/// `dart run tools/content_build/bin/content_build.dart`
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'config',
      help: 'Build config, relative to the repository root.',
      defaultsTo: 'tools/content_build/config/prototype.json',
    )
    ..addOption('out', help: 'Output folder. Default: build/content/<id>.')
    ..addOption(
      'cache',
      help: 'Download cache, relative to the repository root.',
      defaultsTo: 'third_party_cache',
    )
    ..addOption(
      'fixture-out',
      help: 'Also write the JSON copy here (for packages/testing/fixtures).',
    )
    ..addFlag('refresh', help: 'Download sources again.', negatable: false)
    ..addFlag('fonts', help: 'Download page fonts.', defaultsTo: true)
    ..addFlag('verbose', abbr: 'v', negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n${parser.usage}');
    exitCode = 64;
    return;
  }
  if (args.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }

  Logger.root.level = args.flag('verbose') ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen(
    (r) => (r.level >= Level.SEVERE ? stderr : stdout).writeln(
      '${r.level.name.toLowerCase()}: ${r.message}',
    ),
  );
  final logger = Logger('content_build');

  final root = _repositoryRoot();
  if (root == null) {
    logger.severe('Run from inside the Sudur repository.');
    exitCode = 1;
    return;
  }

  final BuildConfig config;
  try {
    config = BuildConfig.fromJson(
      File(p.join(root, args.option('config'))).readAsStringSync(),
    );
  } on ContentBuildException catch (e) {
    logger.severe(e.message);
    exitCode = 1;
    return;
  } on FileSystemException catch (e) {
    logger.severe('Cannot read config: ${e.message}');
    exitCode = 1;
    return;
  }

  final out = args.option('out') ?? p.join(root, 'build', 'content', config.id);
  final builder = ContentBuilder(
    config: config,
    fetcher: HttpSourceFetcher(
      cacheDirectory: p.join(root, args.option('cache')),
      refresh: args.flag('refresh'),
      logger: logger,
    ),
    logger: logger,
  );

  switch (await builder.build()) {
    case Ok(value: final data):
      writeContentDatabase(data, p.join(out, 'content.sqlite'));
      writeContentJson(data, p.join(out, 'content.json'));
      File(
        p.join(root, 'tools', 'content_build', 'ATTRIBUTION.md'),
      ).copySync(p.join(out, 'ATTRIBUTION.md'));
      final fixture = args.option('fixture-out');
      if (fixture != null) writeContentJson(data, p.join(root, fixture));
      logger.info(
        'wrote ${data.words.length} words, ${data.ayahs.length} ayahs, '
        '${data.lines.length} lines to $out',
      );
    case Error(:final error):
      logger.severe('build failed: $error');
      exitCode = 1;
      return;
  }

  if (args.flag('fonts')) {
    switch (await builder.fetchFonts(p.join(out, 'fonts'))) {
      case Ok(value: final sums):
        for (final e in sums.entries) {
          logger.info('font ${e.key} sha256 ${e.value}');
        }
      case Error(:final error):
        logger.severe('fonts failed: $error');
        exitCode = 1;
    }
  }
}

String? _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File(p.join(dir.path, 'AGENTS.md')).existsSync() &&
        Directory(p.join(dir.path, 'tools', 'content_build')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}
