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

  test('all repositories persist and read their schema-v1 entities', () async {
    final profiles = DriftProfileRepository(database);
    final units = DriftUnitRepository(database);
    final attempts = DriftAttemptRepository(database);
    final events = DriftCheckEventRepository(database);
    final sessions = DriftSessionRepository(database);
    final lessons = DriftLessonRepository(database);
    final settings = DriftSettingsRepository(database);
    final downloads = DriftDownloadRepository(database);
    final recordings = DriftRecordingRepository(database);
    final uploads = DriftUploadQueueRepository(database);
    final plans = DriftDailyPlanRepository(database);
    final usage = DriftFreeUsageRepository(database);
    final entitlements = DriftEntitlementRepository(database);
    final searchKeys = DriftSearchKeyCacheRepository(database);
    final ngrams = DriftNgramCacheRepository(database);
    final outbox = DriftOutboxRepository(database);

    expect(unwrap(await outbox.list()), isEmpty);

    unwrap(await profiles.put(profile()));
    unwrap(await units.putUnit(unit()));
    unwrap(await units.putState(unitState()));
    unwrap(await sessions.put(session()));
    unwrap(await attempts.add(attempt()));
    unwrap(await events.put(checkEvent()));
    unwrap(
      await lessons.put(
        const LessonProgressRecord(
          lessonId: 'lesson-1',
          state: LessonState.inProgress,
          stepIndex: 2,
          quizPercent: 80,
          contentVersion: '1',
          updatedAt: 2000,
        ),
      ),
    );
    unwrap(
      await settings.put(
        SettingRecord(
          key: 'notifications',
          value: JsonValueData.fromJson(true),
        ),
      ),
    );
    unwrap(
      await downloads.put(
        const DownloadRecord(
          packageId: 'model-1',
          kind: DownloadKind.model,
          activeVersion: '1',
          state: DownloadState.installed,
          bytesTotal: 100,
          bytesDone: 100,
          updatedAt: 2000,
        ),
      ),
    );
    unwrap(
      await recordings.put(
        const SavedRecordingRecord(
          id: recordingId,
          sessionId: sessionId,
          path: '/private/recording.opus',
          durationMs: 100,
          createdAt: 2000,
        ),
      ),
    );
    unwrap(
      await uploads.put(
        UploadQueueRecord(
          id: uploadId,
          sessionId: sessionId,
          filePath: '/private/upload.opus',
          meta: uploadMetadata(),
          priority: 10,
          bytes: 100,
          state: UploadState.queued,
          tries: 0,
          createdAt: 2000,
        ),
      ),
    );
    unwrap(
      await plans.put(
        DailyPlanRecord(
          date: '2026-11-17',
          items: DailyPlanItems.fromJson(const <Object?>[
            <String, Object?>{'unitId': unitId},
          ]),
          createdAt: 1000,
        ),
      ),
    );
    unwrap(
      await usage.put(
        const FreeUsageRecord(date: '2026-11-17', listeningMs: 900),
      ),
    );
    unwrap(
      await entitlements.put(
        const EntitlementCacheRecord(
          id: 'premium',
          state: EntitlementState.active,
          expiresAt: 3000,
          lastVerifiedAt: 2000,
        ),
      ),
    );
    unwrap(
      await searchKeys.replace('normalizer-1', const <SearchKeyCacheRecord>[
        SearchKeyCacheRecord(
          normalizerId: 'normalizer-1',
          wordIndex: 10,
          key: 'key',
        ),
      ]),
    );
    unwrap(
      await ngrams.replace('normalizer-1', <NgramCacheRecord>[
        NgramCacheRecord(
          normalizerId: 'normalizer-1',
          ngram: 'key',
          wordIndexes: WordIndexes.fromJson(const <Object?>[10]),
        ),
      ]),
    );
    unwrap(
      await outbox.add(
        OutboxRecord(
          id: outboxId,
          event: JsonObjectData.fromJson(
            const <String, Object?>{'kind': 'attempt'},
          ),
          createdAt: 2000,
        ),
      ),
    );

    expect(unwrap(await profiles.list()), hasLength(1));
    expect(unwrap(await units.listForProfile(profileId)), hasLength(1));
    expect(unwrap(await units.getState(unitId)), unitState());
    expect(unwrap(await attempts.listForUnit(unitId)), hasLength(1));
    expect(unwrap(await events.listForSession(sessionId)), hasLength(1));
    expect(unwrap(await sessions.listForProfile(profileId)), hasLength(1));
    expect(unwrap(await lessons.list()), hasLength(1));
    expect(unwrap(await settings.get('notifications'))?.value.value, isTrue);
    expect(unwrap(await settings.list()), hasLength(1));
    expect(unwrap(await downloads.list()), hasLength(1));
    expect(unwrap(await recordings.list()), hasLength(1));
    expect(unwrap(await uploads.list()), hasLength(1));
    expect(unwrap(await plans.get('2026-11-17'))?.items.data.value, isNotEmpty);
    expect(unwrap(await usage.get('2026-11-17'))?.listeningMs, 900);
    expect(
      unwrap(await entitlements.getPremium())?.state,
      EntitlementState.active,
    );
    expect(unwrap(await searchKeys.list('normalizer-1')), hasLength(1));
    expect(unwrap(await ngrams.list('normalizer-1')), hasLength(1));
    expect(unwrap(await outbox.list()), hasLength(1));

    unwrap(await recordings.remove(recordingId));
    expect(unwrap(await recordings.list()), isEmpty);
  });

  test('passage write rolls back every row when an event insert fails',
      () async {
    final attempts = DriftAttemptRepository(database);
    final events = DriftCheckEventRepository(database);
    final units = DriftUnitRepository(database);
    unwrap(await events.put(checkEvent()));

    final result = await attempts.recordPassage(
      PassageWrite(
        attempt: attempt(),
        checkEvents: <CheckEventRecord>[checkEvent()],
        unitState: unitState(),
      ),
    );

    expect(result, isA<Error<void>>());
    expect(unwrap(await attempts.listForUnit(unitId)), isEmpty);
    expect(unwrap(await units.getState(unitId)), isNull);
    expect(unwrap(await events.listForSession(sessionId)), hasLength(1));
  });

  test('invalid identifiers are returned as Result.error', () async {
    final result = await DriftProfileRepository(database).put(
      profile().copyWith(id: 'not-a-uuid'),
    );

    expect(result, isA<Error<void>>());
  });
}
