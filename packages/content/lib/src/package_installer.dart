import 'dart:async';
import 'dart:io';

import 'package:content/src/manifest.dart';
import 'package:content/src/package_state.dart';
import 'package:content/src/package_version.dart';
import 'package:content/src/ports.dart';
import 'package:contracts/contracts.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final Logger _log = Logger('content');

/// HTTP statuses the download understands.
const int _httpOk = 200;
const int _httpPartial = 206;

/// The install failed; the previously active version is untouched.
final class InstallException implements Exception {
  /// Creates the error.
  const InstallException(this.reason, [this.detail = '']);

  /// Why.
  final InstallFailure reason;

  /// Details for logs.
  final String detail;

  @override
  String toString() => 'Install failed: ${reason.name} $detail';
}

/// Downloads and installs packages "whole or nothing" (ДФ-03…ДФ-05,
/// docs/tz 11.4):
///
/// 1. download into `<root>/<id>/<version>.tmp/`, resuming from where an
///    earlier attempt stopped (HTTP Range);
/// 2. check size and SHA-256 against the verified manifest;
/// 3. unpack safely, rename to `<root>/<id>/<version>/`;
/// 4. make it active in the user database in one transaction;
/// 5. older versions are deleted by [cleanUpAfterLaunch] after the next
///    successful launch; until then [rollBack] can return to one.
///
/// A failure at any step leaves the active version as it was.
final class PackageInstaller {
  /// Creates the installer. [root] is the folder for packages; [appVersion]
  /// is the running app's version.
  PackageInstaller({
    required this.root,
    required this.appVersion,
    required ContentTransport transport,
    required ContentFiles files,
    required DiskSpace disk,
    required ActiveVersions versions,
    required ArchiveExtractor extractor,
  })  : _transport = transport,
        _files = files,
        _disk = disk,
        _versions = versions,
        _extractor = extractor;

  /// Folder that holds `<id>/<version>/`.
  final String root;

  /// Version of the running app.
  final PackageVersion appVersion;

  final ContentTransport _transport;
  final ContentFiles _files;
  final DiskSpace _disk;
  final ActiveVersions _versions;
  final ArchiveExtractor _extractor;

  /// Folder of [packageId].
  String packageDirectory(String packageId) => p.join(root, packageId);

  /// Folder of an installed [version].
  String versionDirectory(String packageId, PackageVersion version) =>
      p.join(packageDirectory(packageId), '$version');

  String _tempDirectory(ManifestPackage pkg) =>
      p.join(packageDirectory(pkg.id), '${pkg.version}$_tempSuffix');

  /// Where the archive is downloaded to (kept between attempts).
  String archivePath(ManifestPackage pkg) =>
      p.join(_tempDirectory(pkg), 'package.zip');

  /// Installs [pkg] of a verified manifest, reporting every state to
  /// [onState]. Returns the installed version or an [InstallException].
  Future<Result<PackageVersion>> install(
    ManifestPackage pkg, {
    required void Function(PackageState state) onState,
  }) async {
    PackageState state = const Queued();
    onState(state);
    void move(PackageState next) {
      assert(
        state.canMoveTo(next),
        '${state.runtimeType} → ${next.runtimeType}',
      );
      state = next;
      onState(next);
    }

    Result<PackageVersion> fail(InstallFailure reason, [String detail = '']) {
      _log.warning('${pkg.id} ${pkg.version}: ${reason.name} $detail');
      move(Failed(reason));
      return Result.error(InstallException(reason, detail));
    }

    try {
      // Checks before any byte is loaded.
      if (pkg.minAppVersion > appVersion) {
        return fail(InstallFailure.appUpdateRequired, '${pkg.minAppVersion}');
      }
      if (pkg.url.scheme != 'https') return fail(InstallFailure.insecureUrl);
      for (final dependency in pkg.dependsOn) {
        switch (await _versions.active(dependency)) {
          case Ok(value: null):
            return fail(InstallFailure.missingDependency, dependency);
          case Ok():
            break;
          case Error(:final error):
            return fail(InstallFailure.activation, '$error');
        }
      }
      final archive = archivePath(pkg);
      var done = await _files.length(archive);
      if (done > pkg.size) {
        await _files.truncate(archive);
        done = 0;
      }
      switch (await _disk.freeBytes(root)) {
        // Room for the archive and the unpacked files (ДФ-03).
        case Ok(:final value) when value < (pkg.size - done) + pkg.size:
          return fail(InstallFailure.notEnoughSpace, '$value free');
        case Ok():
          break;
        case Error(:final error):
          return fail(InstallFailure.storage, '$error');
      }

      // Download, resuming after [done] bytes (ДФ-04).
      move(Downloading(bytesDone: done, bytesTotal: pkg.size));
      if (done < pkg.size) {
        final loaded = await _download(pkg, archive, done, (bytes) {
          move(Downloading(bytesDone: bytes, bytesTotal: pkg.size));
        });
        if (loaded != null) return fail(loaded);
      }

      // Verify.
      move(const Verifying());
      final length = await _files.length(archive);
      final hash = length == pkg.size ? await _files.sha256(archive) : null;
      if (hash != pkg.sha256) {
        // A wrong archive is never resumed: start clean next time.
        await _files.delete(_tempDirectory(pkg));
        return fail(InstallFailure.checksumMismatch);
      }

      // Unpack into the temporary folder, then rename.
      move(const Installing());
      final unpacked = p.join(_tempDirectory(pkg), 'unpacked');
      await _files.delete(unpacked);
      await _files.createDirectory(unpacked);
      switch (await _extractor.extract(archive, unpacked)) {
        case ExtractProblem.badArchive:
          await _files.delete(_tempDirectory(pkg));
          return fail(InstallFailure.badArchive);
        case ExtractProblem.unsafePath:
          await _files.delete(_tempDirectory(pkg));
          return fail(InstallFailure.unsafeArchive);
        case null:
          break;
      }
      final target = versionDirectory(pkg.id, pkg.version);
      // Nothing on disk is replaced until the active version is known: if
      // the database cannot say, the live files might be this version.
      final PackageVersion? active;
      switch (await _versions.active(pkg.id)) {
        case Ok(:final value):
          active = value;
        case Error(:final error):
          // The checked archive stays for the next attempt.
          await _cleanUp(unpacked);
          return fail(InstallFailure.activation, '$error');
      }
      if (active == pkg.version) {
        // Reinstalling the active version: never replace live files.
        await _cleanUp(_tempDirectory(pkg));
        move(Installed(pkg.version));
        return Result.ok(pkg.version);
      }
      await _files.delete(target); // A leftover of an unfinished attempt.
      await _files.rename(unpacked, target);

      // Switch the active version: one transaction in the user database.
      switch (await _versions.activate(pkg.id, pkg.kind, pkg.version)) {
        case Ok():
          break;
        case Error(:final error):
          await _cleanUp(target);
          return fail(InstallFailure.activation, '$error');
      }
      // The new version is active from here on; a failed clean-up does not
      // change that and is retried by [cleanUpAfterLaunch].
      await _cleanUp(_tempDirectory(pkg));
      move(Installed(pkg.version));
      return Result.ok(pkg.version);
    } on FileSystemException catch (e) {
      return fail(InstallFailure.storage, e.message);
    }
  }

