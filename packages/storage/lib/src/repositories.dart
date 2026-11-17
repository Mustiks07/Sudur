import 'package:contracts/contracts.dart';
import 'package:drift/drift.dart';
import 'package:storage/src/database.dart';
import 'package:storage/src/storage_exception.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

final _localDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// A complete atomic write after one passage.
final class PassageWrite {
  /// Creates an atomic passage write.
  const PassageWrite({
    required this.attempt,
    required this.checkEvents,
    required this.unitState,
  });

  /// Attempt completed for the passage.
  final AttemptRecord attempt;

  /// Check events produced by the attempt.
  final List<CheckEventRecord> checkEvents;

  /// New scheduling state for the attempted unit.
  final UnitStateRecord unitState;
}

/// Profile persistence.
abstract interface class ProfileRepository {
  /// Inserts or replaces the V1 profile.
  Future<Result<void>> put(ProfileRecord profile);

  /// Returns all profiles (one in V1).
  Future<Result<List<ProfileRecord>>> list();
}

/// Plan-unit and unit-state persistence.
abstract interface class UnitRepository {
  /// Inserts or replaces a unit.
  Future<Result<void>> putUnit(UnitRecord unit);

  /// Inserts or replaces unit state.
  Future<Result<void>> putState(UnitStateRecord state);

  /// Returns units for [profileId].
  Future<Result<List<UnitRecord>>> listForProfile(String profileId);

  /// Returns state for [unitId], if present.
  Future<Result<UnitStateRecord?>> getState(String unitId);
}

/// Attempt persistence and the НФ-21 atomic passage write.
abstract interface class AttemptRepository {
  /// Inserts one attempt.
  Future<Result<void>> add(AttemptRecord attempt);

  /// Returns attempts for [unitId] in chronological order.
  Future<Result<List<AttemptRecord>>> listForUnit(String unitId);

  /// Writes an attempt, its events and new unit state atomically.
  Future<Result<void>> recordPassage(PassageWrite write);
}

/// Check-event persistence.
abstract interface class CheckEventRepository {
  /// Inserts or replaces a check event.
  Future<Result<void>> put(CheckEventRecord event);

  /// Returns events for [sessionId] in creation order.
  Future<Result<List<CheckEventRecord>>> listForSession(String sessionId);
}

/// Reading-session persistence.
abstract interface class SessionRepository {
  /// Inserts or replaces a session.
  Future<Result<void>> put(SessionRecord session);

  /// Returns sessions for [profileId] in start order.
  Future<Result<List<SessionRecord>>> listForProfile(String profileId);
}

/// Lesson progress persistence.
abstract interface class LessonRepository {
  /// Inserts or replaces lesson progress.
  Future<Result<void>> put(LessonProgressRecord progress);

  /// Returns all lesson progress rows.
  Future<Result<List<LessonProgressRecord>>> list();
}

/// Settings persistence.
abstract interface class SettingsRepository {
  /// Inserts or replaces a setting.
  Future<Result<void>> put(SettingRecord setting);

  /// Returns a setting by [key], if present.
  Future<Result<SettingRecord?>> get(String key);

  /// Returns all settings.
  Future<Result<List<SettingRecord>>> list();
}

/// Installed-package persistence.
abstract interface class DownloadRepository {
  /// Inserts or replaces package state.
  Future<Result<void>> put(DownloadRecord download);

  /// Returns all package states.
  Future<Result<List<DownloadRecord>>> list();
}

/// Explicitly saved recording metadata persistence.
abstract interface class RecordingRepository {
  /// Inserts or replaces saved recording metadata.
  Future<Result<void>> put(SavedRecordingRecord recording);

  /// Returns all saved recording metadata.
  Future<Result<List<SavedRecordingRecord>>> list();

  /// Removes metadata for [id].
  Future<Result<void>> remove(String id);
}

/// Consented recording-upload queue persistence.
abstract interface class UploadQueueRepository {
  /// Inserts or replaces an upload item.
  Future<Result<void>> put(UploadQueueRecord upload);

  /// Returns upload items ordered by state, priority and creation time.
  Future<Result<List<UploadQueueRecord>>> list();
}

/// Stable daily-plan persistence.
abstract interface class DailyPlanRepository {
  /// Inserts or replaces a day plan.
  Future<Result<void>> put(DailyPlanRecord plan);

  /// Returns the plan for [date], if present.
  Future<Result<DailyPlanRecord?>> get(String date);
}

