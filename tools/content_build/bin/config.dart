import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:content_build/content_build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Builds and signs the `config` file (docs/tz 8.8, 12.3) with the same key
/// as the manifest.
///
/// From the repository root:
/// `dart run tools/content_build/bin/config.dart --values config.values.json
/// --version 1.0.1 --key-id main-2026 --key-file KEY_OUTSIDE_THE_REPO
/// --out config.json`
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('values', help: 'Parameters by section (no signature).')
    ..addOption('version', help: 'Version of this config, x.y.z.')
    ..addOption('out', help: 'Where to write the signed config.json.')
    ..addOption('key-id', help: 'Signing key id, like main-2026.')
    ..addOption(
      'key-file',
      help: 'Private key file outside the repository. '
          'Or set SUDUR_MANIFEST_SIGNING_KEY to the base64 seed.',
    )
    ..addOption('issued-at', help: 'UTC time of issue (default: now).')
    ..addFlag('allow-test-key', negatable: false)
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
  Logger.root.onRecord.listen(
    (r) => stderr.writeln('${r.level.name.toLowerCase()}: ${r.message}'),
  );
  final log = Logger('config');
  String required(String name) =>
      args.option(name) ??
      (throw ManifestBuildException('--$name is required'));
  try {
    final key = loadSigningKey(
      keyId: required('key-id'),
      repositoryRoot: _repositoryRoot(),
      keyFile: args.option('key-file'),
      envSeed: Platform.environment['SUDUR_MANIFEST_SIGNING_KEY'],
      allowTestKey: args.flag('allow-test-key'),
    );
    final issuedAt = switch (args.option('issued-at')) {
      null => DateTime.now().toUtc(),
      final t => DateTime.tryParse(t) ??
          (throw ManifestBuildException('--issued-at "$t"')),
    };
    final values = switch (jsonDecode(
      File(required('values')).readAsStringSync(),
    )) {
      final Map<String, Object?> m => m,
      _ => throw const ManifestBuildException('values must be an object'),
    };
    final signed = await signJson(
      buildConfig(values, version: required('version'), issuedAt: issuedAt),
      key,
    );
    File(required('out')).writeAsStringSync(formatManifest(signed));
    log.info('signed with ${key.keyId}: ${required('out')}');
  } on ManifestBuildException catch (e) {
    log.severe(e.message);
    exitCode = 1;
  } on FileSystemException catch (e) {
    log.severe('${e.message}: ${e.path}');
    exitCode = 1;
  } on FormatException catch (e) {
    log.severe(e.message);
    exitCode = 1;
  }
}

String _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File(p.join(dir.path, 'AGENTS.md')).existsSync() &&
        Directory(p.join(dir.path, 'tools', 'content_build')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    // Outside any checkout: the current folder bounds the check.
    if (parent.path == dir.path) return Directory.current.absolute.path;
    dir = parent;
  }
}
