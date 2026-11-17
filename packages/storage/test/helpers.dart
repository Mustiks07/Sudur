import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

const profileId = '00000000-0000-4000-8000-000000000001';
const unitId = '00000000-0000-4000-8000-000000000002';
const sessionId = '00000000-0000-4000-8000-000000000003';
const attemptId = '00000000-0000-4000-8000-000000000004';
const eventId = '00000000-0000-4000-8000-000000000005';
const recordingId = '00000000-0000-4000-8000-000000000006';
const uploadId = '00000000-0000-4000-8000-000000000007';
const outboxId = '00000000-0000-4000-8000-000000000008';

const versions = ReadingVersions(
  modelId: 'model',
  modelVersion: '1',
  rulesVersion: '1',
  textVersion: '1',
);

ProfileRecord profile() => const ProfileRecord(
      id: profileId,
      createdAt: 1000,
      uiLanguage: UiLanguage.ru,
      path: LearningPath.read,
      dailyMinutes: 10,
      behavior: ReadingBehavior.gentle,
      showFirstWord: true,
    );

UnitRecord unit() => const UnitRecord(
      id: unitId,
      profileId: profileId,
      kind: UnitKind.passage,
      fromWordIndex: 10,
      toWordIndex: 20,
      origin: UnitOrigin.defaultOrigin,
      createdAt: 1000,
    );

UnitStateRecord unitState() => const UnitStateRecord(
      unitId: unitId,
      queue: UnitQueue.learning,
      updatedAt: 2000,
    );

SessionRecord session() => SessionRecord(
      id: sessionId,
      profileId: profileId,
      fromWordIndex: 10,
      toWordIndex: 20,
      mode: StoredReadingMode.recall,
      behavior: ReadingBehavior.gentle,
      startedAt: 1000,
      endedAt: 2000,
      listeningMs: 900,
      signalOkRatio: 0.95,
      summary: SessionSummary.fromJson(
        const <String, Object?>{'attempts': 1},
      ),
    );

AttemptRecord attempt() => AttemptRecord(
      id: attemptId,
      unitId: unitId,
      sessionId: sessionId,
      mode: StoredReadingMode.recall,
      outcome: AttemptOutcome.clean,
      hints: HintCounts.fromJson(
        const <String, Object?>{'firstWord': 1},
      ),
      errorEventIds: ErrorEventIds.fromJson(const <Object?>[eventId]),
      rating: AttemptRating.good,
      method: CheckMethod.voice,
      durationMs: 900,
      words: 11,
      modelId: versions.modelId,
      modelVersion: versions.modelVersion,
      rulesVersion: versions.rulesVersion,
      textVersion: versions.textVersion,
      createdAt: 2000,
    );

CheckEventRecord checkEvent() => CheckEventRecord(
      id: eventId,
      sessionId: sessionId,
      kind: CheckKind.repetition,
      state: CheckState.corrected,
      wordIndexes: WordIndexes.fromJson(const <Object?>[12]),
      expectedText: 'expected',
      heardText: 'heard',
      audioStartMs: 100,
      audioEndMs: 200,
      versions: versions,
      createdAt: 1500,
      updatedAt: 1600,
    );

UploadMetadata uploadMetadata() => UploadMetadata.fromJson(
      const <String, Object?>{
        'schema': 1,
        'installId': '00000000-0000-4000-8000-000000000009',
        'consentVersion': '2026-12',
        'recordedAt': '2026-12-05T18:20:00Z',
        'range': <String, Object?>{'from': '78:1:1', 'to': '78:5:4'},
        'mode': 'recall',
        'device': <String, Object?>{'model': 'device', 'os': 'os'},
        'versions': <String, Object?>{
          'app': '1',
          'model': 'model@1',
          'rules': '1',
          'text': '1',
        },
        'asr': <Object?>[
          <String, Object?>{
            'segmentId': 1,
            'isFinal': true,
            'text': 'heard',
            'startMs': 0,
            'endMs': 100,
          },
        ],
        'events': <Object?>[
          <String, Object?>{
            'kind': 'repetition',
            'state': 'corrected',
            'wordKey': '78:1:1',
            'heard': 'heard',
          },
        ],
        'audio': <String, Object?>{
          'codec': 'opus',
          'bitrateKbps': 16,
          'durationMs': 100,
          'sha256': 'hash',
        },
      },
    );

T unwrap<T>(Result<T> result) => switch (result) {
      Ok<T>(:final value) => value,
      Error<T>(:final error) => throw TestFailure('Unexpected error: $error'),
    };
