import 'dart:convert';

import 'package:content/src/canonical_json.dart';
import 'package:content/src/manifest.dart';
import 'package:content/src/package_version.dart';
import 'package:contracts/contracts.dart';
import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

/// An Ed25519 public key the app trusts for manifests (docs/tz 8.10).
@immutable
final class TrustedKey {
  /// Creates a key; [publicKey] is the raw 32-byte key.
  const TrustedKey({required this.id, required this.publicKey});

  /// Key id as written in `signature.keyId`.
  final String id;

  /// Raw public key.
  final List<int> publicKey;
}

/// Key ids starting with this belong to test key pairs: their private keys
/// are in the repository, so the app never trusts them.
const String testKeyIdPrefix = 'test-';

/// The public keys built into the app: the main one and the backup one,
/// used if the main private key is lost or leaked (ДФ-06, docs/tz 8.10).
@immutable
final class TrustedKeys {
  /// Creates the key set. Test keys (ids starting with [testKeyIdPrefix])
  /// are refused unless [allowTestKeys] is set, which only tests do.
  TrustedKeys({
    required TrustedKey main,
    required TrustedKey backup,
    bool allowTestKeys = false,
  }) : _keys = {main.id: main, backup.id: backup} {
    if (main.id == backup.id) {
      throw ArgumentError('the main and backup keys must differ');
    }
    for (final k in _keys.values) {
      if (k.publicKey.length != _publicKeyLength) {
        throw ArgumentError('key ${k.id} is not a 32-byte Ed25519 key');
      }
      if (!allowTestKeys && k.id.startsWith(testKeyIdPrefix)) {
        throw ArgumentError('key ${k.id} is a test key');
      }
    }
  }

  final Map<String, TrustedKey> _keys;

  /// The key with [id], or `null`.
  TrustedKey? operator [](String id) => _keys[id];
}

const int _publicKeyLength = 32;
const int _signatureLength = 64;

/// Why a manifest was refused.
enum ManifestProblem {
  /// Not JSON or not the shape of docs/tz 12.3.
  malformed,

  /// A newer manifest format than this app reads.
  unsupportedVersion,

  /// Signed by a key the app does not trust.
  unknownKey,

  /// The signature does not match the content.
  badSignature,

  /// Older than a manifest the app already accepted (replay).
  outdated,
}

/// A manifest that is not accepted.
final class ManifestException implements Exception {
  /// Creates the error.
  const ManifestException(this.problem, this.message);

  /// The kind of problem.
  final ManifestProblem problem;

  /// Details for logs; never contains package content.
  final String message;

  @override
  String toString() => 'Manifest ${problem.name}: $message';
}

/// Checks and reads a manifest (docs/tz 12.3, 11.4, ДФ-06).
///
/// The signature covers the canonical JSON of the manifest without
/// `signature` and is checked before anything in it is used. [notBefore] is
/// the `issuedAt` of the last accepted manifest: an older one is refused so
/// that an old signed manifest cannot be replayed.
///
/// Unknown fields are allowed and covered by the signature, so a newer
/// manifest can add optional fields without breaking older apps; required
/// fields are checked strictly.
Future<Result<Manifest>> verifyManifest(
  String source,
  TrustedKeys keys, {
  DateTime? notBefore,
}) async {
  Result<Manifest> fail(ManifestProblem p, String message) =>
      Result.error(ManifestException(p, message));

  final Map<String, Object?> json;
  final ManifestSignature signature;
  switch (await verifySignedJson(source, keys)) {
    case Ok(value: (final document, final sig)):
      json = document;
      signature = sig;
    case Error(:final error):
      return Result.error(error);
  }

  // Signed by a trusted key: now the content is read.
  switch (json['manifestVersion']) {
    case final int v when v == Manifest.supportedVersion:
      break;
    case final int v when v > Manifest.supportedVersion:
      return fail(ManifestProblem.unsupportedVersion, 'version $v');
    default:
      return fail(ManifestProblem.malformed, 'manifestVersion');
  }
  final Manifest manifest;
  try {
    manifest = Manifest(
      manifestVersion: Manifest.supportedVersion,
      issuedAt: parseUtcTime(json['issuedAt'], 'issuedAt'),
      packages: _packages(json['packages']),
      signature: signature,
    );
  } on FormatException catch (e) {
    return fail(ManifestProblem.malformed, e.message);
  }
  if (notBefore != null && manifest.issuedAt.isBefore(notBefore)) {
    return fail(
      ManifestProblem.outdated,
      'issued ${manifest.issuedAt.toIso8601String()}, '
      'already have ${notBefore.toIso8601String()}',
    );
  }
  return Result.ok(manifest);
}

