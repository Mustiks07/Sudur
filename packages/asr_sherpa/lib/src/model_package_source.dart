import 'package:contracts/contracts.dart';

/// Resolves active ASR package directories installed by `content`.
///
/// The application adapter must read `content.ActiveVersions` and use
/// `PackageInstaller.versionDirectory`; ASR never downloads or activates a
/// package on its own. Tests use an in-memory fake of this interface.
abstract interface class AsrModelPackageSource {
  /// Absolute active directory for [packageId], or an explicit error.
  Future<Result<String>> activeDirectory(String packageId);
}
