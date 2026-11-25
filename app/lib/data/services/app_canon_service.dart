import 'dart:io';
import 'dart:isolate';

import 'package:sudur/data/models/canon_index.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';

/// Gives the positions of ayahs and default passages of the whole Quran.
abstract interface class AppCanonService {
  /// Installs the text if needed (network) and returns its index.
  Future<CanonIndex> load();
}

/// Reads the verified files installed by [PrototypeAssetInstaller].
final class InstalledCanonService implements AppCanonService {
  /// Creates the service.
  // The class name keeps the service easy to scan.
  // ignore: unnecessary_type_name_in_constructor
  InstalledCanonService(this._installer);

  final PrototypeAssetInstaller _installer;
  Future<CanonIndex>? _loading;

  @override
  Future<CanonIndex> load() async {
    final loading = _loading ??= _load();
    try {
      return await loading;
    } on Object {
      // A failed load (no network) is tried again on the next call.
      _loading = null;
      rethrow;
    }
  }

  Future<CanonIndex> _load() async {
    final files = await _installer.installCanon(onProgress: (_) {});
    // 1.5 MB of JSON: parsed off the UI isolate.
    return await Isolate.run(
      () => CanonIndex.parse(
        File(files.textPath).readAsStringSync(),
        File(files.derivedPath).readAsStringSync(),
      ),
    );
  }
}