  /// Deletes [path] if it can; a failure is only logged. Leftovers are
  /// removed later by [cleanUpAfterLaunch].
  Future<void> _cleanUp(String path) async {
    try {
      await _files.delete(path);
    } on FileSystemException catch (e) {
      _log.warning('clean-up of $path postponed: ${e.message}');
    }
  }

  /// Downloads the rest of [pkg] into [archive]; `null` when complete.
  Future<InstallFailure?> _download(
    ManifestPackage pkg,
    String archive,
    int done,
    void Function(int bytes) progress,
  ) async {
    final TransportResponse response;
    switch (await _transport.get(pkg.url, from: done)) {
      case Ok(:final value):
        response = value;
      case Error():
        return InstallFailure.network;
    }
    var bytes = done;
    switch (response.statusCode) {
      case _httpPartial when response.rangeStart == done:
        break;
      case _httpOk:
        // The server ignored the range: start over.
        await _files.truncate(archive);
        bytes = 0;
      default:
        return InstallFailure.network;
    }
    var tooLong = false;
    final counted = response.body.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          if (tooLong) return;
          if (bytes + chunk.length > pkg.size) {
            tooLong = true;
            sink.close();
            return;
          }
          bytes += chunk.length;
          sink.add(chunk);
          progress(bytes);
        },
      ),
    );
    try {
      await _files.append(archive, counted);
    } on IOException catch (e) {
      // Broken connection: what arrived stays on disk for the next attempt.
      _log.info('${pkg.id}: download stopped at $bytes bytes: $e');
      return InstallFailure.network;
    }
    if (tooLong) {
      await _files.delete(_tempDirectory(pkg));
      return InstallFailure.sizeMismatch;
    }
    return bytes == pkg.size ? null : InstallFailure.network;
  }

  /// Installed versions of [packageId] on disk, newest first.
  Future<List<PackageVersion>> installedVersions(String packageId) async => [
        for (final name
            in await _files.directories(packageDirectory(packageId)))
          if (PackageVersion.tryParse(name) case final v?) v,
      ]..sort((a, b) => b.compareTo(a));

  /// Makes the newest version older than the active one active again, while
  /// it is still on disk (before [cleanUpAfterLaunch]). Returns it.
  Future<Result<PackageVersion>> rollBack(
    String packageId,
    PackageKind kind,
  ) async {
    final PackageVersion? active;
    switch (await _versions.active(packageId)) {
      case Ok(:final value):
        active = value;
      case Error(:final error):
        return Result.error(error);
    }
    final previous = [
      for (final v in await installedVersions(packageId))
        if (active == null || v < active) v,
    ].firstOrNull;
    if (previous == null) {
      return Result.error(
        InstallException(
          InstallFailure.storage,
          'no older version of $packageId',
        ),
      );
    }
    return switch (await _versions.activate(packageId, kind, previous)) {
      Ok() => Result.ok(previous),
      Error(:final error) => Result.error(error),
    };
  }

  /// After a successful launch on the new versions: deletes every version
  /// of [packageIds] that is not active (docs/tz 11.4, step 5), and
  /// temporary folders of the active or older versions that an earlier
  /// clean-up could not remove. Unfinished downloads of newer versions are
  /// kept to resume.
  Future<Result<void>> cleanUpAfterLaunch(Iterable<String> packageIds) async {
    try {
      for (final id in packageIds) {
        final PackageVersion? active;
        switch (await _versions.active(id)) {
          case Ok(:final value):
            active = value;
          case Error(:final error):
            return Result.error(error);
        }
        if (active == null) continue;
        for (final v in await installedVersions(id)) {
          if (v != active) await _files.delete(versionDirectory(id, v));
        }
        for (final name in await _files.directories(packageDirectory(id))) {
          if (!name.endsWith(_tempSuffix)) continue;
          final v = PackageVersion.tryParse(
            name.substring(0, name.length - _tempSuffix.length),
          );
          if (v != null && !(v > active)) {
            await _files.delete(p.join(packageDirectory(id), name));
          }
        }
      }
      return const Result.ok(null);
    } on FileSystemException catch (e) {
      return Result.error(e);
    }
  }
}

const String _tempSuffix = '.tmp';
