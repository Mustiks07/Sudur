import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

import 'helpers.dart';

const _tableNames = <String>[
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

void main() {
  late StorageService storage;

  setUp(() {
    storage = StorageService.memory();
  });

  tearDown(() => storage.close());

  test('export, erase and import restores user data from every table file',
      () async {
    await _seedEveryRepository(storage);
    final exported = unwrap(await storage.exportData());
    final archive = ZipDecoder().decodeBytes(exported, verify: true);
    expect(
      archive.map((entry) => entry.name).toSet(),
      <String>{
        'manifest.json',
        for (final table in _tableNames) '$table.json',
      },
    );

    final fileSystem = _FakeRecordingFileSystem();
    unwrap(await storage.eraseAll(fileSystem));
    expect(fileSystem.deleted, <String>['/private/saved.opus']);
    await _expectEveryRepositoryEmpty(storage);

    unwrap(await storage.importData(exported));

    await _expectEveryRepositoryHasOne(storage);
    expect(
      unwrap(await storage.settings.get('language'))?.value.value,
      'ru',
    );
    expect(
      unwrap(await storage.recordings.list()).single.path,
      '/private/saved.opus',
    );
  });

  test('unsupported archive version changes no data', () async {
    unwrap(await storage.profiles.put(profile()));
    final bytes = unwrap(await storage.exportData());
    final archive = ZipDecoder().decodeBytes(bytes)
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode(<String, Object?>{
            'format': 'sudur-user-data',
            'schemaVersion': 3,
          }),
        ),
      );

    final result = await storage.importData(ZipEncoder().encodeBytes(archive));

    expect(result, isA<Error<void>>());
    expect(unwrap(await storage.profiles.list()), hasLength(1));
  });

  test('zip-slip archive entry is rejected', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('../manifest.json', '{}'));

    final result = await storage.importData(ZipEncoder().encodeBytes(archive));

    expect(result, isA<Error<void>>());
    await _expectEveryRepositoryEmpty(storage);
  });

  test('invalid JSON field leaves existing database untouched', () async {
    unwrap(await storage.profiles.put(profile()));
    final archive = ZipDecoder().decodeBytes(unwrap(await storage.exportData()))
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

    final result = await storage.importData(ZipEncoder().encodeBytes(archive));

    expect(result, isA<Error<void>>());
    expect(unwrap(await storage.profiles.list()), hasLength(1));
  });

  test('malformed zip is returned as Result.error', () async {
    final result = await storage.importData(
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

Future<void> _seedEveryRepository(StorageService storage) async {
  unwrap(await storage.profiles.put(profile()));
  unwrap(await storage.units.putUnit(unit()));
  unwrap(await storage.units.putState(unitState()));
  unwrap(await storage.sessions.put(session()));
  unwrap(await storage.attempts.add(attempt()));
  unwrap(await storage.checkEvents.put(checkEvent()));
  unwrap(
    await storage.dailyPlans.put(
      (
        date: '2026-11-17',
        items: DailyPlanItems.fromJson(const <Object?>[]),
        createdAt: 1000,
      ),
    ),
  );
  unwrap(
    await storage.lessons.put(
      const (
        lessonId: 'lesson-1',
        state: LessonState.passed,
        stepIndex: 3,
        quizPercent: 100,
        contentVersion: '1',
        updatedAt: 2000,
      ),
    ),
  );
  unwrap(
    await storage.settings.put(
      (
        key: 'language',
        value: JsonValueData.fromJson('ru'),
      ),
    ),
  );
  unwrap(
    await storage.downloads.put(
      const (
        packageId: 'model-1',
        kind: DownloadKind.model,
        activeVersion: '1',
        pendingVersion: null,
        state: DownloadState.installed,
        bytesTotal: 100,
        bytesDone: 100,
        updatedAt: 2000,
      ),
    ),
  );
  unwrap(
    await storage.searchKeys.replace('normalizer-1', const <SearchKeyCacheData>[
      (normalizerId: 'normalizer-1', wordIndex: 10, key: 'key'),
    ]),
  );
  unwrap(
    await storage.ngrams.replace('normalizer-1', <NgramCacheData>[
      (
        normalizerId: 'normalizer-1',
        ngram: 'key',
        wordIndexes: WordIndexes.fromJson(const <Object?>[10]),
      ),
    ]),
  );
  unwrap(
    await storage.recordings.put(
      const (
        id: recordingId,
        sessionId: sessionId,
        path: '/private/saved.opus',
        durationMs: 100,
        createdAt: 2000,
      ),
    ),
  );
  unwrap(
    await storage.uploads.put(
      (
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
    ),
  );
  unwrap(
    await storage.entitlements.put(
      const (
        id: 'premium',
        state: EntitlementState.active,
        expiresAt: 3000,
        lastVerifiedAt: 2000,
      ),
    ),
  );
  unwrap(
    await storage.freeUsage.put(
      const (
        date: '2026-11-17',
        listeningMs: 900,
      ),
    ),
  );
  unwrap(
    await storage.outbox.add(
      (
        id: outboxId,
        event: JsonObjectData.fromJson(
          const <String, Object?>{'kind': 'attempt'},
        ),
        createdAt: 2000,
      ),
    ),
  );
}

Future<void> _expectEveryRepositoryEmpty(StorageService storage) async {
  expect(unwrap(await storage.profiles.list()), isEmpty);
  expect(unwrap(await storage.units.listForProfile(profileId)), isEmpty);
  expect(unwrap(await storage.units.getState(unitId)), isNull);
  expect(unwrap(await storage.attempts.listForUnit(unitId)), isEmpty);
  expect(unwrap(await storage.checkEvents.listForSession(sessionId)), isEmpty);
  expect(unwrap(await storage.sessions.listForProfile(profileId)), isEmpty);
  expect(unwrap(await storage.dailyPlans.get('2026-11-17')), isNull);
  expect(unwrap(await storage.lessons.list()), isEmpty);
  expect(unwrap(await storage.settings.list()), isEmpty);
  expect(unwrap(await storage.downloads.list()), isEmpty);
  expect(unwrap(await storage.searchKeys.list('normalizer-1')), isEmpty);
  expect(unwrap(await storage.ngrams.list('normalizer-1')), isEmpty);
  expect(unwrap(await storage.recordings.list()), isEmpty);
  expect(unwrap(await storage.uploads.list()), isEmpty);
  expect(unwrap(await storage.entitlements.getPremium()), isNull);
  expect(unwrap(await storage.freeUsage.get('2026-11-17')), isNull);
  expect(unwrap(await storage.outbox.list()), isEmpty);
}

Future<void> _expectEveryRepositoryHasOne(StorageService storage) async {
  expect(unwrap(await storage.profiles.list()), hasLength(1));
  expect(unwrap(await storage.units.listForProfile(profileId)), hasLength(1));
  expect(unwrap(await storage.units.getState(unitId)), isNotNull);
  expect(unwrap(await storage.attempts.listForUnit(unitId)), hasLength(1));
  expect(
    unwrap(await storage.checkEvents.listForSession(sessionId)),
    hasLength(1),
  );
  expect(
    unwrap(await storage.sessions.listForProfile(profileId)),
    hasLength(1),
  );
  expect(unwrap(await storage.dailyPlans.get('2026-11-17')), isNotNull);
  expect(unwrap(await storage.lessons.list()), hasLength(1));
  expect(unwrap(await storage.settings.list()), hasLength(1));
  expect(unwrap(await storage.downloads.list()), hasLength(1));
  expect(unwrap(await storage.searchKeys.list('normalizer-1')), hasLength(1));
  expect(unwrap(await storage.ngrams.list('normalizer-1')), hasLength(1));
  expect(unwrap(await storage.recordings.list()), hasLength(1));
  expect(unwrap(await storage.uploads.list()), hasLength(1));
  expect(unwrap(await storage.entitlements.getPremium()), isNotNull);
  expect(unwrap(await storage.freeUsage.get('2026-11-17')), isNotNull);
  expect(unwrap(await storage.outbox.list()), hasLength(1));
}