/// Free voice-usage persistence.
abstract interface class FreeUsageRepository {
  /// Inserts or replaces daily usage.
  Future<Result<void>> put(FreeUsageRecord usage);

  /// Returns usage for [date], if present.
  Future<Result<FreeUsageRecord?>> get(String date);
}

/// Cached entitlement persistence.
abstract interface class EntitlementRepository {
  /// Inserts or replaces entitlement state.
  Future<Result<void>> put(EntitlementCacheRecord entitlement);

  /// Returns the premium entitlement, if cached.
  Future<Result<EntitlementCacheRecord?>> getPremium();
}

/// Search-key cache persistence.
abstract interface class SearchKeyCacheRepository {
  /// Replaces all keys for [normalizerId].
  Future<Result<void>> replace(
    String normalizerId,
    List<SearchKeyCacheRecord> entries,
  );

  /// Returns all keys for [normalizerId].
  Future<Result<List<SearchKeyCacheRecord>>> list(String normalizerId);
}

/// N-gram cache persistence.
abstract interface class NgramCacheRepository {
  /// Replaces all n-grams for [normalizerId].
  Future<Result<void>> replace(
    String normalizerId,
    List<NgramCacheRecord> entries,
  );

  /// Returns all n-grams for [normalizerId].
  Future<Result<List<NgramCacheRecord>>> list(String normalizerId);
}

/// Future sync-outbox persistence. The table starts empty in schema v1.
abstract interface class OutboxRepository {
  /// Adds an event to the outbox.
  Future<Result<void>> add(OutboxRecord event);

  /// Returns queued events in creation order.
  Future<Result<List<OutboxRecord>>> list();
}

/// Drift implementation of [ProfileRepository].
final class DriftProfileRepository implements ProfileRepository {
  /// Creates the repository.
  const DriftProfileRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<void>> put(ProfileRecord profile) => _guard(() async {
        _validateUuid(profile.id, 'profile.id');
        await _database
            .into(_database.profiles)
            .insertOnConflictUpdate(profile);
      });

  @override
  Future<Result<List<ProfileRecord>>> list() =>
      _guard(() => _database.select(_database.profiles).get());
}

/// Drift implementation of [UnitRepository].
final class DriftUnitRepository implements UnitRepository {
  /// Creates the repository.
  const DriftUnitRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<UnitStateRecord?>> getState(String unitId) => _guard(() {
        _validateUuid(unitId, 'unitId');
        final query = _database.select(_database.unitStates)
          ..where((row) => row.unitId.equals(unitId));
        return query.getSingleOrNull();
      });

