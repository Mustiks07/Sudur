import 'package:contracts/contracts.dart';
import 'package:drift/drift.dart';
import 'package:storage/src/database.dart';
import 'package:storage/src/models.dart';
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
  final AttemptData attempt;

  /// Check events produced by the attempt.
  final List<CheckEventData> checkEvents;

  /// New scheduling state for the attempted unit.
  final UnitStateData unitState;
}

/// Profile persistence.
abstract interface class ProfileRepository {
  /// Inserts or replaces the V1 profile.
  Future<Result<void>> put(ProfileData profile);

  /// Returns all profiles (one in V1).
  Future<Result<List<ProfileData>>> list();
}

/// Plan-unit and unit-state persistence.
abstract interface class UnitRepository {
  /// Inserts or replaces a unit.
  Future<Result<void>> putUnit(UnitData unit);

  /// Inserts or replaces unit state.
  Future<Result<void>> putState(UnitStateData state);

  /// Returns units for [profileId].
  Future<Result<List<UnitData>>> listForProfile(String profileId);

  /// Returns state for [unitId], if present.
  Future<Result<UnitStateData?>> getState(String unitId);
}

/// Attempt persistence and the НФ-21 atomic passage write.
abstract interface class AttemptRepository {
  /// Inserts one attempt.
  Future<Result<void>> add(AttemptData attempt);

  /// Returns attempts for [unitId] in chronological order.
  Future<Result<List<AttemptData>>> listForUnit(String unitId);

  /// Writes an attempt, its events and new unit state atomically.
  Future<Result<void>> recordPassage(PassageWrite write);
}

/// Check-event persistence.
abstract interface class CheckEventRepository {
  /// Inserts or replaces a check event.
  Future<Result<void>> put(CheckEventData event);

  /// Returns events for [sessionId] in creation order.
  Future<Result<List<CheckEventData>>> listForSession(String sessionId);

  /// Returns the event [id], if present.
  Future<Result<CheckEventData?>> get(String id);
}

/// Reading-session persistence.
abstract interface class SessionRepository {
  /// Inserts or replaces a session.
  Future<Result<void>> put(SessionData session);

  /// Returns sessions for [profileId] in start order.
  Future<Result<List<SessionData>>> listForProfile(String profileId);
}

/// Lesson progress persistence.
abstract interface class LessonRepository {
  /// Inserts or replaces lesson progress.
  Future<Result<void>> put(LessonProgressData progress);

  /// Returns all lesson progress rows.
  Future<Result<List<LessonProgressData>>> list();
}

/// Settings persistence.
abstract interface class SettingsRepository {
  /// Inserts or replaces a setting.
  Future<Result<void>> put(SettingData setting);

  /// Returns a setting by [key], if present.
  Future<Result<SettingData?>> get(String key);

  /// Returns all settings.
  Future<Result<List<SettingData>>> list();
}

/// Installed-package persistence.
abstract interface class DownloadRepository {
  /// Inserts or replaces package state.
  Future<Result<void>> put(DownloadData download);

  /// Returns all package states.
  Future<Result<List<DownloadData>>> list();

  /// Forgets [packageId] after its files were deleted: “not installed” is
  /// not stored (docs/tz 11.4), it is the absence of a row.
  Future<Result<void>> remove(String packageId);
}

/// Explicitly saved recording metadata persistence.
abstract interface class RecordingRepository {
  /// Inserts or replaces saved recording metadata.
  Future<Result<void>> put(SavedRecordingData recording);

  /// Returns all saved recording metadata.
  Future<Result<List<SavedRecordingData>>> list();

  /// Removes metadata for [id].
  Future<Result<void>> remove(String id);
}

/// Consented recording-upload queue persistence.
abstract interface class UploadQueueRepository {
  /// Inserts or replaces an upload item.
  Future<Result<void>> put(UploadQueueData upload);

