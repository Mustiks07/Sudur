import 'package:content/src/manifest.dart';
import 'package:content/src/package_version.dart';
import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';

/// A response to a download request.
@immutable
final class TransportResponse {
  /// Creates the response.
  const TransportResponse({
    required this.statusCode,
    required this.rangeStart,
    required this.body,
  });

  /// HTTP status: 200 — the whole file, 206 — a range.
  final int statusCode;

  /// For 206: the first byte sent (from `Content-Range`).
  final int? rangeStart;

  /// The bytes. An error in the stream means the connection broke.
  final Stream<List<int>> body;
}

/// Downloads package archives (injected; the app gives the real HTTPS
/// client, tests a fake).
abstract interface class ContentTransport {
  /// GETs [url] from byte [from] (`Range: bytes=from-` when [from] > 0).
  Future<Result<TransportResponse>> get(Uri url, {int from = 0});
}

/// Free space on the phone (the app reads it from the platform).
abstract interface class DiskSpace {
  /// Free bytes on the volume of [directory].
  Future<Result<int>> freeBytes(String directory);
}

/// The active version of each package, kept in the user database
/// (`download.active_version`, docs/tz 12.1). The app connects `storage`;
/// `content` does not depend on it.
abstract interface class ActiveVersions {
  /// The active version of [packageId], or `null`.
  Future<Result<PackageVersion?>> active(String packageId);

  /// Makes [version] the active one in a single transaction (docs/tz 11.4,
  /// step 4).
  Future<Result<void>> activate(
    String packageId,
    PackageKind kind,
    PackageVersion version,
  );
}

/// Files of installed packages (injected so tests can break things).
///
/// Methods throw `FileSystemException` on failure; the installer turns it
/// into a failed install.
abstract interface class ContentFiles {
  /// Length of the file at [path]; 0 if there is none.
  Future<int> length(String path);

  /// Appends [data] to [path] chunk by chunk, creating it; chunks written
  /// before an error in [data] stay on disk.
  Future<void> append(String path, Stream<List<int>> data);

  /// Empties or creates [path].
  Future<void> truncate(String path);

  /// SHA-256 of [path], lower-case hex.
  Future<String> sha256(String path);

  /// Whether a file or directory exists at [path].
  Future<bool> exists(String path);

  /// Creates [path] with parents.
  Future<void> createDirectory(String path);

  /// Renames directory [from] to [to] in one step.
  Future<void> rename(String from, String to);

  /// Deletes [path] with its content; nothing if missing.
  Future<void> delete(String path);

  /// Names of directories directly in [path]; empty if missing.
  Future<List<String>> directories(String path);
}

/// Why an archive was not unpacked.
enum ExtractProblem {
  /// Not a readable zip.
  badArchive,

  /// An entry would land outside the target (zip-slip) or is a link.
  unsafePath,
}

/// Unpacks a zip into a directory.
abstract interface class ArchiveExtractor {
  /// Unpacks [archivePath] into [targetDirectory], or does nothing and
  /// returns the problem.
  Future<ExtractProblem?> extract(String archivePath, String targetDirectory);
}
