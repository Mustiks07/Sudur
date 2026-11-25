import 'package:storage/storage.dart';
import 'package:sudur/data/services/prototype_platform_service.dart';

// Keep the constructor spelling consistent with the rest of the application.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Lazily opens the user database after the platform directory is available.
final class AppStorageService {
  /// Creates a file-backed production service.
  AppStorageService(PrototypePlatformService platform)
    : _storage = _open(platform);

  /// Creates a service around an injected database for tests.
  AppStorageService.fromStorage(StorageService storage)
    : _storage = Future<StorageService>.value(storage);

  final Future<StorageService> _storage;

  /// Ready storage facade; drift rows remain inside data repositories.
  Future<StorageService> get storage => _storage;

  static Future<StorageService> _open(PrototypePlatformService platform) async {
    final directory = await platform.applicationDirectory();
    return StorageService.openFile('$directory/sudur-user.sqlite');
  }

  /// Closes the database after all pending initialization completes.
  Future<void> dispose() => _storage.then((storage) => storage.close());
}