  /// Returns upload items ordered by state, priority and creation time.
  Future<Result<List<UploadQueueData>>> list();
}

/// Stable daily-plan persistence.
abstract interface class DailyPlanRepository {
  /// Inserts or replaces a day plan.
  Future<Result<void>> put(DailyPlanData plan);

  /// Returns the plan for [date], if present.
  Future<Result<DailyPlanData?>> get(String date);
}

/// Free voice-usage persistence.
abstract interface class FreeUsageRepository {
  /// Inserts or replaces daily usage.
  Future<Result<void>> put(FreeUsageData usage);

  /// Returns usage for [date], if present.
  Future<Result<FreeUsageData?>> get(String date);
}

/// Cached entitlement persistence.
abstract interface class EntitlementRepository {
  /// Inserts or replaces entitlement state.
  Future<Result<void>> put(EntitlementCacheData entitlement);

  /// Returns the premium entitlement, if cached.
  Future<Result<EntitlementCacheData?>> getPremium();
}

/// Search-key cache persistence.
abstract interface class SearchKeyCacheRepository {
  /// Replaces all keys for [normalizerId].
  Future<Result<void>> replace(
    String normalizerId,
    List<SearchKeyCacheData> entries,
  );

  /// Returns all keys for [normalizerId].
  Future<Result<List<SearchKeyCacheData>>> list(String normalizerId);
}

/// N-gram cache persistence.
abstract interface class NgramCacheRepository {
  /// Replaces all n-grams for [normalizerId].
  Future<Result<void>> replace(
    String normalizerId,
    List<NgramCacheData> entries,
  );

  /// Returns all n-grams for [normalizerId].
  Future<Result<List<NgramCacheData>>> list(String normalizerId);
}

/// Future sync-outbox persistence. The table starts empty in schema v1.
abstract interface class OutboxRepository {
  /// Adds an event to the outbox.
  Future<Result<void>> add(OutboxData event);

  /// Returns queued events in creation order.
  Future<Result<List<OutboxData>>> list();
}

/// Drift implementation of [ProfileRepository].
final class DriftProfileRepository implements ProfileRepository {
  /// Creates the repository.
  const DriftProfileRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<void>> put(ProfileData profile) => _guard(() async {
        _validateUuid(profile.id, 'profile.id');
        await _database
            .into(_database.profiles)
            .insertOnConflictUpdate(_profileRow(profile));
      });

  @override
  Future<Result<List<ProfileData>>> list() => _guard(
        () => _mappedList(
          _database.select(_database.profiles).get(),
          _profileData,
        ),
      );
}

/// Drift implementation of [UnitRepository].
final class DriftUnitRepository implements UnitRepository {
  /// Creates the repository.
  const DriftUnitRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<UnitStateData?>> getState(String unitId) => _guard(() {
        _validateUuid(unitId, 'unitId');
        final query = _database.select(_database.unitStates)
          ..where((row) => row.unitId.equals(unitId));
        return _mappedNullable(query.getSingleOrNull(), _unitStateData);
      });

