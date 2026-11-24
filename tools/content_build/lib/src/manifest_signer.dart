import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

// Builds and signs the content manifest (docs/tz 12.3, 4.9, 8.10). The app
// side (`packages/content`) checks it; the two agree through the canonical
// form below and the signed test fixture in packages/testing.

/// A manifest or signing input that cannot be used.
final class ManifestBuildException implements Exception {
  /// Creates the error.
  const ManifestBuildException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'Manifest: $message';
}

/// Key ids of test key pairs (their private keys are in the repository).
const String testKeyIdPrefix = 'test-';

const List<String> _kinds = [
  'text',
  'layout',
  'font',
  'audio',
  'model',
  'lessons',
  'translation',
  'config',
];
final RegExp _version = RegExp(r'^(0|[1-9]\d{0,8})(\.(0|[1-9]\d{0,8})){2}$');
final RegExp _id = RegExp(r'^[a-z0-9][a-z0-9._-]*$');
const int _seedLength = 32;

/// The canonical form of a JSON value that the signature covers: object
/// keys sorted, no whitespace, integers only. The same rule as
/// `canonicalJson` of `packages/content`.
String canonicalJson(Object? value) {
  final out = StringBuffer();
  void write(Object? v) {
    switch (v) {
      case null || bool() || String() || int():
        out.write(jsonEncode(v));
      case final Map<String, Object?> map:
        final keys = map.keys.toList()..sort();
        out.write('{');
        for (final (i, k) in keys.indexed) {
          if (i > 0) out.write(',');
          out
            ..write(jsonEncode(k))
            ..write(':');
          write(map[k]);
        }
        out.write('}');
      case final List<Object?> list:
        out.write('[');
        for (final (i, e) in list.indexed) {
          if (i > 0) out.write(',');
          write(e);
        }
        out.write(']');
      default:
        throw ManifestBuildException('not a canonical JSON value: $v');
    }
  }

  write(value);
  return out.toString();
}

/// Builds an unsigned manifest from [spec] (see README: `packages.json`),
/// reading each package archive from [filesDirectory] for its size and
/// SHA-256.
Map<String, Object?> buildManifest(
  Map<String, Object?> spec, {
  required String filesDirectory,
  required DateTime issuedAt,
}) {
  if (!issuedAt.isUtc) throw const ManifestBuildException('issuedAt not UTC');
  final list = spec['packages'];
  if (list is! List<Object?> || list.isEmpty) {
    throw const ManifestBuildException('spec.packages must be a list');
  }
  final ids = <String>{};
  final packages = <Map<String, Object?>>[];
  for (final (i, entry) in list.indexed) {
    if (entry is! Map<String, Object?>) {
      throw ManifestBuildException('packages[$i] must be an object');
    }
    String text(String key) => switch (entry[key]) {
          final String v when v.trim().isNotEmpty => v,
          _ => throw ManifestBuildException('packages[$i].$key is missing'),
        };
    final id = text('id');
    if (!_id.hasMatch(id) || !ids.add(id)) {
      throw ManifestBuildException('packages[$i].id "$id"');
    }
    final kind = text('kind');
    if (!_kinds.contains(kind)) {
      throw ManifestBuildException('packages[$i].kind "$kind"');
    }
    for (final key in ['version', 'minAppVersion']) {
      if (!_version.hasMatch(text(key))) {
        throw ManifestBuildException('packages[$i].$key must be x.y.z');
      }
    }
    final url = Uri.tryParse(text('url'));
    if (url == null || url.scheme != 'https' || url.host.isEmpty) {
      throw ManifestBuildException('packages[$i].url must be HTTPS');
    }
    final depends = switch (entry['dependsOn'] ?? const <Object?>[]) {
      final List<Object?> d when d.every((x) => x is String) =>
        d.cast<String>(),
      _ => throw ManifestBuildException('packages[$i].dependsOn'),
    };
    final file = File(p.join(filesDirectory, text('file')));
    if (!file.existsSync()) {
      throw ManifestBuildException('no file ${file.path}');
    }
    final bytes = file.readAsBytesSync();
    packages.add({
      'id': id,
      'kind': kind,
      'version': text('version'),
      'url': '$url',
      'size': bytes.length,
      'sha256': crypto.sha256.convert(bytes).toString(),
      'license': text('license'),
      'minAppVersion': text('minAppVersion'),
      'dependsOn': depends,
    });
  }
  for (final pkg in packages) {
    for (final d in pkg['dependsOn']! as List<String>) {
      // Every entry above has dependsOn.
      if (d == pkg['id'] || !ids.contains(d)) {
        throw ManifestBuildException('${pkg['id']} depends on unknown $d');
      }
    }
  }
  return {
    'manifestVersion': 1,
    'issuedAt': issuedAt.toIso8601String(),
    'packages': packages,
  };
}

