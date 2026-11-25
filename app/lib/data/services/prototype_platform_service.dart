import 'package:flutter/services.dart';

/// Android platform operations needed by the standalone prototype.
abstract interface class PrototypePlatformService {
  /// Stable private directory for downloaded prototype resources.
  Future<String> applicationDirectory();

  /// Lets the owner select a WAV file and returns a readable local path.
  Future<String?> pickWavFile();

  /// Lets the user select an exported Sudur user-data archive.
  Future<String?> pickUserDataArchive();

  /// Opens the platform share sheet for a JSON log file.
  Future<void> shareFile(String path);
}

/// Method-channel implementation supplied by `MainActivity`.
final class MethodChannelPrototypePlatformService
    implements PrototypePlatformService {
  /// Creates the Android platform adapter.
  const new();

  static const _channel = MethodChannel('kz.sudur/prototype');

  @override
  Future<String> applicationDirectory() async {
    final path = await _channel.invokeMethod<String>('applicationDirectory');
    if (path == null || path.isEmpty) {
      throw StateError('The platform did not return an application directory.');
    }
    return path;
  }

  @override
  Future<String?> pickWavFile() => _channel.invokeMethod<String>('pickWav');

  @override
  Future<String?> pickUserDataArchive() =>
      _channel.invokeMethod<String>('pickUserDataArchive');

  @override
  Future<void> shareFile(String path) =>
      _channel.invokeMethod<void>('shareFile', <String, Object?>{'path': path});
}
