import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:content_build/content_build.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// The signed test manifest in packages/testing is made by this tool with
// the test-only key; packages/content checks it. Both sides agree through
// that file.

const String fixtures = '../../packages/testing/fixtures/manifest';
const String keyFile = '$fixtures/test-keys.TEST-ONLY.json';
final String repositoryRoot = p.normalize(p.absolute('../..'));

Map<String, Object?> spec() =>
    jsonDecode(File('$fixtures/packages.test.json').readAsStringSync())
        as Map<String, Object?>;

SigningKey testKey() => loadSigningKey(
      keyId: 'test-main',
      repositoryRoot: repositoryRoot,
      keyFile: keyFile,
      allowTestKey: true,
    );

void main() {
  test('rebuilding the test manifest gives the committed file byte for byte',
      () async {
    final manifest = buildManifest(
      spec(),
      filesDirectory: fixtures,
      issuedAt: DateTime.utc(2026, 11, 18),
    );
    final signed = await signManifest(manifest, testKey());
    expect(
      formatManifest(signed),
      File('$fixtures/manifest.test.json').readAsStringSync(),
    );
  });

  test('the signature verifies with the public key of the key file', () async {
    final key = testKey();
    final signed = await signManifest(
      buildManifest(
        spec(),
        filesDirectory: fixtures,
        issuedAt: DateTime.utc(2026, 11, 18),
      ),
      key,
    );
    final sig = signed['signature']! as Map<String, Object?>; // Just signed.
    final ok = await Ed25519().verify(
      utf8.encode(canonicalJson({...signed}..remove('signature'))),
      signature: Signature(
        base64.decode(sig['ed25519']! as String), // Just signed.
        publicKey: SimplePublicKey(
          base64.decode(await publicKeyOf(key)),
          type: KeyPairType.ed25519,
        ),
      ),
    );
    expect(ok, isTrue);
  });

  test('size and SHA-256 come from the archive', () {
    final m = buildManifest(
      spec(),
      filesDirectory: fixtures,
      issuedAt: DateTime.utc(2026, 11, 18),
    );
    final pkg =
        (m['packages']! as List<Object?>).single! as Map<String, Object?>;
    expect(pkg['size'], File('$fixtures/hello-1.0.0.zip').lengthSync());
    expect(pkg['sha256'], hasLength(64));
  });

  group('the private key stays outside the repository (8.10)', () {
    late Directory outside;
    setUp(() => outside = Directory.systemTemp.createTempSync('key'));
    tearDown(() => outside.deleteSync(recursive: true));

    String keyFileWith(String dirPath, String keyId) {
      final f = File(p.join(dirPath, 'key.json'))
        ..writeAsStringSync(
          jsonEncode(
            {'keyId': keyId, 'seed': base64.encode(List.filled(32, 7))},
          ),
        );
      return f.path;
    }

    test('a real key file inside the repository is refused', () {
      final inside = Directory(p.join(repositoryRoot, 'build', 'key-test'))
        ..createSync(recursive: true);
      try {
        expect(
          () => loadSigningKey(
            keyId: 'main-2026',
            repositoryRoot: repositoryRoot,
            keyFile: keyFileWith(inside.path, 'main-2026'),
          ),
          throwsA(isA<ManifestBuildException>()),
        );
      } finally {
        inside.deleteSync(recursive: true);
      }
    });

    test('a real key file outside is used', () {
      final key = loadSigningKey(
        keyId: 'main-2026',
        repositoryRoot: repositoryRoot,
        keyFile: keyFileWith(outside.path, 'main-2026'),
      );
      expect(key.keyId, 'main-2026');
      expect(key.isTest, isFalse);
    });

    test('the key from the environment', () {
      final key = loadSigningKey(
        keyId: 'main-2026',
        repositoryRoot: repositoryRoot,
        envSeed: base64.encode(List.filled(32, 9)),
      );
      expect(key.keyId, 'main-2026');
    });

    test('a new key is created outside and only there', () async {
      final path = p.join(outside.path, 'main.json');
      final public = await createSigningKey(
        keyId: 'main-2027',
        keyFile: path,
        repositoryRoot: repositoryRoot,
        random: Random(1),
      );
      final key = loadSigningKey(
        keyId: 'main-2027',
        repositoryRoot: repositoryRoot,
        keyFile: path,
      );
      expect(await publicKeyOf(key), public);
      expect(base64.decode(public), hasLength(32));
      await expectLater(
        createSigningKey(
          keyId: 'main-2027',
          keyFile: path,
          repositoryRoot: repositoryRoot,
          random: Random(1),
        ),
        throwsA(isA<ManifestBuildException>()),
        reason: 'never overwrite a key',
      );
      await expectLater(
        createSigningKey(
          keyId: 'main-2027',
          keyFile: p.join(repositoryRoot, 'build', 'k.json'),
          repositoryRoot: repositoryRoot,
          random: Random(1),
        ),
        throwsA(isA<ManifestBuildException>()),
      );
    });

    test('a test key needs --allow-test-key', () {
      expect(
        () => loadSigningKey(
          keyId: 'test-main',
          repositoryRoot: repositoryRoot,
          keyFile: keyFile,
        ),
        throwsA(isA<ManifestBuildException>()),
      );
    });

    test('a seed that is not 32 bytes, or no key: refused', () {
      expect(
        () => loadSigningKey(
          keyId: 'main-2026',
          repositoryRoot: repositoryRoot,
          envSeed: base64.encode([1, 2, 3]),
        ),
        throwsA(isA<ManifestBuildException>()),
      );
      expect(
        () =>
            loadSigningKey(keyId: 'main-2026', repositoryRoot: repositoryRoot),
        throwsA(isA<ManifestBuildException>()),
      );
    });
  });

  group('a bad spec is refused', () {
    Map<String, Object?> changed(String key, Object? value) {
      final s = spec();
      ((s['packages']! as List<Object?>).single! as Map<String, Object?>)[key] =
          value;
      return s;
    }

    for (final (key, value) in [
      ('url', 'http://cdn.example/x.zip'),
      ('version', '1.0'),
      ('kind', 'virus'),
      ('dependsOn', ['nothing']),
      ('file', 'missing.zip'),
      ('id', 'Bad Id'),
    ]) {
      test('$key = $value', () {
        expect(
          () => buildManifest(
            changed(key, value),
            filesDirectory: fixtures,
            issuedAt: DateTime.utc(2026, 11, 18),
          ),
          throwsA(isA<ManifestBuildException>()),
        );
      });
    }
  });

  test('canonical JSON: sorted keys, no spaces, finite numbers', () {
    expect(
      canonicalJson({
        'b': 1,
        'a': [true, null],
      }),
      '{"a":[true,null],"b":1}',
    );
    expect(
      () => canonicalJson({'a': double.nan}),
      throwsA(isA<ManifestBuildException>()),
    );
  });
}
