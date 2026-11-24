import 'dart:io';
import 'dart:typed_data';

// Private application files are necessarily inspected before deletion.
// ignore_for_file: avoid_slow_async_io, unnecessary_type_name_in_constructor

import 'package:storage/storage.dart';
import 'package:sudur/data/services/prototype_platform_service.dart';

/// Private-file operations used by user-data and download settings.
final class AppFileService implements RecordingFileSystem {
  /// Creates a file service over platform pick/share operations.
  const AppFileService(this._platform);

  final PrototypePlatformService _platform;

  /// Writes and shares an exported user-data archive.
  Future<void> shareUserData(Uint8List bytes) async {
    final root = Directory(await _platform.applicationDirectory());
    final directory = Directory('${root.path}/user-data');
    await directory.create(recursive: true);
    final file = File('${directory.path}/sudur-user-data.zip');
    await file.writeAsBytes(bytes, flush: true);
    await _platform.shareFile(file.path);
  }

  /// Selects a copied archive from the platform picker.
  Future<Uint8List?> pickUserData() async {
    final path = await _platform.pickUserDataArchive();
    if (path == null) return null;
    return await File(path).readAsBytes();
  }

  /// Removes downloaded model directories from the private application root.
  Future<void> deleteModels() async {
    final root = Directory(await _platform.applicationDirectory());
    final models = Directory('${root.path}/models');
    if (await models.exists()) await models.delete(recursive: true);
  }

  @override
  Future<void> deleteRecording(String path) async {
    final root = Directory(await _platform.applicationDirectory());
    final rootPath = root.absolute.path;
    final recording = File(path).absolute;
    if (recording.path != rootPath &&
        !recording.path.startsWith('$rootPath${Platform.pathSeparator}')) {
      throw const FileSystemException(
        'A recording is outside private application storage.',
      );
    }
    if (await recording.exists()) await recording.delete();
  }
}
