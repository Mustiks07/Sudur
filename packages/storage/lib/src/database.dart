// Drift table declarations are internal schema metadata.
// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:storage/src/json_types.dart';

part 'database.g.dart';

/// Every user table in schema version 1.
const schemaV1TableNames = <String>[
  'profile',
  'unit',
  'unit_state',
  'attempt',
  'check_event',
  'session',
  'daily_plan',
  'lesson_progress',
  'setting',
  'download',
  'search_key_cache',
  'ngram_cache',
  'saved_recording',
  'upload_queue',
  'entitlement_cache',
  'free_usage',
  'outbox',
];

/// Supported interface languages.
enum UiLanguage { ru, kk, uz }

/// User learning path.
enum LearningPath { read, hifz, restore }

/// Error feedback behavior.
enum ReadingBehavior { gentle, strict }

/// Kind of a plan unit.
enum UnitKind { passage, junction, hardSpot, skill }

/// How a plan unit was created.
enum UnitOrigin { defaultOrigin, knownBefore, error, lesson }

/// Persists [UnitOrigin] using the exact values from spec 12.1.
final class UnitOriginConverter extends TypeConverter<UnitOrigin, String> {
  /// Creates the converter.
  const UnitOriginConverter();

  @override
  UnitOrigin fromSql(String fromDb) => switch (fromDb) {
        'default' => UnitOrigin.defaultOrigin,
        'knownBefore' => UnitOrigin.knownBefore,
        'error' => UnitOrigin.error,
        'lesson' => UnitOrigin.lesson,
        _ => throw FormatException('Unknown unit origin: $fromDb.'),
      };

  @override
  String toSql(UnitOrigin value) => switch (value) {
        UnitOrigin.defaultOrigin => 'default',
        UnitOrigin.knownBefore => 'knownBefore',
        UnitOrigin.error => 'error',
        UnitOrigin.lesson => 'lesson',
      };
}

/// Scheduling queue for a unit.
enum UnitQueue { notStarted, learning, recent, old, closed }

/// How a unit was last checked.
enum CheckMethod { voice, self, listener }

/// Reading mode stored with attempts and sessions.
enum StoredReadingMode { supported, recall, test, self }

/// Attempt outcome.
enum AttemptOutcome {
  clean,
  withHints,
  corrected,
  withErrors,
  unverified,
  disputed,
}

/// FSRS rating supplied after an attempt.
enum AttemptRating { again, hard, good, easy }

/// Lesson progress state (docs/tz section 11.2).
enum LessonState { locked, available, inProgress, quiz, passed, failed }

/// Downloadable package kind.
enum DownloadKind {
  text,
  layout,
  font,
  audio,
  model,
  lessons,
  translation,
  config,
}

/// Persisted download lifecycle state (docs/tz section 11.4).
///
/// `notInstalled` and `updateAvailable` are derived from installed versions
/// and the current manifest, so they are intentionally not stored.
enum DownloadState {
  queued,
  downloading,
  verifying,
  installing,
  installed,
  failed,
}

/// Recording upload lifecycle state.
enum UploadState { queued, uploading, uploaded, failed }

/// Cached entitlement state.
enum EntitlementState { free, trial, active, grace, expiredOffline, expired }

@DataClassName('ProfileRecord')
class Profiles extends Table {
  @override
  String get tableName => 'profile';

  TextColumn get id => text().withLength(min: 36, max: 36)();

  IntColumn get createdAt => integer()();

  TextColumn get uiLanguage => textEnum<UiLanguage>()();

  TextColumn get path => textEnum<LearningPath>()();

  IntColumn get dailyMinutes => integer()();

  TextColumn get behavior => textEnum<ReadingBehavior>()();

