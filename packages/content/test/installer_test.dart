import 'dart:convert';
import 'dart:io';

import 'package:content/content.dart';
import 'package:contracts/contracts.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

// Test keys, fixtures and manifests built here have a known shape: `!` on
// their fields cannot fail.

void main() {
  late Map<String, TestKey> keys;
  late Directory dir;
  late FakeTransport transport;
  late FakeDisk disk;
  late MemoryActiveVersions versions;
  late PackageInstaller installer;
  late List<PackageState> states;

  setUpAll(() => keys = loadTestKeys());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('content');
    transport = FakeTransport({});
    disk = FakeDisk(1 << 30);
    versions = MemoryActiveVersions();
    states = [];
    installer = PackageInstaller(
      root: p.join(dir.path, 'packages'),
      appVersion: const PackageVersion(1, 2, 0),
      transport: transport,
      files: const IoContentFiles(),
      disk: disk,
      versions: versions,
      extractor: const SyncExtractor(),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// A verified manifest package for [archive], served by the transport.
  Future<ManifestPackage> publish(
    String id,
    String version,
    List<int> archive, {
    String minAppVersion = '1.0.0',
    List<String> dependsOn = const [],
    List<Map<String, Object?>> others = const [],
  }) async {
    final e = entry(
      id,
      version,
      archive,
      minAppVersion: minAppVersion,
      dependsOn: dependsOn,
    );
    transport.files[Uri.parse(e['url']! as String)] = archive;
    final text = await sign(
      {
        'manifestVersion': 1,
        'issuedAt': '2026-11-18T00:00:00Z',
        'packages': [e, ...others],
      },
      keys['test-main']!.seed,
      keyId: 'test-main',
    );
    return ok(await verifyManifest(text, trusted(keys))).package(id)!;
  }

  Future<Result<PackageVersion>> install(ManifestPackage pkg) =>
      installer.install(pkg, onState: states.add);

  InstallFailure failure(Result<PackageVersion> r) =>
      ((r as Error<PackageVersion>).error as InstallException).reason;

  String installedFile(String id, String version, String name) =>
      File(p.join(dir.path, 'packages', id, version, name)).readAsStringSync();

  List<int> bigZip(String marker) => zip({
        'hello.txt': marker,
        // Barely compressible, so the download has many chunks.
        'noise.bin':
            List.generate(4000, (i) => '${(i * 7919) % 104729}').join(','),
      });

  test('the fixture package from the signed fixture manifest installs',
      () async {
    final m = ok(
      await verifyManifest(
        File('$fixtures/manifest.test.json').readAsStringSync(),
        trusted(keys),
      ),
    );
    final pkg = m.package('test-hello')!;
    transport.files[pkg.url] =
        File('$fixtures/hello-1.0.0.zip').readAsBytesSync();
    expect(ok(await install(pkg)), const PackageVersion(1, 0, 0));
    expect(
      installedFile('test-hello', '1.0.0', 'hello.txt'),
      contains('TEST PACKAGE ONLY'),
    );
    expect(
      installedFile('test-hello', '1.0.0', 'data/info.txt'),
      contains('TEST PACKAGE ONLY'),
    );
    expect(versions.versions['test-hello'], const PackageVersion(1, 0, 0));
    // States in the order of docs/tz 11.4.
    expect(states.first, isA<Queued>());
    expect(states.whereType<Downloading>().last.percent, 100);
    expect(
      states.map((s) => s.runtimeType).toSet().toList(),
      [Queued, Downloading, Verifying, Installing, Installed],
    );
    for (var i = 1; i < states.length; i++) {
      expect(states[i - 1].canMoveTo(states[i]), isTrue, reason: '$i');
    }
    // No temporary folder is left.
    expect(
      Directory(p.join(dir.path, 'packages', 'test-hello', '1.0.0.tmp'))
          .existsSync(),
      isFalse,
    );
  });

  test('a broken download resumes from where it stopped (ДФ-04)', () async {
    final archive = bigZip('v1');
    final pkg = await publish('pkg', '1.0.0', archive);
    transport.breakAfter = archive.length ~/ 2;
    final first = await install(pkg);
    expect(failure(first), InstallFailure.network);
    final kept = File(installer.archivePath(pkg)).lengthSync();
    expect(kept, greaterThan(0));
    expect(kept, lessThan(archive.length));
    expect(versions.versions, isEmpty);

    transport.breakAfter = null;
    states.clear();
    expect(ok(await install(pkg)), const PackageVersion(1, 0, 0));
    expect(transport.requestedFrom, [0, kept]);
    expect((states[1] as Downloading).bytesDone, kept);
    expect(installedFile('pkg', '1.0.0', 'hello.txt'), 'v1');
  });

  test('a server that ignores Range: the download starts over', () async {
    final archive = bigZip('v1');
    final pkg = await publish('pkg', '1.0.0', archive);
    transport.breakAfter = archive.length ~/ 2;
    await install(pkg);
    transport
      ..breakAfter = null
      ..ignoreRange = true;
    expect(ok(await install(pkg)), const PackageVersion(1, 0, 0));
    expect(installedFile('pkg', '1.0.0', 'hello.txt'), 'v1');
  });

  Future<void> installV1() async {
    expect(
      ok(await install(await publish('pkg', '1.0.0', zip({'a.txt': 'v1'})))),
      const PackageVersion(1, 0, 0),
    );
  }

  void expectV1Intact() {
    expect(versions.versions['pkg'], const PackageVersion(1, 0, 0));
    expect(installedFile('pkg', '1.0.0', 'a.txt'), 'v1');
  }

  test('a corrupted archive does not break the installed version (ДФ-05)',
      () async {
    await installV1();
    final good = zip({'a.txt': 'v2'});
    final pkg = await publish('pkg', '1.1.0', good);
    final bad = [...good]..[good.length ~/ 2] ^= 0xff;
    transport.files[pkg.url] = bad;
    expect(failure(await install(pkg)), InstallFailure.checksumMismatch);
    expectV1Intact();
    expect(
      Directory(p.join(dir.path, 'packages', 'pkg', '1.1.0')).existsSync(),
      isFalse,
    );
    // The bad download is not resumed: next time starts clean.
    expect(File(installer.archivePath(pkg)).existsSync(), isFalse);
  });

  test('an archive with ../ is refused and writes nothing (zip-slip)',
      () async {
    await installV1();
    final evil = zip({'a.txt': 'v2', '../../../escaped.txt': 'gotcha'});
    final pkg = await publish('pkg', '1.1.0', evil);
    expect(failure(await install(pkg)), InstallFailure.unsafeArchive);
    expectV1Intact();
    final escaped = dir
        .listSync(recursive: true)
        .where((e) => p.basename(e.path) == 'escaped.txt');
    expect(escaped, isEmpty);
  });

  test('a signed archive that is not a zip: bad archive, version kept',
      () async {
    await installV1();
    final pkg = await publish('pkg', '1.1.0', utf8.encode('not a zip' * 50));
    expect(failure(await install(pkg)), InstallFailure.badArchive);
    expectV1Intact();
  });

  test('more bytes than the manifest says: refused', () async {
    final archive = zip({'a.txt': 'v1'});
    final pkg = await publish('pkg', '1.0.0', archive);
    transport.files[pkg.url] = [...archive, ...archive];
    expect(failure(await install(pkg)), InstallFailure.sizeMismatch);
    expect(versions.versions, isEmpty);
  });

  test('minAppVersion above the app: «Обновите приложение», no download',
      () async {
    final pkg = await publish(
      'pkg',
      '1.0.0',
      zip({'a.txt': 'v1'}),
      minAppVersion: '1.3.0',
    );
    expect(failure(await install(pkg)), InstallFailure.appUpdateRequired);
    expect(transport.requestedFrom, isEmpty);
    expect(states.last, isA<Failed>());
  });

  test('not enough space: size × 2 needed (ДФ-03)', () async {
    final archive = zip({'a.txt': 'v1'});
    final pkg = await publish('pkg', '1.0.0', archive);
    disk.free = archive.length * 2 - 1;
    expect(failure(await install(pkg)), InstallFailure.notEnoughSpace);
    expect(transport.requestedFrom, isEmpty);
    disk.free = archive.length * 2;
    expect(await install(pkg), isA<Ok<PackageVersion>>());
  });

  test('a missing dependency stops the install', () async {
    final base = entry('base', '1.0.0', zip({'b.txt': 'b'}));
    final pkg = await publish(
      'pkg',
      '1.0.0',
      zip({'a.txt': 'v1'}),
      dependsOn: ['base'],
      others: [base],
    );
    expect(failure(await install(pkg)), InstallFailure.missingDependency);
    versions.versions['base'] = const PackageVersion(1, 0, 0);
    expect(await install(pkg), isA<Ok<PackageVersion>>());
  });

  test('the database does not switch: the new files are removed', () async {
    await installV1();
    final pkg = await publish('pkg', '1.1.0', zip({'a.txt': 'v2'}));
    versions.failActivate = true;
    expect(failure(await install(pkg)), InstallFailure.activation);
    expectV1Intact();
    expect(
      Directory(p.join(dir.path, 'packages', 'pkg', '1.1.0')).existsSync(),
      isFalse,
    );
  });

  test('no network at all: failed, retry later', () async {
    final pkg = await publish('pkg', '1.0.0', zip({'a.txt': 'v1'}));
    transport.fail = true;
    expect(failure(await install(pkg)), InstallFailure.network);
  });

  test('roll back to the previous version until the next launch', () async {
    await installV1();
    final v2 = await publish('pkg', '1.1.0', zip({'a.txt': 'v2'}));
    expect(ok(await install(v2)), const PackageVersion(1, 1, 0));
    expect(installedFile('pkg', '1.1.0', 'a.txt'), 'v2');
    // The old version is still on disk until a successful launch.
    expect(installedFile('pkg', '1.0.0', 'a.txt'), 'v1');

    expect(
      ok(await installer.rollBack('pkg', PackageKind.config)),
      const PackageVersion(1, 0, 0),
    );
    expectV1Intact();

    // Install the update again, launch, clean up: no way back.
    expect(ok(await install(v2)), const PackageVersion(1, 1, 0));
    ok(await installer.cleanUpAfterLaunch(['pkg']));
    expect(
      Directory(p.join(dir.path, 'packages', 'pkg', '1.0.0')).existsSync(),
      isFalse,
    );
    expect(installedFile('pkg', '1.1.0', 'a.txt'), 'v2');
    expect(
      await installer.rollBack('pkg', PackageKind.config),
      isA<Error<PackageVersion>>(),
    );
  });

  test('clean up keeps an unfinished download to resume', () async {
    await installV1();
    final archive = bigZip('v2');
    final v2 = await publish('pkg', '1.1.0', archive);
    transport.breakAfter = archive.length ~/ 2;
    await install(v2);
    ok(await installer.cleanUpAfterLaunch(['pkg']));
    expect(File(installer.archivePath(v2)).existsSync(), isTrue);
    expectV1Intact();
  });

  group('package states (11.4)', () {
    test('allowed and forbidden moves', () {
      expect(const NotInstalled().canMoveTo(const Queued()), isTrue);
      expect(
        const Failed(InstallFailure.network).canMoveTo(const Queued()),
        isTrue,
      );
      expect(const NotInstalled().canMoveTo(const Installing()), isFalse);
      expect(
        const Verifying().canMoveTo(const Installed(PackageVersion(1, 0, 0))),
        isFalse,
      );
      expect(
        const Installed(PackageVersion(1, 0, 0)).canMoveTo(
          const UpdateAvailable(
            installed: PackageVersion(1, 0, 0),
            available: PackageVersion(1, 1, 0),
          ),
        ),
        isTrue,
      );
    });

    test('state from the manifest and the active version', () async {
      final pkg = await publish('pkg', '1.1.0', zip({'a.txt': 'v2'}));
      expect(stateFor(pkg, null), isA<NotInstalled>());
      expect(stateFor(pkg, const PackageVersion(1, 1, 0)), isA<Installed>());
      final update = stateFor(pkg, const PackageVersion(1, 0, 0));
      expect(update, isA<UpdateAvailable>());
      expect(
        (update as UpdateAvailable).available,
        const PackageVersion(1, 1, 0),
      );
    });

    test('download percent', () {
      expect(const Downloading(bytesDone: 50, bytesTotal: 200).percent, 25);
    });
  });
}
