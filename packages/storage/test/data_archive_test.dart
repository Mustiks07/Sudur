import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

import 'helpers.dart';

void main() {
  late SudurDatabase database;

  setUp(() {
    database = SudurDatabase.memory();
  });

  tearDown(() => database.close());

  test('export, erase and import restores user data from every table file',
      () async {
    unwrap(await DriftProfileRepository(database).put(profile()));
    unwrap(
      await DriftSettingsRepository(database).put(
        SettingRecord(
          key: 'language',
          value: JsonValueData.fromJson('ru'),
        ),
      ),
    );
    unwrap(
      await DriftRecordingRepository(database).put(
        const SavedRecordingRecord(
          id: recordingId,
          sessionId: sessionId,
          path: '/private/saved.opus',
          durationMs: 100,
          createdAt: 2000,
        ),
      ),
    );
    await database.into(database.units).insert(unit());
    await database.into(database.unitStates).insert(unitState());
    await database.into(database.sessions).insert(session());
    await database.into(database.attempts).insert(attempt());
    await database.into(database.checkEvents).insert(checkEvent());
    await database.into(database.dailyPlans).insert(
          DailyPlanRecord(
            date: '2026-11-17',
            items: DailyPlanItems.fromJson(const <Object?>[]),
            createdAt: 1000,
          ),
        );
    await database.into(database.lessonProgressEntries).insert(
          const LessonProgressRecord(
            lessonId: 'lesson-1',
            state: LessonState.completed,
            stepIndex: 3,
            quizPercent: 100,
            contentVersion: '1',
            updatedAt: 2000,
          ),
        );
    await database.into(database.downloads).insert(
          const DownloadRecord(
            packageId: 'model-1',
            kind: DownloadKind.model,
            activeVersion: '1',
            state: DownloadState.installed,
            bytesTotal: 100,
            bytesDone: 100,
            updatedAt: 2000,
          ),
        );
    await database.into(database.searchKeyCacheEntries).insert(
          const SearchKeyCacheRecord(
            normalizerId: 'normalizer-1',
            wordIndex: 10,
            key: 'key',
          ),
        );
    await database.into(database.ngramCacheEntries).insert(
          NgramCacheRecord(
            normalizerId: 'normalizer-1',
            ngram: 'key',
            wordIndexes: WordIndexes.fromJson(const <Object?>[10]),
          ),
        );
    await database.into(database.uploadQueueEntries).insert(
          UploadQueueRecord(
            id: uploadId,
            sessionId: sessionId,
            filePath: '/private/upload.opus',
            meta: uploadMetadata(),
            priority: 1,
            bytes: 100,
            state: UploadState.queued,
            tries: 0,
            createdAt: 2000,
          ),
        );
    await database.into(database.entitlementCacheEntries).insert(
          const EntitlementCacheRecord(
            id: 'premium',
            state: EntitlementState.active,
            expiresAt: 3000,
            lastVerifiedAt: 2000,
          ),
        );
    await database.into(database.freeUsageEntries).insert(
          const FreeUsageRecord(
            date: '2026-11-17',
            listeningMs: 900,
          ),
        );
    await database.into(database.outboxEntries).insert(
          OutboxRecord(
            id: outboxId,
            event: JsonObjectData.fromJson(
              const <String, Object?>{'kind': 'attempt'},
            ),
            createdAt: 2000,
          ),
        );

    final archiveService = UserDataArchiveService(database);
    final exported = unwrap(await archiveService.exportData());
    final archive = ZipDecoder().decodeBytes(exported, verify: true);
    expect(
      archive.map((entry) => entry.name).toSet(),
      <String>{
        'manifest.json',
        for (final table in schemaV1TableNames) '$table.json',
      },
    );

    final fileSystem = _FakeRecordingFileSystem();
    unwrap(await UserDataEraser(database, fileSystem).eraseAll());
    expect(fileSystem.deleted, <String>['/private/saved.opus']);
    await _expectAllTablesEmpty(database);

    unwrap(await archiveService.importData(exported));

    await _expectEveryTableHasOne(database);
    expect(unwrap(await DriftProfileRepository(database).list()), hasLength(1));
    expect(
      unwrap(await DriftSettingsRepository(database).get('language'))
          ?.value
          .value,
      'ru',
    );
    expect(
      unwrap(await DriftRecordingRepository(database).list()).single.path,
      '/private/saved.opus',
    );
  });

  test('unsupported archive version changes no data', () async {
    unwrap(await DriftProfileRepository(database).put(profile()));
    final service = UserDataArchiveService(database);
    final bytes = unwrap(await service.exportData());
    final archive = ZipDecoder().decodeBytes(bytes)
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode(<String, Object?>{
            'format': 'sudur-user-data',
            'schemaVersion': 2,
          }),
        ),
      );

    final result = await service.importData(ZipEncoder().encodeBytes(archive));

    expect(result, isA<Error<void>>());
    expect(unwrap(await DriftProfileRepository(database).list()), hasLength(1));
  });

  test('zip-slip archive entry is rejected', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('../manifest.json', '{}'));

    final result = await UserDataArchiveService(database).importData(
      ZipEncoder().encodeBytes(archive),
    );

    expect(result, isA<Error<void>>());
    await _expectAllTablesEmpty(database);
  });

  test('invalid JSON field leaves existing database untouched', () async {
    unwrap(await DriftProfileRepository(database).put(profile()));
    final service = UserDataArchiveService(database);
    final archive = ZipDecoder().decodeBytes(unwrap(await service.exportData()))
      ..addFile(
        ArchiveFile.string(
          'profile.json',
          jsonEncode(<Object?>[
            <String, Object?>{
              'id': profileId,
              'created_at': 'not-an-int',
              'ui_language': 'ru',
              'path': 'read',
              'daily_minutes': 10,
              'behavior': 'gentle',
              'show_first_word': true,
            },
          ]),
        ),
      );

    final result = await service.importData(ZipEncoder().encodeBytes(archive));

    expect(result, isA<Error<void>>());
    expect(unwrap(await DriftProfileRepository(database).list()), hasLength(1));
  });

  test('malformed zip is returned as Result.error', () async {
    final result = await UserDataArchiveService(database).importData(
      Uint8List.fromList(<int>[1, 2, 3]),
    );

    expect(result, isA<Error<void>>());
  });
}

final class _FakeRecordingFileSystem implements RecordingFileSystem {
  final deleted = <String>[];

  @override
  Future<void> deleteRecording(String path) async {
    deleted.add(path);
  }
}

Future<void> _expectAllTablesEmpty(SudurDatabase database) async {
  for (final table in schemaV1TableNames) {
    final row = await database
        .customSelect('SELECT COUNT(*) AS count FROM "$table"')
        .getSingle();
    expect(row.read<int>('count'), 0, reason: table);
  }
}

Future<void> _expectEveryTableHasOne(SudurDatabase database) async {
  for (final table in schemaV1TableNames) {
    final row = await database
        .customSelect('SELECT COUNT(*) AS count FROM "$table"')
        .getSingle();
    expect(row.read<int>('count'), 1, reason: table);
  }
}
