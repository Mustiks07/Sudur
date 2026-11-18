import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:content_build/content_build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Environment variable with the base64 Ed25519 seed of the signing key.
const String signingKeyEnv = 'SUDUR_MANIFEST_SIGNING_KEY';

/// Builds and signs the content manifest (docs/tz 12.3, 8.10).
///
/// From the repository root:
/// `dart run tools/content_build/bin/manifest.dart --spec packages.json
/// --files FOLDER --key-id main-2026 --key-file KEY_OUTSIDE_THE_REPO
/// --out manifest.json`
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('spec', help: 'packages.json: what goes into the manifest.')
    ..addOption('files', help: 'Folder with the package archives.')
    ..addOption('out', help: 'Where to write the signed manifest.')
    ..addOption('key-id', help: 'Signing key id, like main-2026.')
    ..addOption(
      'key-file',
      help: 'Private key file outside the repository. '
          'Or set $signingKeyEnv to the base64 seed.',
    )
    ..addOption(
      'issued-at',
      help: 'UTC time of issue (default: now), like 2026-12-01T00:00:00Z.',
    )
    ..addFlag(
      'allow-test-key',
      help: 'Allow a test- key (only for test fixtures).',
      negatable: false,
    )
    ..addOption(
      'new-key',
      help: 'Create a new key --key-id in this file (outside the repository) '
          'and print its public key.',
    )
    ..addFlag(
      'print-public-key',
      help: 'Only print the public key of the signing key.',
      negatable: false,
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
  if (args.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }
  Logger.root.onRecord.listen(
    (r) => stderr.writeln('${r.level.name.toLowerCase()}: ${r.message}'),
  );
  final log = Logger('manifest');

  String required(String name) =>
      args.option(name) ??
      (throw ManifestBuildException('--$name is required'));

  try {
    if (args.option('new-key') case final path?) {
      stdout.writeln(
        await createSigningKey(
          keyId: required('key-id'),
          keyFile: path,
          repositoryRoot: _repositoryRoot(),
          random: Random.secure(),
        ),
      );
      return;
    }
    final key = loadSigningKey(
      keyId: required('key-id'),
      repositoryRoot: _repositoryRoot(),
      keyFile: args.option('key-file'),
      envSeed: Platform.environment[signingKeyEnv],
      allowTestKey: args.flag('allow-test-key'),
    );
    if (args.flag('print-public-key')) {
      stdout.writeln(await publicKeyOf(key));
      return;
    }
    final issuedAt = switch (args.option('issued-at')) {
      null => DateTime.now().toUtc(),
      final t => DateTime.tryParse(t) ??
          (throw ManifestBuildException('--issued-at "$t"')),
    };
    final specPath = required('spec');
    final spec = switch (jsonDecode(File(specPath).readAsStringSync())) {
      final Map<String, Object?> m => m,
      _ => throw ManifestBuildException('$specPath is not an object'),
    };
    final manifest = buildManifest(
      spec,
      filesDirectory: required('files'),
      issuedAt: issuedAt,
    );
    final signed = await signManifest(manifest, key);
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
