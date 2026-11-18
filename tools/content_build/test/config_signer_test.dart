import 'dart:convert';
import 'dart:io';

import 'package:content_build/content_build.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// The signed test config in packages/testing is made by this tool with the
// test-only key; packages/content checks it.

const String fixtures = '../../packages/testing/fixtures';
final String repositoryRoot = p.normalize(p.absolute('../..'));

Map<String, Object?> values() =>
    jsonDecode(File('$fixtures/config/config.values.json').readAsStringSync())
        as Map<String, Object?>;

void main() {
  test('rebuilding the test config gives the committed file byte for byte',
      () async {
    final key = loadSigningKey(
      keyId: 'test-main',
      repositoryRoot: repositoryRoot,
      keyFile: '$fixtures/manifest/test-keys.TEST-ONLY.json',
      allowTestKey: true,
    );
    final signed = await signJson(
      buildConfig(
        values(),
        version: '1.0.0',
        issuedAt: DateTime.utc(2026, 11, 18),
      ),
      key,
    );
    expect(
      formatManifest(signed),
      File('$fixtures/config/config.test.json').readAsStringSync(),
    );
  });

  test('unknown sections and bad versions are refused', () {
    expect(
      () => buildConfig(
        {...values(), 'follow': <String, Object?>{}},
        version: '1.0.0',
        issuedAt: DateTime.utc(2026, 11, 18),
      ),
      throwsA(isA<ManifestBuildException>()),
    );
    expect(
      () => buildConfig(
        values(),
        version: '1.0',
        issuedAt: DateTime.utc(2026, 11, 18),
      ),
      throwsA(isA<ManifestBuildException>()),
    );
  });
}
