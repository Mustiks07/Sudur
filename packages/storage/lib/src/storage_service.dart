import 'dart:typed_data';

import 'package:contracts/contracts.dart';
import 'package:storage/src/data_archive.dart';
import 'package:storage/src/data_eraser.dart';
import 'package:storage/src/database.dart';
import 'package:storage/src/repositories.dart';

/// Public storage facade that keeps drift types inside this package.
final class StorageService {
  StorageService._(
    SudurDatabase database, {
    required StorageArchiveLimits archiveLimits,
  })  : _database = database,
        _archiveLimits = archiveLimits,
        profiles = DriftProfileRepository(database),
        units = DriftUnitRepository(database),
        attempts = DriftAttemptRepository(database),
        checkEvents = DriftCheckEventRepository(database),
        sessions = DriftSessionRepository(database),
        lessons = DriftLessonRepository(database),
        settings = DriftSettingsRepository(database),
        downloads = DriftDownloadRepository(database),
        recordings = DriftRecordingRepository(database),
        uploads = DriftUploadQueueRepository(database),
        dailyPlans = DriftDailyPlanRepository(database),
        freeUsage = DriftFreeUsageRepository(database),
        entitlements = DriftEntitlementRepository(database),
        searchKeys = DriftSearchKeyCacheRepository(database),
        ngrams = DriftNgramCacheRepository(database),
        outbox = DriftOutboxRepository(database);

  /// Opens a file-backed database on drift's background isolate.
  factory StorageService.openFile(
    String path, {
    StorageArchiveLimits archiveLimits = const StorageArchiveLimits(),
  }) =>
      StorageService._(
        SudurDatabase.openFile(path),
        archiveLimits: archiveLimits,
      );

  /// Opens an in-memory database for tests.
  factory StorageService.memory({
    StorageArchiveLimits archiveLimits = const StorageArchiveLimits(),
  }) =>
      StorageService._(
        SudurDatabase.memory(),
        archiveLimits: archiveLimits,
      );

  final SudurDatabase _database;
  final StorageArchiveLimits _archiveLimits;

  /// Profile repository.
  final ProfileRepository profiles;

  /// Plan-unit repository.
  final UnitRepository units;

  /// Attempt repository.
  final AttemptRepository attempts;

  /// Check-event repository.
  final CheckEventRepository checkEvents;

  /// Reading-session repository.
  final SessionRepository sessions;

  /// Lesson-progress repository.
  final LessonRepository lessons;

  /// Settings repository.
  final SettingsRepository settings;

  /// Installed-package repository.
  final DownloadRepository downloads;

  /// Saved-recording metadata repository.
  final RecordingRepository recordings;

  /// Recording-upload queue repository.
  final UploadQueueRepository uploads;

  /// Daily-plan repository.
  final DailyPlanRepository dailyPlans;

  /// Free voice-usage repository.
  final FreeUsageRepository freeUsage;

  /// Entitlement cache repository.
  final EntitlementRepository entitlements;

  /// Search-key cache repository.
  final SearchKeyCacheRepository searchKeys;

  /// N-gram cache repository.
  final NgramCacheRepository ngrams;

  /// Future sync-outbox repository.
  final OutboxRepository outbox;

  /// Exports every user table as JSON inside a zip archive.
  Future<Result<Uint8List>> exportData() => UserDataArchiveService(
        _database,
        limits: _archiveLimits,
      ).exportData();

  /// Validates and atomically imports a user-data archive.
  Future<Result<void>> importData(Uint8List bytes) => UserDataArchiveService(
        _database,
        limits: _archiveLimits,
      ).importData(bytes);

  /// Removes all database rows and explicitly saved recording files.
  Future<Result<void>> eraseAll(RecordingFileSystem fileSystem) =>
      UserDataEraser(_database, fileSystem).eraseAll();

  /// Closes the database and its background isolate, when present.
  Future<void> close() => _database.close();
}
