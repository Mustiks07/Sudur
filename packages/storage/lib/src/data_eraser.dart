import 'package:contracts/contracts.dart';
import 'package:storage/src/database.dart';
import 'package:storage/src/storage_exception.dart';

/// Deletes files explicitly saved by the user.
abstract interface class RecordingFileSystem {
  /// Deletes the recording at [path].
  Future<void> deleteRecording(String path);
}

/// Completely removes user database rows and saved recording files.
final class UserDataEraser {
  /// Creates the eraser with an externally supplied file-system boundary.
  const UserDataEraser(this._database, this._fileSystem);

  final SudurDatabase _database;
  final RecordingFileSystem _fileSystem;

  /// Deletes all saved recording files and then clears every user table.
  Future<Result<void>> eraseAll() async {
    try {
      final recordings =
          await _database.select(_database.savedRecordings).get();
      for (final recording in recordings) {
        await _fileSystem.deleteRecording(recording.path);
      }
      await _database.transaction(() async {
        for (final table in schemaV1TableNames.reversed) {
          await _database.customStatement('DELETE FROM "$table"');
        }
      });
      return const Result<void>.ok(null);
    } on Exception catch (error) {
      return Result<void>.error(error);
    } on Object catch (_) {
      return const Result<void>.error(StorageException('eraseFailed'));
    }
  }
}
