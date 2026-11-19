import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:content/content.dart';
import 'package:contracts/contracts.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

// Test keys, fixtures and manifests built here have a known shape: `!` on
// their fields cannot fail.

const String fixtures = '../testing/fixtures/manifest';

/// A test-only key pair from `test-keys.TEST-ONLY.json`.
typedef TestKey = ({String id, List<int> seed, List<int> publicKey});

Map<String, TestKey> loadTestKeys() {
  final json = jsonDecode(
    File('$fixtures/test-keys.TEST-ONLY.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return {
    for (final k
        in (json['keys']! as List<Object?>).cast<Map<String, Object?>>())
      k['keyId']! as String: (
        id: k['keyId']! as String,
        seed: base64.decode(k['seed']! as String),
        publicKey: base64.decode(k['publicKey']! as String),
      ),
  };
}

TrustedKeys trusted(Map<String, TestKey> keys) => TrustedKeys(
      main:
          TrustedKey(id: 'test-main', publicKey: keys['test-main']!.publicKey),
      backup: TrustedKey(
        id: 'test-backup',
        publicKey: keys['test-backup']!.publicKey,
      ),
      allowTestKeys: true,
    );

/// Signs [manifest] with [seed] under [keyId] (any key id, to forge).
Future<String> sign(
  Map<String, Object?> manifest,
  List<int> seed, {
  required String keyId,
}) async {
  final unsigned = {...manifest}..remove('signature');
  final pair = await Ed25519().newKeyPairFromSeed(seed);
  final sig = await Ed25519().sign(
    utf8.encode(canonicalJson(unsigned)),
    keyPair: pair,
  );
  return jsonEncode({
    ...unsigned,
    'signature': {'keyId': keyId, 'ed25519': base64.encode(sig.bytes)},
  });
}

/// A manifest entry for [archive].
Map<String, Object?> entry(
  String id,
  String version,
  List<int> archive, {
  String minAppVersion = '1.0.0',
  List<String> dependsOn = const [],
}) =>
    {
      'id': id,
      'kind': 'config',
      'version': version,
      'url': 'https://cdn.example.invalid/$id-$version.zip',
      'size': archive.length,
      'sha256': crypto.sha256.convert(archive).toString(),
      'license': 'TEST-ONLY',
      'minAppVersion': minAppVersion,
      'dependsOn': dependsOn,
    };

/// A zip of [files] (name → text). Names are written as given, even bad
/// ones, to test the extractor.
List<int> zip(Map<String, String> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    archive.add(ArchiveFile.bytes(key, utf8.encode(value)));
  }
  return ZipEncoder().encode(archive);
}

T ok<T>(Result<T> r) => switch (r) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };

/// Serves archives by URL; can break a download after [breakAfter] bytes
/// and can ignore Range.
final class FakeTransport implements ContentTransport {
  FakeTransport(this.files);

  final Map<Uri, List<int>> files;
  final List<int> requestedFrom = [];
  int? breakAfter;
  bool ignoreRange = false;
  bool fail = false;

  @override
  Future<Result<TransportResponse>> get(Uri url, {int from = 0}) async {
    requestedFrom.add(from);
    final data = files[url];
    if (fail || data == null) {
      return const Result.error(SocketException('no network'));
    }
    final start = ignoreRange ? 0 : from;
    final rest = data.sublist(start);
    final limit = breakAfter;
    Stream<List<int>> body() async* {
      const chunk = 64;
      for (var i = 0; i < rest.length; i += chunk) {
        if (limit != null && i >= limit) {
          throw const SocketException('connection reset');
        }
        yield rest.sublist(
          i,
          i + chunk > rest.length ? rest.length : i + chunk,
        );
      }
    }

    return Result.ok(
      TransportResponse(
        statusCode: start == 0 ? 200 : 206,
        rangeStart: start == 0 ? null : start,
        body: body(),
      ),
    );
  }
}

final class FakeDisk implements DiskSpace {
  FakeDisk(this.free);
  int free;

  @override
  Future<Result<int>> freeBytes(String directory) async => Result.ok(free);
}

/// Active versions in memory, like the `download` table.
final class MemoryActiveVersions implements ActiveVersions {
  final Map<String, PackageVersion> versions = {};
  bool failActivate = false;
  bool failActive = false;

  @override
  Future<Result<PackageVersion?>> active(String packageId) async => failActive
      ? const Result.error(FileSystemException('database is unavailable'))
      : Result.ok(versions[packageId]);

  @override
  Future<Result<void>> activate(
    String packageId,
    PackageKind kind,
    PackageVersion version,
  ) async {
    if (failActivate) {
      return const Result.error(FileSystemException('database is locked'));
    }
    versions[packageId] = version;
    return const Result.ok(null);
  }
}

/// Runs the extractor on this isolate (tests stay simple and fast).
final class SyncExtractor implements ArchiveExtractor {
  const SyncExtractor();

  @override
  Future<ExtractProblem?> extract(String archivePath, String target) async =>
      extractZipSync(archivePath, target);
}

/// Real files, but deleting a path that ends with [failDeleteSuffix] fails —
/// like a file held open by another process.
final class FlakyFiles implements ContentFiles {
  FlakyFiles();

  final ContentFiles _real = const IoContentFiles();
  String? failDeleteSuffix;

  @override
  Future<void> delete(String path) async {
    final suffix = failDeleteSuffix;
    if (suffix != null && path.endsWith(suffix)) {
      throw FileSystemException('file is busy', path);
    }
    await _real.delete(path);
  }

  @override
  Future<int> length(String path) => _real.length(path);

  @override
  Future<void> append(String path, Stream<List<int>> data) =>
      _real.append(path, data);

  @override
  Future<void> truncate(String path) => _real.truncate(path);

  @override
  Future<String> sha256(String path) => _real.sha256(path);

  @override
  Future<bool> exists(String path) => _real.exists(path);

  @override
  Future<void> createDirectory(String path) => _real.createDirectory(path);

  @override
  Future<void> rename(String from, String to) => _real.rename(from, to);

  @override
  Future<List<String>> directories(String path) => _real.directories(path);
}