  @override
  Future<Result<List<UnitData>>> listForProfile(String profileId) => _guard(() {
        _validateUuid(profileId, 'profileId');
        final query = _database.select(_database.units)
          ..where((row) => row.profileId.equals(profileId))
          ..orderBy(<OrderingTerm Function(Units)>[
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return _mappedList(query.get(), _unitData);
      });

  @override
  Future<Result<void>> putState(UnitStateData state) => _guard(() async {
        _validateUuid(state.unitId, 'unit_state.unit_id');
        await _database
            .into(_database.unitStates)
            .insertOnConflictUpdate(_unitStateRow(state));
      });

  @override
  Future<Result<void>> putUnit(UnitData unit) => _guard(() async {
        _validateUnit(unit);
        await _database
            .into(_database.units)
            .insertOnConflictUpdate(_unitRow(unit));
      });
}

/// Drift implementation of [AttemptRepository].
final class DriftAttemptRepository implements AttemptRepository {
  /// Creates the repository.
  const DriftAttemptRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<void>> add(AttemptData attempt) => _guard(() async {
        _validateAttempt(attempt);
        await _database.into(_database.attempts).insert(_attemptRow(attempt));
      });

  @override
  Future<Result<List<AttemptData>>> listForUnit(String unitId) => _guard(() {
        _validateUuid(unitId, 'unitId');
        final query = _database.select(_database.attempts)
          ..where((row) => row.unitId.equals(unitId))
          ..orderBy(<OrderingTerm Function(Attempts)>[
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return _mappedList(query.get(), _attemptData);
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
          await _database
              .into(_database.attempts)
              .insert(_attemptRow(write.attempt));
          for (final event in write.checkEvents) {
            await _database
                .into(_database.checkEvents)
                .insert(_checkEventRow(event));
          }
          await _database
              .into(_database.unitStates)
              .insertOnConflictUpdate(_unitStateRow(write.unitState));
        });
      });
}

/// Drift implementation of [CheckEventRepository].
final class DriftCheckEventRepository implements CheckEventRepository {
  /// Creates the repository.
  const DriftCheckEventRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<CheckEventData>>> listForSession(String sessionId) =>
      _guard(() {
        _validateUuid(sessionId, 'sessionId');
        final query = _database.select(_database.checkEvents)
          ..where((row) => row.sessionId.equals(sessionId))
          ..orderBy(<OrderingTerm Function(CheckEvents)>[
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return _mappedList(query.get(), _checkEventData);
      });

  @override
  Future<Result<CheckEventData?>> get(String id) => _guard(() async {
        _validateUuid(id, 'check_event.id');
        final row = await (_database.select(_database.checkEvents)
              ..where((row) => row.id.equals(id)))
            .getSingleOrNull();
        return row == null ? null : _checkEventData(row);
      });

  @override
  Future<Result<void>> put(CheckEventData event) => _guard(() async {
        _validateCheckEvent(event);
        await _database
            .into(_database.checkEvents)
            .insertOnConflictUpdate(_checkEventRow(event));
      });
}

/// Drift implementation of [SessionRepository].
final class DriftSessionRepository implements SessionRepository {
  /// Creates the repository.
  const DriftSessionRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<SessionData>>> listForProfile(String profileId) =>
      _guard(() {
        _validateUuid(profileId, 'profileId');
        final query = _database.select(_database.sessions)
          ..where((row) => row.profileId.equals(profileId))
          ..orderBy(<OrderingTerm Function(Sessions)>[
            (row) => OrderingTerm.asc(row.startedAt),
          ]);
        return _mappedList(query.get(), _sessionData);
      });

  @override
  Future<Result<void>> put(SessionData session) => _guard(() async {
        _validateUuid(session.id, 'session.id');
        _validateUuid(session.profileId, 'session.profile_id');
        _validateRange(session.fromWordIndex, session.toWordIndex, 'session');
        if (session.signalOkRatio case final ratio?
            when ratio < 0 || ratio > 1) {
          throw const FormatException('signal_ok_ratio must be from 0 to 1.');
        }
        await _database
            .into(_database.sessions)
            .insertOnConflictUpdate(_sessionRow(session));
      });
}

/// Drift implementation of [LessonRepository].
final class DriftLessonRepository implements LessonRepository {
  /// Creates the repository.
  const DriftLessonRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<LessonProgressData>>> list() => _guard(
        () => _mappedList(
          _database.select(_database.lessonProgressEntries).get(),
          _lessonProgressData,
        ),
      );

  @override
  Future<Result<void>> put(LessonProgressData progress) => _guard(() async {
        if (progress.quizPercent < 0 || progress.quizPercent > 100) {
          throw const FormatException('quiz_percent must be from 0 to 100.');
        }
        await _database
            .into(_database.lessonProgressEntries)
            .insertOnConflictUpdate(_lessonProgressRow(progress));
      });
}

/// Drift implementation of [SettingsRepository].
final class DriftSettingsRepository implements SettingsRepository {
  /// Creates the repository.
  const DriftSettingsRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<SettingData?>> get(String key) => _guard(() {
        final query = _database.select(_database.settings)
          ..where((row) => row.key.equals(key));
        return _mappedNullable(query.getSingleOrNull(), _settingData);
      });

  @override
  Future<Result<List<SettingData>>> list() => _guard(
        () => _mappedList(
          _database.select(_database.settings).get(),
          _settingData,
        ),
      );

  @override
  Future<Result<void>> put(SettingData setting) => _guard(() async {
        await _database
            .into(_database.settings)
            .insertOnConflictUpdate(_settingRow(setting));
      });
}

/// Drift implementation of [DownloadRepository].
final class DriftDownloadRepository implements DownloadRepository {
  /// Creates the repository.
  const DriftDownloadRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<DownloadData>>> list() => _guard(
        () => _mappedList(
          _database.select(_database.downloads).get(),
          _downloadData,
        ),
      );

  @override
  Future<Result<void>> put(DownloadData download) => _guard(() async {
        if (download.bytesTotal < 0 ||
            download.bytesDone < 0 ||
            download.bytesDone > download.bytesTotal) {
          throw const FormatException('Download byte counts are invalid.');
        }
        await _database
            .into(_database.downloads)
            .insertOnConflictUpdate(_downloadRow(download));
      });

  @override
  Future<Result<void>> remove(String packageId) => _guard(() async {
        await (_database.delete(_database.downloads)
              ..where((row) => row.packageId.equals(packageId)))
            .go();
      });
}

/// Drift implementation of [RecordingRepository].
final class DriftRecordingRepository implements RecordingRepository {
  /// Creates the repository.
  const DriftRecordingRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<SavedRecordingData>>> list() => _guard(
        () => _mappedList(
          _database.select(_database.savedRecordings).get(),
          _savedRecordingData,
        ),
      );

  @override
  Future<Result<void>> put(SavedRecordingData recording) => _guard(() async {
        _validateUuid(recording.id, 'saved_recording.id');
        _validateUuid(recording.sessionId, 'saved_recording.session_id');
        if (recording.path.isEmpty || recording.durationMs < 0) {
          throw const FormatException('Saved recording metadata is invalid.');
        }
        await _database
            .into(_database.savedRecordings)
            .insertOnConflictUpdate(_savedRecordingRow(recording));
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
  Future<Result<List<UploadQueueData>>> list() => _guard(() {
        final query = _database.select(_database.uploadQueueEntries)
          ..orderBy(<OrderingTerm Function(UploadQueueEntries)>[
            (row) => OrderingTerm.asc(row.state),
            (row) => OrderingTerm.desc(row.priority),
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return _mappedList(query.get(), _uploadQueueData);
      });

  @override
  Future<Result<void>> put(UploadQueueData upload) => _guard(() async {
        _validateUuid(upload.id, 'upload_queue.id');
        _validateUuid(upload.sessionId, 'upload_queue.session_id');
        if (upload.filePath.isEmpty || upload.bytes < 0 || upload.tries < 0) {
          throw const FormatException('Upload queue metadata is invalid.');
        }
        await _database
            .into(_database.uploadQueueEntries)
            .insertOnConflictUpdate(_uploadQueueRow(upload));
      });
}

/// Drift implementation of [DailyPlanRepository].
final class DriftDailyPlanRepository implements DailyPlanRepository {
  /// Creates the repository.
  const DriftDailyPlanRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<DailyPlanData?>> get(String date) => _guard(() {
        _validateDate(date);
        final query = _database.select(_database.dailyPlans)
          ..where((row) => row.date.equals(date));
        return _mappedNullable(query.getSingleOrNull(), _dailyPlanData);
      });

  @override
  Future<Result<void>> put(DailyPlanData plan) => _guard(() async {
        _validateDate(plan.date);
        await _database
            .into(_database.dailyPlans)
            .insertOnConflictUpdate(_dailyPlanRow(plan));
      });
}

/// Drift implementation of [FreeUsageRepository].
final class DriftFreeUsageRepository implements FreeUsageRepository {
  /// Creates the repository.
  const DriftFreeUsageRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<FreeUsageData?>> get(String date) => _guard(() {
        _validateDate(date);
        final query = _database.select(_database.freeUsageEntries)
          ..where((row) => row.date.equals(date));
        return _mappedNullable(query.getSingleOrNull(), _freeUsageData);
      });

  @override
  Future<Result<void>> put(FreeUsageData usage) => _guard(() async {
        _validateDate(usage.date);
        if (usage.listeningMs < 0) {
          throw const FormatException('listening_ms must be non-negative.');
        }
        await _database
            .into(_database.freeUsageEntries)
            .insertOnConflictUpdate(_freeUsageRow(usage));
      });
}

/// Drift implementation of [EntitlementRepository].
final class DriftEntitlementRepository implements EntitlementRepository {
  /// Creates the repository.
  const DriftEntitlementRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<EntitlementCacheData?>> getPremium() => _guard(() {
        final query = _database.select(_database.entitlementCacheEntries)
          ..where((row) => row.id.equals('premium'));
        return _mappedNullable(query.getSingleOrNull(), _entitlementData);
      });

  @override
  Future<Result<void>> put(EntitlementCacheData entitlement) =>
      _guard(() async {
        if (entitlement.id != 'premium') {
          throw const FormatException('Entitlement id must be premium.');
        }
        await _database
            .into(_database.entitlementCacheEntries)
            .insertOnConflictUpdate(_entitlementRow(entitlement));
      });
}

/// Drift implementation of [SearchKeyCacheRepository].
final class DriftSearchKeyCacheRepository implements SearchKeyCacheRepository {
  /// Creates the repository.
  const DriftSearchKeyCacheRepository(this._database);

  final SudurDatabase _database;

  @override
  Future<Result<List<SearchKeyCacheData>>> list(String normalizerId) =>
      _guard(() {
        final query = _database.select(_database.searchKeyCacheEntries)
          ..where((row) => row.normalizerId.equals(normalizerId))
          ..orderBy(<OrderingTerm Function(SearchKeyCacheEntries)>[
            (row) => OrderingTerm.asc(row.wordIndex),
          ]);
        return _mappedList(query.get(), _searchKeyData);
      });

  @override
  Future<Result<void>> replace(
    String normalizerId,
    List<SearchKeyCacheData> entries,
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
            batch.insertAll(
              _database.searchKeyCacheEntries,
              entries.map(_searchKeyRow),
            );
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
  Future<Result<List<NgramCacheData>>> list(String normalizerId) => _guard(() {
        final query = _database.select(_database.ngramCacheEntries)
          ..where((row) => row.normalizerId.equals(normalizerId))
          ..orderBy(<OrderingTerm Function(NgramCacheEntries)>[
            (row) => OrderingTerm.asc(row.ngram),
          ]);
        return _mappedList(query.get(), _ngramData);
      });

  @override
  Future<Result<void>> replace(
    String normalizerId,
    List<NgramCacheData> entries,
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
            batch.insertAll(
              _database.ngramCacheEntries,
              entries.map(_ngramRow),
            );
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
  Future<Result<void>> add(OutboxData event) => _guard(() async {
        _validateUuid(event.id, 'outbox.id');
        await _database.into(_database.outboxEntries).insert(_outboxRow(event));
      });

  @override
  Future<Result<List<OutboxData>>> list() => _guard(() {
        final query = _database.select(_database.outboxEntries)
          ..orderBy(<OrderingTerm Function(OutboxEntries)>[
            (row) => OrderingTerm.asc(row.createdAt),
          ]);
        return _mappedList(query.get(), _outboxData);
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

Future<List<R>> _mappedList<T, R>(
  Future<List<T>> rows,
  R Function(T) mapper,
) async =>
    (await rows).map(mapper).toList(growable: false);

Future<R?> _mappedNullable<T, R>(
  Future<T?> row,
  R Function(T) mapper,
) async {
  final value = await row;
  return value == null ? null : mapper(value);
}

ProfileRecord _profileRow(ProfileData value) => ProfileRecord(
      id: value.id,
      createdAt: value.createdAt,
      uiLanguage: value.uiLanguage,
      path: value.path,
      dailyMinutes: value.dailyMinutes,
      behavior: value.behavior,
      showFirstWord: value.showFirstWord,
    );

ProfileData _profileData(ProfileRecord value) => (
      id: value.id,
      createdAt: value.createdAt,
      uiLanguage: value.uiLanguage,
      path: value.path,
      dailyMinutes: value.dailyMinutes,
      behavior: value.behavior,
      showFirstWord: value.showFirstWord,
    );

UnitRecord _unitRow(UnitData value) => UnitRecord(
      id: value.id,
      profileId: value.profileId,
      kind: value.kind,
      fromWordIndex: value.fromWordIndex,
      toWordIndex: value.toWordIndex,
      skillId: value.skillId,
      surah: value.surah,
      origin: value.origin,
      parentUnitId: value.parentUnitId,
      createdAt: value.createdAt,
    );

UnitData _unitData(UnitRecord value) => (
      id: value.id,
      profileId: value.profileId,
      kind: value.kind,
      fromWordIndex: value.fromWordIndex,
      toWordIndex: value.toWordIndex,
      skillId: value.skillId,
      surah: value.surah,
      origin: value.origin,
      parentUnitId: value.parentUnitId,
      createdAt: value.createdAt,
    );

UnitStateRecord _unitStateRow(UnitStateData value) => UnitStateRecord(
      unitId: value.unitId,
      queue: value.queue,
      memoryState: value.memoryState,
      fsrsCard: value.fsrsCard,
      dueAt: value.dueAt,
      recentSince: value.recentSince,
      lastAttemptAt: value.lastAttemptAt,
      lastMethod: value.lastMethod,
      updatedAt: value.updatedAt,
    );

UnitStateData _unitStateData(UnitStateRecord value) => (
      unitId: value.unitId,
      queue: value.queue,
      memoryState: value.memoryState,
      fsrsCard: value.fsrsCard,
      dueAt: value.dueAt,
      recentSince: value.recentSince,
      lastAttemptAt: value.lastAttemptAt,
      lastMethod: value.lastMethod,
      updatedAt: value.updatedAt,
    );

AttemptRecord _attemptRow(AttemptData value) => AttemptRecord(
      id: value.id,
      unitId: value.unitId,
      sessionId: value.sessionId,
      mode: value.mode,
      outcome: value.outcome,
      hints: value.hints,
      errorEventIds: value.errorEventIds,
      rating: value.rating,
      method: value.method,
      durationMs: value.durationMs,
      words: value.words,
      modelId: value.modelId,
      modelVersion: value.modelVersion,
      rulesVersion: value.rulesVersion,
      textVersion: value.textVersion,
      createdAt: value.createdAt,
    );

AttemptData _attemptData(AttemptRecord value) => (
      id: value.id,
      unitId: value.unitId,
      sessionId: value.sessionId,
      mode: value.mode,
      outcome: value.outcome,
      hints: value.hints,
      errorEventIds: value.errorEventIds,
      rating: value.rating,
      method: value.method,
      durationMs: value.durationMs,
      words: value.words,
      modelId: value.modelId,
      modelVersion: value.modelVersion,
      rulesVersion: value.rulesVersion,
      textVersion: value.textVersion,
      createdAt: value.createdAt,
    );

CheckEventRecord _checkEventRow(CheckEventData value) => CheckEventRecord(
      id: value.id,
      sessionId: value.sessionId,
      kind: value.kind,
      state: value.state,
      wordIndexes: value.wordIndexes,
      expectedText: value.expectedText,
      heardText: value.heardText,
      jumpFromWordIndex: value.jumpFromWordIndex,
      jumpToWordIndex: value.jumpToWordIndex,
      audioStartMs: value.audioStartMs,
      audioEndMs: value.audioEndMs,
      versions: value.versions,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );

CheckEventData _checkEventData(CheckEventRecord value) => (
      id: value.id,
      sessionId: value.sessionId,
      kind: value.kind,
      state: value.state,
      wordIndexes: value.wordIndexes,
      expectedText: value.expectedText,
      heardText: value.heardText,
      jumpFromWordIndex: value.jumpFromWordIndex,
      jumpToWordIndex: value.jumpToWordIndex,
      audioStartMs: value.audioStartMs,
      audioEndMs: value.audioEndMs,
      versions: value.versions,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );

SessionRecord _sessionRow(SessionData value) => SessionRecord(
      id: value.id,
      profileId: value.profileId,
      fromWordIndex: value.fromWordIndex,
      toWordIndex: value.toWordIndex,
      mode: value.mode,
      behavior: value.behavior,
      startedAt: value.startedAt,
      endedAt: value.endedAt,
      listeningMs: value.listeningMs,
      signalOkRatio: value.signalOkRatio,
      summary: value.summary,
    );

SessionData _sessionData(SessionRecord value) => (
      id: value.id,
      profileId: value.profileId,
      fromWordIndex: value.fromWordIndex,
      toWordIndex: value.toWordIndex,
      mode: value.mode,
      behavior: value.behavior,
      startedAt: value.startedAt,
      endedAt: value.endedAt,
      listeningMs: value.listeningMs,
      signalOkRatio: value.signalOkRatio,
      summary: value.summary,
    );

LessonProgressRecord _lessonProgressRow(LessonProgressData value) =>
    LessonProgressRecord(
      lessonId: value.lessonId,
      state: value.state,
      stepIndex: value.stepIndex,
      quizPercent: value.quizPercent,
      contentVersion: value.contentVersion,
      updatedAt: value.updatedAt,
    );

LessonProgressData _lessonProgressData(LessonProgressRecord value) => (
      lessonId: value.lessonId,
      state: value.state,
      stepIndex: value.stepIndex,
      quizPercent: value.quizPercent,
      contentVersion: value.contentVersion,
      updatedAt: value.updatedAt,
    );

SettingRecord _settingRow(SettingData value) =>
    SettingRecord(key: value.key, value: value.value);

SettingData _settingData(SettingRecord value) =>
    (key: value.key, value: value.value);

DownloadRecord _downloadRow(DownloadData value) => DownloadRecord(
      packageId: value.packageId,
      kind: value.kind,
      activeVersion: value.activeVersion,
      pendingVersion: value.pendingVersion,
      state: value.state,
      bytesTotal: value.bytesTotal,
      bytesDone: value.bytesDone,
      updatedAt: value.updatedAt,
    );

DownloadData _downloadData(DownloadRecord value) => (
      packageId: value.packageId,
      kind: value.kind,
      activeVersion: value.activeVersion,
      pendingVersion: value.pendingVersion,
      state: value.state,
      bytesTotal: value.bytesTotal,
      bytesDone: value.bytesDone,
      updatedAt: value.updatedAt,
    );

SavedRecordingRecord _savedRecordingRow(SavedRecordingData value) =>
    SavedRecordingRecord(
      id: value.id,
      sessionId: value.sessionId,
      path: value.path,
      durationMs: value.durationMs,
      createdAt: value.createdAt,
    );

SavedRecordingData _savedRecordingData(SavedRecordingRecord value) => (
      id: value.id,
      sessionId: value.sessionId,
      path: value.path,
      durationMs: value.durationMs,
      createdAt: value.createdAt,
    );

UploadQueueRecord _uploadQueueRow(UploadQueueData value) => UploadQueueRecord(
      id: value.id,
      sessionId: value.sessionId,
      filePath: value.filePath,
      meta: value.meta,
      priority: value.priority,
      bytes: value.bytes,
      state: value.state,
      tries: value.tries,
      createdAt: value.createdAt,
    );

UploadQueueData _uploadQueueData(UploadQueueRecord value) => (
      id: value.id,
      sessionId: value.sessionId,
      filePath: value.filePath,
      meta: value.meta,
      priority: value.priority,
      bytes: value.bytes,
      state: value.state,
      tries: value.tries,
      createdAt: value.createdAt,
    );

DailyPlanRecord _dailyPlanRow(DailyPlanData value) => DailyPlanRecord(
      date: value.date,
      items: value.items,
      createdAt: value.createdAt,
    );

DailyPlanData _dailyPlanData(DailyPlanRecord value) => (
      date: value.date,
      items: value.items,
      createdAt: value.createdAt,
    );

FreeUsageRecord _freeUsageRow(FreeUsageData value) => FreeUsageRecord(
      date: value.date,
      listeningMs: value.listeningMs,
    );

FreeUsageData _freeUsageData(FreeUsageRecord value) => (
      date: value.date,
      listeningMs: value.listeningMs,
    );

EntitlementCacheRecord _entitlementRow(EntitlementCacheData value) =>
    EntitlementCacheRecord(
      id: value.id,
      state: value.state,
      expiresAt: value.expiresAt,
      lastVerifiedAt: value.lastVerifiedAt,
    );

EntitlementCacheData _entitlementData(EntitlementCacheRecord value) => (
      id: value.id,
      state: value.state,
      expiresAt: value.expiresAt,
      lastVerifiedAt: value.lastVerifiedAt,
    );

SearchKeyCacheRecord _searchKeyRow(SearchKeyCacheData value) =>
    SearchKeyCacheRecord(
      normalizerId: value.normalizerId,
      wordIndex: value.wordIndex,
      key: value.key,
    );

SearchKeyCacheData _searchKeyData(SearchKeyCacheRecord value) => (
      normalizerId: value.normalizerId,
      wordIndex: value.wordIndex,
      key: value.key,
    );

NgramCacheRecord _ngramRow(NgramCacheData value) => NgramCacheRecord(
      normalizerId: value.normalizerId,
      ngram: value.ngram,
      wordIndexes: value.wordIndexes,
    );

NgramCacheData _ngramData(NgramCacheRecord value) => (
      normalizerId: value.normalizerId,
      ngram: value.ngram,
      wordIndexes: value.wordIndexes,
    );

OutboxRecord _outboxRow(OutboxData value) => OutboxRecord(
      id: value.id,
      event: value.event,
      createdAt: value.createdAt,
    );

OutboxData _outboxData(OutboxRecord value) => (
      id: value.id,
      event: value.event,
      createdAt: value.createdAt,
    );

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

void _validateUnit(UnitData unit) {
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

void _validateAttempt(AttemptData attempt) {
  _validateUuid(attempt.id, 'attempt.id');
  _validateUuid(attempt.unitId, 'attempt.unit_id');
  _validateUuid(attempt.sessionId, 'attempt.session_id');
  if (attempt.durationMs < 0 || attempt.words < 0) {
    throw const FormatException('Attempt counters must be non-negative.');
  }
}

void _validateCheckEvent(CheckEventData event) {
  _validateUuid(event.id, 'check_event.id');
  _validateUuid(event.sessionId, 'check_event.session_id');
  if (event.audioStartMs < 0 || event.audioEndMs < event.audioStartMs) {
    throw const FormatException('Check-event audio range is invalid.');
  }
}
