import 'package:contracts/contracts.dart';
import 'package:storage/src/database.dart';
import 'package:storage/src/json_types.dart';

/// Immutable profile storage model.
typedef ProfileData = ({
  String id,
  int createdAt,
  UiLanguage uiLanguage,
  LearningPath path,
  int dailyMinutes,
  ReadingBehavior behavior,
  bool showFirstWord,
});

/// Immutable plan-unit storage model.
typedef UnitData = ({
  String id,
  String profileId,
  UnitKind kind,
  int? fromWordIndex,
  int? toWordIndex,
  String? skillId,
  int? surah,
  UnitOrigin origin,
  String? parentUnitId,
  int createdAt,
});

/// Immutable unit-state storage model.
typedef UnitStateData = ({
  String unitId,
  UnitQueue queue,
  JsonObjectData? memoryState,
  JsonObjectData? fsrsCard,
  int? dueAt,
  int? recentSince,
  int? lastAttemptAt,
  CheckMethod? lastMethod,
  int updatedAt,
});

/// Immutable attempt storage model.
typedef AttemptData = ({
  String id,
  String unitId,
  String sessionId,
  StoredReadingMode mode,
  AttemptOutcome outcome,
  HintCounts hints,
  ErrorEventIds errorEventIds,
  AttemptRating? rating,
  CheckMethod method,
  int durationMs,
  int words,
  String modelId,
  String modelVersion,
  String rulesVersion,
  String textVersion,
  int createdAt,
});

/// Immutable check-event storage model.
typedef CheckEventData = ({
  String id,
  String sessionId,
  CheckKind kind,
  CheckState state,
  WordIndexes wordIndexes,
  String expectedText,
  String heardText,
  int? jumpFromWordIndex,
  int? jumpToWordIndex,
  int audioStartMs,
  int audioEndMs,
  ReadingVersions versions,
  int createdAt,
  int updatedAt,
});

/// Immutable reading-session storage model.
typedef SessionData = ({
  String id,
  String profileId,
  int fromWordIndex,
  int toWordIndex,
  StoredReadingMode mode,
  ReadingBehavior behavior,
  int startedAt,
  int? endedAt,
  int listeningMs,
  double? signalOkRatio,
  SessionSummary? summary,
});

/// Immutable daily-plan storage model.
typedef DailyPlanData = ({
  String date,
  DailyPlanItems items,
  int createdAt,
});

/// Immutable lesson-progress storage model.
typedef LessonProgressData = ({
  String lessonId,
  LessonState state,
  int stepIndex,
  int quizPercent,
  String contentVersion,
  int updatedAt,
});

/// Immutable setting storage model.
typedef SettingData = ({String key, JsonValueData value});

/// Immutable download storage model.
typedef DownloadData = ({
  String packageId,
  DownloadKind kind,
  String? activeVersion,
  String? pendingVersion,
  DownloadState state,
  int bytesTotal,
  int bytesDone,
  int updatedAt,
});

/// Immutable search-key cache storage model.
typedef SearchKeyCacheData = ({
  String normalizerId,
  int wordIndex,
  String key,
});

/// Immutable n-gram cache storage model.
typedef NgramCacheData = ({
  String normalizerId,
  String ngram,
  WordIndexes wordIndexes,
});

/// Immutable saved-recording metadata model.
typedef SavedRecordingData = ({
  String id,
  String sessionId,
  String path,
  int durationMs,
  int createdAt,
});

/// Immutable upload-queue storage model.
typedef UploadQueueData = ({
  String id,
  String sessionId,
  String filePath,
  UploadMetadata meta,
  int priority,
  int bytes,
  UploadState state,
  int tries,
  int createdAt,
});

/// Immutable entitlement-cache storage model.
typedef EntitlementCacheData = ({
  String id,
  EntitlementState state,
  int? expiresAt,
  int lastVerifiedAt,
});

/// Immutable free-usage storage model.
typedef FreeUsageData = ({String date, int listeningMs});

/// Immutable future-sync outbox model.
typedef OutboxData = ({
  String id,
  JsonObjectData event,
  int createdAt,
});
