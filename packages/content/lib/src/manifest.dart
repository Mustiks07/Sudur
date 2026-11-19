import 'package:content/src/package_version.dart';
import 'package:meta/meta.dart';

/// Kinds of content packages (docs/tz 4.9).
enum PackageKind {
  /// The whole-Quran text (ADR 0004).
  text,

  /// Page layout of a mushaf.
  layout,

  /// Page fonts.
  font,

  /// Recitation and lesson audio.
  audio,

  /// Recognition model.
  model,

  /// One stage of the reading course.
  lessons,

  /// A translation of meanings.
  translation,

  /// Parameters (docs/tz 8.8, 12.3).
  config,
}

/// One package of the manifest (docs/tz 12.3).
@immutable
final class ManifestPackage {
  /// Creates a package entry.
  const ManifestPackage({
    required this.id,
    required this.kind,
    required this.version,
    required this.url,
    required this.size,
    required this.sha256,
    required this.license,
    required this.minAppVersion,
    required this.dependsOn,
  });

  /// Package id, like `model-quran-asr-small`.
  final String id;

  /// What the package holds.
  final PackageKind kind;

  /// Package version.
  final PackageVersion version;

  /// Where to download the archive; always HTTPS.
  final Uri url;

  /// Archive size in bytes.
  final int size;

  /// SHA-256 of the archive, lower-case hex.
  final String sha256;

  /// License id of the content.
  final String license;

  /// The oldest app version that can use the package.
  final PackageVersion minAppVersion;

  /// Ids of packages that must be installed first.
  final List<String> dependsOn;
}

/// Who signed a manifest and the signature (docs/tz 12.3).
@immutable
final class ManifestSignature {
  /// Creates the signature.
  const ManifestSignature({required this.keyId, required this.ed25519});

  /// Id of the signing key, like `main-2026`.
  final String keyId;

  /// Ed25519 signature of the canonical manifest without `signature`.
  final List<int> ed25519;
}

/// A manifest whose signature has been checked (see `verifyManifest`).
@immutable
final class Manifest {
  /// Creates a manifest.
  const Manifest({
    required this.manifestVersion,
    required this.issuedAt,
    required this.packages,
    required this.signature,
  });

  /// Format of manifests this app reads.
  static const int supportedVersion = 1;

  /// Format of this manifest.
  final int manifestVersion;

  /// When it was issued (UTC).
  final DateTime issuedAt;

  /// Packages in the order of the file.
  final List<ManifestPackage> packages;

  /// The signature that was checked.
  final ManifestSignature signature;

  /// The package with [id], or `null`.
  ManifestPackage? package(String id) {
    for (final p in packages) {
      if (p.id == id) return p;
    }
    return null;
  }
}
