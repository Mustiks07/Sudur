import 'package:content/src/manifest.dart';
import 'package:content/src/package_version.dart';
import 'package:meta/meta.dart';

/// Why an install failed (docs/tz 11.4, `failed(причина)`).
enum InstallFailure {
  /// The package needs a newer app: «Обновите приложение».
  appUpdateRequired,

  /// A package it depends on is not installed.
  missingDependency,

  /// Less free space than twice the package size (ДФ-03).
  notEnoughSpace,

  /// The address is not HTTPS.
  insecureUrl,

  /// The download broke off; what was loaded is kept to resume (ДФ-04).
  network,

  /// The server sent more bytes than the manifest says.
  sizeMismatch,

  /// SHA-256 of the archive differs from the manifest.
  checksumMismatch,

  /// The archive cannot be read.
  badArchive,

  /// An archive entry would land outside the package folder (zip-slip) or
  /// is a link.
  unsafeArchive,

  /// Reading or writing files failed.
  storage,

  /// The user database did not record the new active version.
  activation,
}

/// State of a package (docs/tz 11.4):
///
/// ```text
/// notInstalled → queued → downloading(%) → verifying → installing → installed
///                                    ↘ failed(reason) → queued (retry)
/// installed → updateAvailable → (the same path for the new version)
/// ```
@immutable
sealed class PackageState {
  const PackageState();

  /// Whether the state may move to [next].
  bool canMoveTo(PackageState next) => switch ((this, next)) {
        (NotInstalled() || Failed() || UpdateAvailable(), Queued()) => true,
        (Queued(), Downloading() || Failed()) => true,
        (Downloading(), Downloading() || Verifying() || Failed()) => true,
        (Verifying(), Installing() || Failed()) => true,
        (Installing(), Installed() || Failed()) => true,
        (Installed(), UpdateAvailable()) => true,
        _ => false,
      };
}

/// Not on the phone.
final class NotInstalled extends PackageState {
  /// Creates the state.
  const NotInstalled();
}

/// Waiting to download.
final class Queued extends PackageState {
  /// Creates the state.
  const Queued();
}

/// Downloading.
final class Downloading extends PackageState {
  /// Creates the state.
  const Downloading({required this.bytesDone, required this.bytesTotal});

  /// Bytes on the phone, including those of an earlier attempt.
  final int bytesDone;

  /// Archive size.
  final int bytesTotal;

  /// Whole percent done, 0..100.
  int get percent => bytesTotal == 0 ? 0 : bytesDone * 100 ~/ bytesTotal;

  @override
  bool operator ==(Object other) =>
      other is Downloading &&
      other.bytesDone == bytesDone &&
      other.bytesTotal == bytesTotal;

  @override
  int get hashCode => Object.hash(bytesDone, bytesTotal);
}

/// Checking the size and SHA-256.
final class Verifying extends PackageState {
  /// Creates the state.
  const Verifying();
}

/// Unpacking and switching the active version.
final class Installing extends PackageState {
  /// Creates the state.
  const Installing();
}

/// Installed and active.
final class Installed extends PackageState {
  /// Creates the state.
  const Installed(this.version);

  /// The active version.
  final PackageVersion version;
}

/// The manifest has a newer version than the installed one.
final class UpdateAvailable extends PackageState {
  /// Creates the state.
  const UpdateAvailable({required this.installed, required this.available});

  /// The active version.
  final PackageVersion installed;

  /// The manifest version.
  final PackageVersion available;
}

/// The last attempt failed.
final class Failed extends PackageState {
  /// Creates the state.
  const Failed(this.reason);

  /// Why.
  final InstallFailure reason;
}

/// State of [package] when [active] is installed (or nothing is).
PackageState stateFor(ManifestPackage package, PackageVersion? active) =>
    switch (active) {
      null => const NotInstalled(),
      final v when package.version > v =>
        UpdateAvailable(installed: v, available: package.version),
      final v => Installed(v),
    };