  BoolColumn get showFirstWord => boolean()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('UnitRecord')
@TableIndex(name: 'unit_profile_kind', columns: <Object>{#profileId, #kind})
class Units extends Table {
  @override
  String get tableName => 'unit';

  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get profileId => text().withLength(min: 36, max: 36)();

  TextColumn get kind => textEnum<UnitKind>()();

  IntColumn get fromWordIndex => integer().nullable()();

  IntColumn get toWordIndex => integer().nullable()();

  TextColumn get skillId => text().nullable()();

  IntColumn get surah => integer().nullable()();

  TextColumn get origin => text().map(const UnitOriginConverter())();

  TextColumn get parentUnitId => text().nullable()();

  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('UnitStateRecord')
@TableIndex(name: 'unit_state_due_at', columns: <Object>{#dueAt})
class UnitStates extends Table {
  @override
  String get tableName => 'unit_state';

  TextColumn get unitId => text().withLength(min: 36, max: 36)();

  TextColumn get queue => textEnum<UnitQueue>()();

  TextColumn get memoryState =>
      text().map(const JsonObjectConverter()).nullable()();

  TextColumn get fsrsCard =>
      text().map(const JsonObjectConverter()).nullable()();

  IntColumn get dueAt => integer().nullable()();

  IntColumn get recentSince => integer().nullable()();

  IntColumn get lastAttemptAt => integer().nullable()();

  TextColumn get lastMethod => textEnum<CheckMethod>().nullable()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{unitId};
}

@DataClassName('AttemptRecord')
@TableIndex(
  name: 'attempt_unit_created',
  columns: <Object>{#unitId, #createdAt},
)
class Attempts extends Table {
  @override
  String get tableName => 'attempt';

  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get unitId => text().withLength(min: 36, max: 36)();

  TextColumn get sessionId => text().withLength(min: 36, max: 36)();

  TextColumn get mode => textEnum<StoredReadingMode>()();

  TextColumn get outcome => textEnum<AttemptOutcome>()();

  TextColumn get hints => text().map(const HintCountsConverter())();

  TextColumn get errorEventIds => text().map(const ErrorEventIdsConverter())();

  TextColumn get rating => textEnum<AttemptRating>().nullable()();

  TextColumn get method => textEnum<CheckMethod>()();

  IntColumn get durationMs => integer()();

  IntColumn get words => integer()();

  TextColumn get modelId => text()();

  TextColumn get modelVersion => text()();

  TextColumn get rulesVersion => text()();

  TextColumn get textVersion => text()();

  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('CheckEventRecord')
@TableIndex(name: 'check_event_session', columns: <Object>{#sessionId})
class CheckEvents extends Table {
  @override
  String get tableName => 'check_event';

  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get sessionId => text().withLength(min: 36, max: 36)();

  TextColumn get kind => textEnum<CheckKind>()();

  TextColumn get state => textEnum<CheckState>()();

  TextColumn get wordIndexes => text().map(const WordIndexesConverter())();

  TextColumn get expectedText => text()();

  TextColumn get heardText => text()();

  IntColumn get jumpFromWordIndex => integer().nullable()();

  IntColumn get jumpToWordIndex => integer().nullable()();

  IntColumn get audioStartMs => integer()();

  IntColumn get audioEndMs => integer()();

  TextColumn get versions => text().map(const ReadingVersionsConverter())();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('SessionRecord')
class Sessions extends Table {
  @override
  String get tableName => 'session';

  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get profileId => text().withLength(min: 36, max: 36)();

  IntColumn get fromWordIndex => integer()();

  IntColumn get toWordIndex => integer()();

  TextColumn get mode => textEnum<StoredReadingMode>()();

  TextColumn get behavior => textEnum<ReadingBehavior>()();

  IntColumn get startedAt => integer()();

  IntColumn get endedAt => integer().nullable()();

  IntColumn get listeningMs => integer()();

  RealColumn get signalOkRatio => real().nullable()();

  TextColumn get summary =>
      text().map(const SessionSummaryConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('DailyPlanRecord')
class DailyPlans extends Table {
  @override
  String get tableName => 'daily_plan';

  TextColumn get date => text().withLength(min: 10, max: 10)();

  TextColumn get items => text().map(const DailyPlanItemsConverter())();

  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{date};
}

@DataClassName('LessonProgressRecord')
class LessonProgressEntries extends Table {
  @override
  String get tableName => 'lesson_progress';

  TextColumn get lessonId => text()();

  TextColumn get state => textEnum<LessonState>()();

  IntColumn get stepIndex => integer()();

  IntColumn get quizPercent => integer()();

  TextColumn get contentVersion => text()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{lessonId};
}

@DataClassName('SettingRecord')
class Settings extends Table {
  @override
  String get tableName => 'setting';

  TextColumn get key => text()();

  TextColumn get value => text().map(const JsonValueConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

@DataClassName('DownloadRecord')
class Downloads extends Table {
  @override
  String get tableName => 'download';

  TextColumn get packageId => text()();

  TextColumn get kind => textEnum<DownloadKind>()();

  TextColumn get activeVersion => text().nullable()();

  TextColumn get pendingVersion => text().nullable()();

  TextColumn get state => textEnum<DownloadState>()();

  IntColumn get bytesTotal => integer()();

  IntColumn get bytesDone => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{packageId};
}

@DataClassName('SearchKeyCacheRecord')
class SearchKeyCacheEntries extends Table {
  @override
  String get tableName => 'search_key_cache';

  TextColumn get normalizerId => text()();

  IntColumn get wordIndex => integer()();

  TextColumn get key => text()();

  @override
  Set<Column<Object>> get primaryKey =>
      <Column<Object>>{normalizerId, wordIndex};
}

@DataClassName('NgramCacheRecord')
class NgramCacheEntries extends Table {
  @override
  String get tableName => 'ngram_cache';

  TextColumn get normalizerId => text()();

  TextColumn get ngram => text()();

  TextColumn get wordIndexes => text().map(const WordIndexesConverter())();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{normalizerId, ngram};
}

@DataClassName('SavedRecordingRecord')
class SavedRecordings extends Table {
  @override
  String get tableName => 'saved_recording';

  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get sessionId => text().withLength(min: 36, max: 36)();

  TextColumn get path => text()();

  IntColumn get durationMs => integer()();

  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('UploadQueueRecord')
@TableIndex(
  name: 'upload_queue_state_priority',
  columns: <Object>{#state, #priority},
)
class UploadQueueEntries extends Table {
  @override
  String get tableName => 'upload_queue';

  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get sessionId => text().withLength(min: 36, max: 36)();

  TextColumn get filePath => text()();

  TextColumn get meta => text().map(const UploadMetadataConverter())();

  IntColumn get priority => integer()();

  IntColumn get bytes => integer()();

  TextColumn get state => textEnum<UploadState>()();

  IntColumn get tries => integer()();

  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('EntitlementCacheRecord')
class EntitlementCacheEntries extends Table {
  @override
  String get tableName => 'entitlement_cache';

  TextColumn get id => text()();

  TextColumn get state => textEnum<EntitlementState>()();

  IntColumn get expiresAt => integer().nullable()();

  IntColumn get lastVerifiedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('FreeUsageRecord')
class FreeUsageEntries extends Table {
  @override
  String get tableName => 'free_usage';

  TextColumn get date => text().withLength(min: 10, max: 10)();

  IntColumn get listeningMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{date};
}

@DataClassName('OutboxRecord')
class OutboxEntries extends Table {
  @override
  String get tableName => 'outbox';

  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get event => text().map(const JsonObjectConverter())();

  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// User database with schema version 1.
@DriftDatabase(
  tables: <Type>[
    Profiles,
    Units,
    UnitStates,
    Attempts,
    CheckEvents,
    Sessions,
    DailyPlans,
    LessonProgressEntries,
    Settings,
    Downloads,
    SearchKeyCacheEntries,
    NgramCacheEntries,
    SavedRecordings,
    UploadQueueEntries,
    EntitlementCacheEntries,
    FreeUsageEntries,
    OutboxEntries,
  ],
)
final class SudurDatabase extends _$SudurDatabase {
  /// Creates a database from a drift executor.
  SudurDatabase(super.e);

  /// Opens a file-backed database on drift's background isolate.
  factory SudurDatabase.openFile(String path) {
    return SudurDatabase(NativeDatabase.createInBackground(File(path)));
  }

  /// Opens an in-memory database for tests.
  factory SudurDatabase.memory() => SudurDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) => migrator.createAll(),
        onUpgrade: (migrator, from, to) async {
          if (from == 1) {
            await customStatement(
              "UPDATE download SET state = 'queued' WHERE state = 'pending'",
            );
          }
        },
      );
}
