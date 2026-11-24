import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

import 'helpers.dart';

void main() {
  late StorageService storage;

  setUp(() {
    storage = StorageService.memory();
  });

  tearDown(() => storage.close());

  test('lesson repository round-trips every state from spec 11.2', () async {
    for (final (index, state) in LessonState.values.indexed) {
      unwrap(
        await storage.lessons.put(
          (
            lessonId: 'lesson-$index',
            state: state,
            stepIndex: index,
            quizPercent: index * 10,
            contentVersion: '1',
            updatedAt: 1000 + index,
          ),
        ),
      );
    }

    final saved = unwrap(await storage.lessons.list());
    expect(saved.map((progress) => progress.state).toSet(), LessonState.values);
  });

  test('all repositories persist and read their schema-v1 entities', () async {
    final profiles = storage.profiles;
    final units = storage.units;
    final attempts = storage.attempts;
    final events = storage.checkEvents;
    final sessions = storage.sessions;
    final lessons = storage.lessons;
    final settings = storage.settings;
    final downloads = storage.downloads;
    final recordings = storage.recordings;
    final uploads = storage.uploads;
    final plans = storage.dailyPlans;
    final usage = storage.freeUsage;
    final entitlements = storage.entitlements;
    final searchKeys = storage.searchKeys;
    final ngrams = storage.ngrams;
    final outbox = storage.outbox;

    expect(unwrap(await outbox.list()), isEmpty);

    unwrap(await profiles.put(profile()));
    unwrap(await units.putUnit(unit()));
    unwrap(await units.putState(unitState()));
    unwrap(await sessions.put(session()));
    unwrap(await attempts.add(attempt()));
    unwrap(await events.put(checkEvent()));
    unwrap(
      await lessons.put(
        const (
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
        (
          key: 'notifications',
          value: JsonValueData.fromJson(true),
        ),
      ),
    );
    unwrap(
      await downloads.put(
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
      await recordings.put(
        const (
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
        (
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
        (
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
        const (date: '2026-11-17', listeningMs: 900),
      ),
    );
    unwrap(
      await entitlements.put(
        const (
          id: 'premium',
          state: EntitlementState.active,
          expiresAt: 3000,
          lastVerifiedAt: 2000,
        ),
      ),
    );
    unwrap(
      await searchKeys.replace('normalizer-1', const <SearchKeyCacheData>[
        (
          normalizerId: 'normalizer-1',
          wordIndex: 10,
          key: 'key',
        ),
      ]),
    );
    unwrap(
      await ngrams.replace('normalizer-1', <NgramCacheData>[
        (
          normalizerId: 'normalizer-1',
          ngram: 'key',
          wordIndexes: WordIndexes.fromJson(const <Object?>[10]),
        ),
      ]),
    );
    unwrap(
      await outbox.add(
        (
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
    final attempts = storage.attempts;
    final events = storage.checkEvents;
    final units = storage.units;
    unwrap(await events.put(checkEvent()));

    final result = await attempts.recordPassage(
      PassageWrite(
        attempt: attempt(),
        checkEvents: <CheckEventData>[checkEvent()],
        unitState: unitState(),
      ),
    );

    expect(result, isA<Error<void>>());
    expect(unwrap(await attempts.listForUnit(unitId)), isEmpty);
    expect(unwrap(await units.getState(unitId)), isNull);
    expect(unwrap(await events.listForSession(sessionId)), hasLength(1));
  });

  test('a removed download is not listed', () async {
    unwrap(
      await storage.downloads.put(
        const (
          packageId: 'model-1',
          kind: DownloadKind.model,
          activeVersion: '1',
          pendingVersion: null,
          state: DownloadState.installed,
          bytesTotal: 1,
          bytesDone: 1,
          updatedAt: 1,
        ),
      ),
    );
    unwrap(await storage.downloads.remove('model-1'));
    unwrap(await storage.downloads.remove('never-installed'));
    expect(unwrap(await storage.downloads.list()), isEmpty);
  });

  test('transaction keeps writes of every repository together or not at all',
      () async {
    final failed = await storage.transaction(() async {
      unwrap(await storage.profiles.put(profile()));
      unwrap(await storage.units.putUnit(unit()));
      throw const StorageException('stop');
    });
    expect(failed, isA<Error<Object?>>());
    expect(unwrap(await storage.profiles.list()), isEmpty);

    final done = await storage.transaction(() async {
      unwrap(await storage.profiles.put(profile()));
      unwrap(await storage.units.putUnit(unit()));
      return 2;
    });
    expect(unwrap(done), 2);
    expect(unwrap(await storage.profiles.list()), hasLength(1));
    expect(unwrap(await storage.units.listForProfile(profileId)), hasLength(1));
  });

  test('invalid identifiers are returned as Result.error', () async {
    final valid = profile();
    final result = await storage.profiles.put(
      (
        id: 'not-a-uuid',
        createdAt: valid.createdAt,
        uiLanguage: valid.uiLanguage,
        path: valid.path,
        dailyMinutes: valid.dailyMinutes,
        behavior: valid.behavior,
        showFirstWord: valid.showFirstWord,
      ),
    );

    expect(result, isA<Error<void>>());
  });
}