  @override
  Future<Result<List<UnitRecord>>> listForProfile(String profileId) =>
      _guard(() {
        _validateUuid(profileId, 'profileId');
        final query = _database.select(_database.units)
          ..where((row) => row.profileId.equals(profileId))
          ..orderBy(<OrderingTerm Function(Units)>[
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return query.get();
      });

  @override
  Future<Result<void>> putState(UnitStateRecord state) => _guard(() async {
        _validateUuid(state.unitId, 'unit_state.unit_id');
        await _database
            .into(_database.unitStates)
            .insertOnConflictUpdate(state);
      });

  @override
  Future<Result<void>> putUnit(UnitRecord unit) => _guard(() async {
        _validateUnit(unit);
        await _database.into(_database.units).insertOnConflictUpdate(unit);
      });
}

/// Drift implementation of [AttemptRepository].
final class DriftAttemptRepository implements AttemptRepository {
  /// Creates the repository.
  const DriftAttemptRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<void>> add(AttemptRecord attempt) => _guard(() async {
        _validateAttempt(attempt);
        await _database.into(_database.attempts).insert(attempt);
      });

  @override
  Future<Result<List<AttemptRecord>>> listForUnit(String unitId) => _guard(() {
        _validateUuid(unitId, 'unitId');
        final query = _database.select(_database.attempts)
          ..where((row) => row.unitId.equals(unitId))
          ..orderBy(<OrderingTerm Function(Attempts)>[
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return query.get();
      });

  @override
  Future<Result<void>> recordPassage(PassageWrite write) => _guard(() async {
        _validateAttempt(write.attempt);
        if (write.unitState.unitId != write.attempt.unitId) {
          throw const FormatException(
            'Attempt and unit state must reference the same unit.',
          );
        }
        for (final event in write.checkEvents) {
          _validateCheckEvent(event);
          if (event.sessionId != write.attempt.sessionId) {
            throw const FormatException(
              'Attempt and check events must reference the same session.',
            );
          }
        }
        await _database.transaction(() async {
          await _database.into(_database.attempts).insert(write.attempt);
          for (final event in write.checkEvents) {
            await _database.into(_database.checkEvents).insert(event);
          }
          await _database
              .into(_database.unitStates)
              .insertOnConflictUpdate(write.unitState);
        });
      });
}

/// Drift implementation of [CheckEventRepository].
final class DriftCheckEventRepository implements CheckEventRepository {
  /// Creates the repository.
  const DriftCheckEventRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<CheckEventRecord>>> listForSession(String sessionId) =>
      _guard(() {
        _validateUuid(sessionId, 'sessionId');
        final query = _database.select(_database.checkEvents)
          ..where((row) => row.sessionId.equals(sessionId))
          ..orderBy(<OrderingTerm Function(CheckEvents)>[
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return query.get();
      });

  @override
  Future<Result<void>> put(CheckEventRecord event) => _guard(() async {
        _validateCheckEvent(event);
        await _database
            .into(_database.checkEvents)
            .insertOnConflictUpdate(event);
      });
}

/// Drift implementation of [SessionRepository].
final class DriftSessionRepository implements SessionRepository {
  /// Creates the repository.
  const DriftSessionRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<SessionRecord>>> listForProfile(String profileId) =>
      _guard(() {
        _validateUuid(profileId, 'profileId');
        final query = _database.select(_database.sessions)
          ..where((row) => row.profileId.equals(profileId))
          ..orderBy(<OrderingTerm Function(Sessions)>[
            (row) => OrderingTerm.asc(row.startedAt),
          ]);
        return query.get();
      });

  @override
  Future<Result<void>> put(SessionRecord session) => _guard(() async {
        _validateUuid(session.id, 'session.id');
        _validateUuid(session.profileId, 'session.profile_id');
        _validateRange(session.fromWordIndex, session.toWordIndex, 'session');
        if (session.signalOkRatio case final ratio?
            when ratio < 0 || ratio > 1) {
          throw const FormatException('signal_ok_ratio must be from 0 to 1.');
        }
        await _database
            .into(_database.sessions)
            .insertOnConflictUpdate(session);
      });
}

/// Drift implementation of [LessonRepository].
final class DriftLessonRepository implements LessonRepository {
  /// Creates the repository.
  const DriftLessonRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<LessonProgressRecord>>> list() =>
      _guard(() => _database.select(_database.lessonProgressEntries).get());

  @override
  Future<Result<void>> put(LessonProgressRecord progress) => _guard(() async {
        if (progress.quizPercent < 0 || progress.quizPercent > 100) {
          throw const FormatException('quiz_percent must be from 0 to 100.');
        }
        await _database
            .into(_database.lessonProgressEntries)
            .insertOnConflictUpdate(progress);
      });
}

/// Drift implementation of [SettingsRepository].
final class DriftSettingsRepository implements SettingsRepository {
  /// Creates the repository.
  const DriftSettingsRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<SettingRecord?>> get(String key) => _guard(() {
        final query = _database.select(_database.settings)
          ..where((row) => row.key.equals(key));
        return query.getSingleOrNull();
      });

  @override
  Future<Result<List<SettingRecord>>> list() =>
      _guard(() => _database.select(_database.settings).get());

  @override
  Future<Result<void>> put(SettingRecord setting) => _guard(() async {
        await _database
            .into(_database.settings)
            .insertOnConflictUpdate(setting);
      });
}

/// Drift implementation of [DownloadRepository].
final class DriftDownloadRepository implements DownloadRepository {
  /// Creates the repository.
  const DriftDownloadRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<DownloadRecord>>> list() =>
      _guard(() => _database.select(_database.downloads).get());

  @override
  Future<Result<void>> put(DownloadRecord download) => _guard(() async {
        if (download.bytesTotal < 0 ||
            download.bytesDone < 0 ||
            download.bytesDone > download.bytesTotal) {
          throw const FormatException('Download byte counts are invalid.');
        }
        await _database
            .into(_database.downloads)
            .insertOnConflictUpdate(download);
      });
}

/// Drift implementation of [RecordingRepository].
final class DriftRecordingRepository implements RecordingRepository {
  /// Creates the repository.
  const DriftRecordingRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<SavedRecordingRecord>>> list() =>
      _guard(() => _database.select(_database.savedRecordings).get());

  @override
  Future<Result<void>> put(SavedRecordingRecord recording) => _guard(() async {
        _validateUuid(recording.id, 'saved_recording.id');
        _validateUuid(recording.sessionId, 'saved_recording.session_id');
        if (recording.path.isEmpty || recording.durationMs < 0) {
          throw const FormatException('Saved recording metadata is invalid.');
        }
        await _database
            .into(_database.savedRecordings)
            .insertOnConflictUpdate(recording);
      });

  @override
  Future<Result<void>> remove(String id) => _guard(() async {
        _validateUuid(id, 'saved_recording.id');
        await (_database.delete(_database.savedRecordings)
              ..where((row) => row.id.equals(id)))
            .go();
      });
}

/// Drift implementation of [UploadQueueRepository].
final class DriftUploadQueueRepository implements UploadQueueRepository {
  /// Creates the repository.
  const DriftUploadQueueRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<UploadQueueRecord>>> list() => _guard(() {
        final query = _database.select(_database.uploadQueueEntries)
          ..orderBy(<OrderingTerm Function(UploadQueueEntries)>[
            (row) => OrderingTerm.asc(row.state),
            (row) => OrderingTerm.desc(row.priority),
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return query.get();
      });

  @override
  Future<Result<void>> put(UploadQueueRecord upload) => _guard(() async {
        _validateUuid(upload.id, 'upload_queue.id');
        _validateUuid(upload.sessionId, 'upload_queue.session_id');
        if (upload.filePath.isEmpty || upload.bytes < 0 || upload.tries < 0) {
          throw const FormatException('Upload queue metadata is invalid.');
        }
        await _database
            .into(_database.uploadQueueEntries)
            .insertOnConflictUpdate(upload);
      });
}

/// Drift implementation of [DailyPlanRepository].
final class DriftDailyPlanRepository implements DailyPlanRepository {
  /// Creates the repository.
  const DriftDailyPlanRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<DailyPlanRecord?>> get(String date) => _guard(() {
        _validateDate(date);
        final query = _database.select(_database.dailyPlans)
          ..where((row) => row.date.equals(date));
        return query.getSingleOrNull();
      });

  @override
  Future<Result<void>> put(DailyPlanRecord plan) => _guard(() async {
        _validateDate(plan.date);
        await _database.into(_database.dailyPlans).insertOnConflictUpdate(plan);
      });
}

/// Drift implementation of [FreeUsageRepository].
final class DriftFreeUsageRepository implements FreeUsageRepository {
  /// Creates the repository.
  const DriftFreeUsageRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<FreeUsageRecord?>> get(String date) => _guard(() {
        _validateDate(date);
        final query = _database.select(_database.freeUsageEntries)
          ..where((row) => row.date.equals(date));
        return query.getSingleOrNull();
      });

  @override
  Future<Result<void>> put(FreeUsageRecord usage) => _guard(() async {
        _validateDate(usage.date);
        if (usage.listeningMs < 0) {
          throw const FormatException('listening_ms must be non-negative.');
        }
        await _database
            .into(_database.freeUsageEntries)
            .insertOnConflictUpdate(usage);
      });
}

/// Drift implementation of [EntitlementRepository].
final class DriftEntitlementRepository implements EntitlementRepository {
  /// Creates the repository.
  const DriftEntitlementRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<EntitlementCacheRecord?>> getPremium() => _guard(() {
        final query = _database.select(_database.entitlementCacheEntries)
          ..where((row) => row.id.equals('premium'));
        return query.getSingleOrNull();
      });

  @override
  Future<Result<void>> put(EntitlementCacheRecord entitlement) =>
      _guard(() async {
        if (entitlement.id != 'premium') {
          throw const FormatException('Entitlement id must be premium.');
        }
        await _database
            .into(_database.entitlementCacheEntries)
            .insertOnConflictUpdate(entitlement);
      });
}

/// Drift implementation of [SearchKeyCacheRepository].
final class DriftSearchKeyCacheRepository implements SearchKeyCacheRepository {
  /// Creates the repository.
  const DriftSearchKeyCacheRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<SearchKeyCacheRecord>>> list(String normalizerId) =>
      _guard(() {
        final query = _database.select(_database.searchKeyCacheEntries)
          ..where((row) => row.normalizerId.equals(normalizerId))
          ..orderBy(<OrderingTerm Function(SearchKeyCacheEntries)>[
            (row) => OrderingTerm.asc(row.wordIndex),
          ]);
        return query.get();
      });

  @override
  Future<Result<void>> replace(
    String normalizerId,
    List<SearchKeyCacheRecord> entries,
  ) =>
      _guard(() async {
        if (normalizerId.isEmpty ||
            entries.any((entry) => entry.normalizerId != normalizerId)) {
          throw const FormatException('Search-key cache ids do not match.');
        }
        await _database.transaction(() async {
          await (_database.delete(_database.searchKeyCacheEntries)
                ..where((row) => row.normalizerId.equals(normalizerId)))
              .go();
          await _database.batch((batch) {
            batch.insertAll(_database.searchKeyCacheEntries, entries);
          });
        });
      });
}

/// Drift implementation of [NgramCacheRepository].
final class DriftNgramCacheRepository implements NgramCacheRepository {
  /// Creates the repository.
  const DriftNgramCacheRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<NgramCacheRecord>>> list(String normalizerId) =>
      _guard(() {
        final query = _database.select(_database.ngramCacheEntries)
          ..where((row) => row.normalizerId.equals(normalizerId))
          ..orderBy(<OrderingTerm Function(NgramCacheEntries)>[
            (row) => OrderingTerm.asc(row.ngram),
          ]);
        return query.get();
      });

  @override
  Future<Result<void>> replace(
    String normalizerId,
    List<NgramCacheRecord> entries,
  ) =>
      _guard(() async {
        if (normalizerId.isEmpty ||
            entries.any((entry) => entry.normalizerId != normalizerId)) {
          throw const FormatException('N-gram cache ids do not match.');
        }
        await _database.transaction(() async {
          await (_database.delete(_database.ngramCacheEntries)
                ..where((row) => row.normalizerId.equals(normalizerId)))
              .go();
          await _database.batch((batch) {
            batch.insertAll(_database.ngramCacheEntries, entries);
          });
        });
      });
}

/// Drift implementation of [OutboxRepository].
final class DriftOutboxRepository implements OutboxRepository {
  /// Creates the repository.
  const DriftOutboxRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<void>> add(OutboxRecord event) => _guard(() async {
        _validateUuid(event.id, 'outbox.id');
        await _database.into(_database.outboxEntries).insert(event);
      });

  @override
  Future<Result<List<OutboxRecord>>> list() => _guard(() {
        final query = _database.select(_database.outboxEntries)
          ..orderBy(<OrderingTerm Function(OutboxEntries)>[
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return query.get();
      });
}

Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
  try {
    return Result<T>.ok(await operation());
  } on Exception catch (error) {
    return Result<T>.error(error);
  } on Object catch (_) {
    return Result<T>.error(const StorageException('unexpectedFailure'));
  }
}

void _validateUuid(String value, String field) {
  if (!_uuidV4.hasMatch(value)) {
    throw FormatException('$field must be a UUID v4.');
  }
}

void _validateDate(String value) {
  if (!_localDate.hasMatch(value) || DateTime.tryParse(value) == null) {
    throw FormatException('$value is not a YYYY-MM-DD date.');
  }
}

void _validateRange(int from, int to, String field) {
  if (from < 0 || to < from) {
    throw FormatException('$field word range is invalid.');
  }
}

void _validateUnit(UnitRecord unit) {
  _validateUuid(unit.id, 'unit.id');
  _validateUuid(unit.profileId, 'unit.profile_id');
  if (unit.parentUnitId case final parent?) {
    _validateUuid(parent, 'unit.parent_unit_id');
  }
  if (unit.kind == UnitKind.skill) {
    if (unit.skillId == null ||
        unit.fromWordIndex != null ||
        unit.toWordIndex != null) {
      throw const FormatException('A skill unit must contain only skill_id.');
    }
    return;
  }
  final from = unit.fromWordIndex;
  final to = unit.toWordIndex;
  if (from == null || to == null || unit.skillId != null) {
    throw const FormatException('A reading unit must contain a word range.');
  }
  _validateRange(from, to, 'unit');
}

void _validateAttempt(AttemptRecord attempt) {
  _validateUuid(attempt.id, 'attempt.id');
  _validateUuid(attempt.unitId, 'attempt.unit_id');
  _validateUuid(attempt.sessionId, 'attempt.session_id');
  if (attempt.durationMs < 0 || attempt.words < 0) {
    throw const FormatException('Attempt counters must be non-negative.');
  }
}

void _validateCheckEvent(CheckEventRecord event) {
  _validateUuid(event.id, 'check_event.id');
  _validateUuid(event.sessionId, 'check_event.session_id');
  if (event.audioStartMs < 0 || event.audioEndMs < event.audioStartMs) {
    throw const FormatException('Check-event audio range is invalid.');
  }
}
