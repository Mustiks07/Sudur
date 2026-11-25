import 'dart:convert';
import 'dart:io';

import 'package:content/content.dart';
import 'package:contracts/contracts.dart';
import 'package:test/test.dart';

import 'helpers.dart';

// Test keys, fixtures and manifests built here have a known shape: `!` on
// their fields cannot fail.

ManifestException refused(Result<Manifest> r) =>
    (r as Error<Manifest>).error as ManifestException;

void main() {
  late Map<String, TestKey> keys;
  late TrustedKeys trust;
  late String fixture;

  setUpAll(() {
    keys = loadTestKeys();
    trust = trusted(keys);
    fixture = File('$fixtures/manifest.test.json').readAsStringSync();
  });

  Map<String, Object?> fixtureJson() =>
      jsonDecode(fixture) as Map<String, Object?>;

  Future<String> signedBy(String keyName, Map<String, Object?> m) =>
      sign(m, keys[keyName]!.seed, keyId: keyName);

  test('the manifest signed by tools/content_build is accepted', () async {
    final m = ok(await verifyManifest(fixture, trust));
    expect(m.issuedAt, DateTime.utc(2026, 11, 18));
    expect(m.signature.keyId, 'test-main');
    final p = m.package('test-hello')!;
    expect(p.kind, PackageKind.config);
    expect(p.version, const PackageVersion(1, 0, 0));
    expect(p.size, File('$fixtures/hello-1.0.0.zip').lengthSync());
    expect(p.url.scheme, 'https');
  });

  test('the backup key is accepted too (ДФ-06, 8.10)', () async {
    final text = await signedBy('test-backup', fixtureJson());
    expect(
      ok(await verifyManifest(text, trust)).signature.keyId,
      'test-backup',
    );
  });

  test('a changed manifest is refused: bad signature', () async {
    final json = fixtureJson();
    ((json['packages']! as List<Object?>).first!
        as Map<String, Object?>)['url'] = 'https://evil.example/model.zip';
    final r = await verifyManifest(jsonEncode(json), trust);
    expect(refused(r).problem, ManifestProblem.badSignature);
  });

  test('a foreign key under a trusted id is refused', () async {
    final text = await sign(
      fixtureJson(),
      keys['test-stranger']!.seed,
      keyId: 'test-main',
    );
    expect(
      refused(await verifyManifest(text, trust)).problem,
      ManifestProblem.badSignature,
    );
  });

  test('an unknown key id is refused', () async {
    final text = await signedBy('test-stranger', fixtureJson());
    expect(
      refused(await verifyManifest(text, trust)).problem,
      ManifestProblem.unknownKey,
    );
  });

  test('garbage, no signature, bad signature bytes: malformed', () async {
    for (final text in [
      '{not json',
      '[]',
      jsonEncode({...fixtureJson()}..remove('signature')),
      jsonEncode({
        ...fixtureJson(),
        'signature': {'keyId': 'test-main', 'ed25519': 'AAAA'},
      }),
    ]) {
      expect(
        refused(await verifyManifest(text, trust)).problem,
        ManifestProblem.malformed,
        reason: text.length > 40 ? text.substring(0, 40) : text,
      );
    }
  });

  test('a signed manifest with wrong content is still refused', () async {
    Future<ManifestProblem> problem(
      void Function(Map<String, Object?>) edit,
    ) async {
      final json = fixtureJson();
      edit(json);
      return refused(
        await verifyManifest(await signedBy('test-main', json), trust),
      ).problem;
    }

    Map<String, Object?> pkg(Map<String, Object?> j) =>
        (j['packages']! as List<Object?>).first! as Map<String, Object?>;

    expect(
      await problem((j) => j['manifestVersion'] = 2),
      ManifestProblem.unsupportedVersion,
    );
    expect(
      await problem((j) => pkg(j)['url'] = 'http://cdn.example/x.zip'),
      ManifestProblem.malformed,
    );
    expect(
      await problem((j) => pkg(j)['sha256'] = 'ABC'),
      ManifestProblem.malformed,
    );
    expect(
      await problem((j) => pkg(j)['version'] = '1.0'),
      ManifestProblem.malformed,
    );
    expect(
      await problem((j) => pkg(j)['kind'] = 'virus'),
      ManifestProblem.malformed,
    );
    expect(
      await problem((j) => pkg(j)['dependsOn'] = ['nothing']),
      ManifestProblem.malformed,
    );
    expect(
      await problem((j) => j['issuedAt'] = '2026-11-18'),
      ManifestProblem.malformed,
    );
    expect(
      await problem(
        (j) => j['packages'] = [pkg(j), pkg(j)],
      ),
      ManifestProblem.malformed,
    );
  });

  test('unknown fields are allowed and covered by the signature', () async {
    final json = fixtureJson()..['note'] = 'added later';
    final text = await signedBy('test-main', json);
    expect(await verifyManifest(text, trust), isA<Ok<Manifest>>());
    final tampered = (jsonDecode(text) as Map<String, Object?>)
      ..['note'] = 'changed';
    expect(
      refused(await verifyManifest(jsonEncode(tampered), trust)).problem,
      ManifestProblem.badSignature,
    );
  });

  test('an older manifest than the last accepted one is refused', () async {
    final r = await verifyManifest(
      fixture,
      trust,
      notBefore: DateTime.utc(2026, 12),
    );
    expect(refused(r).problem, ManifestProblem.outdated);
    expect(
      await verifyManifest(fixture, trust, notBefore: DateTime.utc(2026, 11)),
      isA<Ok<Manifest>>(),
    );
  });

  test('the app never trusts test keys by default', () {
    expect(
      () => TrustedKeys(
        main: TrustedKey(
          id: 'test-main',
          publicKey: keys['test-main']!.publicKey,
        ),
        backup: TrustedKey(
          id: 'main-2026',
          publicKey: keys['test-backup']!.publicKey,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => TrustedKeys(
        main: const TrustedKey(id: 'a', publicKey: [1, 2, 3]),
        backup: TrustedKey(id: 'b', publicKey: keys['test-backup']!.publicKey),
      ),
      throwsArgumentError,
    );
  });

  group('canonical JSON', () {
    test('keys sorted at every level, no whitespace', () {
      expect(
        canonicalJson({
          'b': [
            {'z': 1, 'a': true},
          ],
          'a': null,
          'c': 'é"',
        }),
        r'{"a":null,"b":[{"a":true,"z":1}],"c":"é\""}',
      );
    });

    test('fractional numbers as Dart writes them; NaN and infinity refused',
        () {
      expect(
        canonicalJson({'a': 1.5, 'b': 3.0, 'c': 0.01}),
        '{"a":1.5,"b":3.0,"c":0.01}',
      );
      expect(() => canonicalJson({'x': double.nan}), throwsFormatException);
      expect(
        () => canonicalJson({'x': double.infinity}),
        throwsFormatException,
      );
    });
  });

  test('versions compare by number', () {
    PackageVersion v(String s) => PackageVersion.tryParse(s)!;
    expect(v('1.10.0') > v('1.9.9'), isTrue);
    expect(v('2.0.0') < v('10.0.0'), isTrue);
    for (final bad in ['1.0', '1.0.0.0', '01.0.0', 'a.b.c', '1.0.0-beta']) {
      expect(PackageVersion.tryParse(bad), isNull, reason: bad);
    }
  });
}