/// Checks the Ed25519 signature of a signed JSON document — the manifest
/// or the `config` file (docs/tz 12.3: «подписан так же, как манифест») —
/// and returns the document with its signature. The signature covers the
/// canonical JSON without `signature`; nothing in the document is trusted
/// before this check.
Future<Result<(Map<String, Object?>, ManifestSignature)>> verifySignedJson(
  String source,
  TrustedKeys keys,
) async {
  Result<(Map<String, Object?>, ManifestSignature)> fail(
    ManifestProblem p,
    String message,
  ) =>
      Result.error(ManifestException(p, message));

  final Object? json;
  try {
    json = jsonDecode(source);
  } on FormatException catch (e) {
    return fail(ManifestProblem.malformed, 'not JSON: ${e.message}');
  }
  if (json is! Map<String, Object?>) {
    return fail(ManifestProblem.malformed, 'not an object');
  }
  final ManifestSignature signature;
  final String signed;
  try {
    signature = _signature(json['signature']);
    signed = canonicalJson({...json}..remove('signature'));
  } on FormatException catch (e) {
    return fail(ManifestProblem.malformed, e.message);
  }
  final key = keys[signature.keyId];
  if (key == null) {
    return fail(ManifestProblem.unknownKey, 'key "${signature.keyId}"');
  }
  final valid = await Ed25519().verify(
    utf8.encode(signed),
    signature: Signature(
      signature.ed25519,
      publicKey: SimplePublicKey(key.publicKey, type: KeyPairType.ed25519),
    ),
  );
  if (!valid) {
    return fail(ManifestProblem.badSignature, 'key "${key.id}"');
  }
  return Result.ok((json, signature));
}

ManifestSignature _signature(Object? json) {
  if (json case {'keyId': final String keyId, 'ed25519': final String sig}) {
    final List<int> bytes;
    try {
      bytes = base64.decode(sig);
    } on FormatException {
      throw const FormatException('signature.ed25519 is not base64');
    }
    if (bytes.length != _signatureLength) {
      throw const FormatException('signature.ed25519 is not 64 bytes');
    }
    return ManifestSignature(keyId: keyId, ed25519: bytes);
  }
  throw const FormatException('signature must have keyId and ed25519');
}

/// Reads a UTC time like `2026-12-01T00:00:00Z` from [json].
///
/// Throws [FormatException] naming [field].
DateTime parseUtcTime(Object? json, String field) {
  if (json is String) {
    final t = DateTime.tryParse(json);
    if (t != null && t.isUtc) return t;
  }
  throw FormatException(
    '$field must be a UTC time like 2026-12-01T00:00:00Z',
  );
}

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9._-]*$');
final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

List<ManifestPackage> _packages(Object? json) {
  if (json is! List<Object?>) {
    throw const FormatException('packages must be a list');
  }
  final packages = [
    for (final (i, p) in json.indexed) _package(p, 'packages[$i]'),
  ];
  final ids = <String>{};
  for (final p in packages) {
    if (!ids.add(p.id)) throw FormatException('duplicate package ${p.id}');
  }
  for (final p in packages) {
    for (final d in p.dependsOn) {
      if (d == p.id || !ids.contains(d)) {
        throw FormatException('${p.id} depends on unknown package $d');
      }
    }
  }
  return List.unmodifiable(packages);
}

ManifestPackage _package(Object? json, String at) {
  if (json is! Map<String, Object?>) {
    throw FormatException('$at must be an object');
  }
  T field<T>(String key) => switch (json[key]) {
        final T v => v,
        _ => throw FormatException('$at.$key is missing or has a wrong type'),
      };
  PackageVersion version(String key) =>
      PackageVersion.tryParse(field<String>(key)) ??
      (throw FormatException('$at.$key must be major.minor.patch'));

  final id = field<String>('id');
  if (!_idPattern.hasMatch(id)) throw FormatException('$at.id "$id"');
  final kindName = field<String>('kind');
  final kind = PackageKind.values.where((k) => k.name == kindName).firstOrNull;
  if (kind == null) throw FormatException('$at.kind "$kindName"');
  final url = Uri.tryParse(field<String>('url'));
  if (url == null || url.scheme != 'https' || url.host.isEmpty) {
    throw FormatException('$at.url must be an HTTPS address');
  }
  final size = field<int>('size');
  if (size <= 0) throw FormatException('$at.size must be positive');
  final sha256 = field<String>('sha256');
  if (!_sha256Pattern.hasMatch(sha256)) {
    throw FormatException('$at.sha256 must be 64 lower-case hex digits');
  }
  final license = field<String>('license');
  if (license.trim().isEmpty) throw FormatException('$at.license is empty');
  final depends = field<List<Object?>>('dependsOn');
  return ManifestPackage(
    id: id,
    kind: kind,
    version: version('version'),
    url: url,
    size: size,
    sha256: sha256,
    license: license,
    minAppVersion: version('minAppVersion'),
    dependsOn: List.unmodifiable([
      for (final d in depends)
        switch (d) {
          final String id => id,
          _ => throw FormatException('$at.dependsOn'),
        },
    ]),
  );
}