/// A private signing key: a 32-byte Ed25519 seed and its key id.
final class SigningKey {
  /// Creates the key.
  SigningKey({required this.keyId, required List<int> seed}) : _seed = seed {
    if (seed.length != _seedLength) {
      throw const ManifestBuildException('the seed must be 32 bytes');
    }
  }

  /// Key id written into the signature.
  final String keyId;
  final List<int> _seed;

  /// Whether this is a test key (its private key is in the repository).
  bool get isTest => keyId.startsWith(testKeyIdPrefix);
}

/// Signs [manifest]: the canonical JSON without `signature` (docs/tz 12.3).
Future<Map<String, Object?>> signManifest(
  Map<String, Object?> manifest,
  SigningKey key,
) async {
  final unsigned = {...manifest}..remove('signature');
  final pair = await Ed25519().newKeyPairFromSeed(key._seed);
  final signature = await Ed25519().sign(
    utf8.encode(canonicalJson(unsigned)),
    keyPair: pair,
  );
  return {
    ...unsigned,
    'signature': {
      'keyId': key.keyId,
      'ed25519': base64.encode(signature.bytes),
    },
  };
}

/// The public key of [key], base64 — to build into the app.
Future<String> publicKeyOf(SigningKey key) async {
  final pair = await Ed25519().newKeyPairFromSeed(key._seed);
  return base64.encode((await pair.extractPublicKey()).bytes);
}

/// Reads the signing key. It comes from outside the repository (docs/tz
/// 8.10): environment variable [envSeed] (base64 seed, with [keyId]) or a
/// key file `{"keyId": …, "seed": …}` or `{"keys": [ … ]}` picked by
/// [keyId].
///
/// A real key (id not starting with `test-`) in a file inside
/// [repositoryRoot] is refused: it must never be committed. A test key is
/// refused unless [allowTestKey].
SigningKey loadSigningKey({
  required String keyId,
  required String repositoryRoot,
  String? keyFile,
  String? envSeed,
  bool allowTestKey = false,
}) {
  if (keyId.startsWith(testKeyIdPrefix) && !allowTestKey) {
    throw ManifestBuildException(
      '$keyId is a test key; pass --allow-test-key only for tests',
    );
  }
  List<int> seedOf(String text) {
    try {
      return base64.decode(text.trim());
    } on FormatException {
      throw const ManifestBuildException('the seed is not base64');
    }
  }

  if (envSeed != null && keyFile != null) {
    throw const ManifestBuildException('give the key either by file or env');
  }
  if (envSeed != null) return SigningKey(keyId: keyId, seed: seedOf(envSeed));
  if (keyFile == null) {
    throw const ManifestBuildException('no signing key given');
  }
  final path = p.normalize(p.absolute(keyFile));
  if (!keyId.startsWith(testKeyIdPrefix) &&
      p.isWithin(p.normalize(p.absolute(repositoryRoot)), path)) {
    throw ManifestBuildException(
      'the private key $path is inside the repository: keep it outside',
    );
  }
  final Object? json;
  try {
    json = jsonDecode(File(path).readAsStringSync());
  } on FormatException {
    throw ManifestBuildException('$path is not JSON');
  } on FileSystemException catch (e) {
    throw ManifestBuildException('cannot read $path: ${e.message}');
  }
  final entries = switch (json) {
    {'keys': final List<Object?> keys} => keys,
    final Map<String, Object?> single => [single],
    _ => const <Object?>[],
  };
  for (final e in entries) {
    if (e case {'keyId': final String id, 'seed': final String seed}
        when id == keyId) {
      return SigningKey(keyId: id, seed: seedOf(seed));
    }
  }
  throw ManifestBuildException('no key $keyId in $path');
}

/// Creates a new signing key [keyId] with a random seed from [random]
/// (`Random.secure()`), writes it to [keyFile] and returns its public key
/// (base64) to build into the app. The file must be outside
/// [repositoryRoot] and must not exist yet.
Future<String> createSigningKey({
  required String keyId,
  required String keyFile,
  required String repositoryRoot,
  required Random random,
}) async {
  if (keyId.startsWith(testKeyIdPrefix) || !_id.hasMatch(keyId)) {
    throw ManifestBuildException('key id "$keyId"');
  }
  final path = p.normalize(p.absolute(keyFile));
  if (p.isWithin(p.normalize(p.absolute(repositoryRoot)), path)) {
    throw ManifestBuildException('$path is inside the repository');
  }
  final file = File(path);
  if (file.existsSync()) throw ManifestBuildException('$path exists');
  final seed = List<int>.generate(_seedLength, (_) => random.nextInt(256));
  final key = SigningKey(keyId: keyId, seed: seed);
  file.writeAsStringSync(
    '${jsonEncode({'keyId': keyId, 'seed': base64.encode(seed)})}\n',
  );
  return await publicKeyOf(key);
}

/// Writes a signed manifest as indented JSON (the signature covers the
/// canonical form, so the layout of the file does not matter).
String formatManifest(Map<String, Object?> signed) =>
    '${const JsonEncoder.withIndent('  ').convert(signed)}\n';
