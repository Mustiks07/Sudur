// The class names keep the codec easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:planner/planner.dart';

// JSON of the planner state kept in `unit_state` (docs/tz 12.1):
// `fsrs_card` holds the FSRS card, `memory_state` the rest of what the
// planner tracks for a unit. Both stay inside the data layer.

/// `fsrs_card` JSON of [card].
Map<String, Object?> encodeFsrsCard(FsrsCardSnapshot card) => {
  'cardId': card.cardId,
  'stage': card.stage.name,
  'step': card.step,
  'stability': card.stability,
  'difficulty': card.difficulty,
  'due': card.due.toUtc().millisecondsSinceEpoch,
  'lastReview': card.lastReview?.toUtc().millisecondsSinceEpoch,
};

/// Reads `fsrs_card` JSON. Throws [FormatException] if it is not one.
FsrsCardSnapshot decodeFsrsCard(Map<String, Object?> json) => FsrsCardSnapshot(
  cardId: _int(json, 'cardId'),
  stage: _enum(FsrsStage.values, json, 'stage'),
  step: _intOrNull(json, 'step'),
  stability: _doubleOrNull(json, 'stability'),
  difficulty: _doubleOrNull(json, 'difficulty'),
  due: _time(json, 'due'),
  lastReview: _timeOrNull(json, 'lastReview'),
);

/// Planner fields of a unit besides its card, queue and history.
final class PlanMemoryState {
  /// Creates the state.
  const PlanMemoryState({
    this.hardSpotStage,
    this.skillStage,
    this.recentStartedAt,
    this.learningStartedAt,
    this.recentReviewIndex = 0,
    this.consecutiveForgot = 0,
    this.hardSpotCleanAt,
    this.acceleratedLearning = false,
  });

  /// Reads `memory_state` JSON; `null` gives the initial state.
  factory PlanMemoryState.fromJson(Map<String, Object?>? json) {
    if (json == null) return const PlanMemoryState();
    return PlanMemoryState(
      hardSpotStage: _enumOrNull(HardSpotStage.values, json, 'hardSpotStage'),
      skillStage: _enumOrNull(SkillStage.values, json, 'skillStage'),
      recentStartedAt: _timeOrNull(json, 'recentStartedAt'),
      learningStartedAt: _timeOrNull(json, 'learningStartedAt'),
      recentReviewIndex: _intOrNull(json, 'recentReviewIndex') ?? 0,
      consecutiveForgot: _intOrNull(json, 'consecutiveForgot') ?? 0,
      hardSpotCleanAt: _timeOrNull(json, 'hardSpotCleanAt'),
      acceleratedLearning: switch (json['acceleratedLearning']) {
        null => false,
        final bool value => value,
        _ => throw const FormatException('acceleratedLearning'),
      },
    );
  }

  /// The planner's state of [unit].
  factory PlanMemoryState.of(PlanUnit unit) => PlanMemoryState(
    hardSpotStage: unit.hardSpotStage,
    skillStage: unit.skillStage,
    recentStartedAt: unit.recentStartedAt,
    learningStartedAt: unit.learningStartedAt,
    recentReviewIndex: unit.recentReviewIndex,
    consecutiveForgot: unit.consecutiveForgot,
    hardSpotCleanAt: unit.hardSpotCleanAt,
    acceleratedLearning: unit.acceleratedLearning,
  );

  /// Stage of a hard spot; `null` for other units.
  final HardSpotStage? hardSpotStage;

  /// Stage of a skill; `null` for other units.
  final SkillStage? skillStage;

  /// When the unit entered the “recent” queue.
  final DateTime? recentStartedAt;

  /// When the unit entered the “new” queue.
  final DateTime? learningStartedAt;

  /// Step of the fixed recent ladder.
  final int recentReviewIndex;

  /// Forgotten reviews in a row.
  final int consecutiveForgot;

  /// First clean reading of a hard spot.
  final DateTime? hardSpotCleanAt;

  /// Faster learning after a failed recovery check.
  final bool acceleratedLearning;

  /// `memory_state` JSON.
  Map<String, Object?> toJson() => {
    'hardSpotStage': hardSpotStage?.name,
    'skillStage': skillStage?.name,
    'recentStartedAt': recentStartedAt?.toUtc().millisecondsSinceEpoch,
    'learningStartedAt': learningStartedAt?.toUtc().millisecondsSinceEpoch,
    'recentReviewIndex': recentReviewIndex,
    'consecutiveForgot': consecutiveForgot,
    'hardSpotCleanAt': hardSpotCleanAt?.toUtc().millisecondsSinceEpoch,
    'acceleratedLearning': acceleratedLearning,
  };
}

int _int(Map<String, Object?> json, String key) =>
    _intOrNull(json, key) ?? (throw FormatException('$key is missing.'));

int? _intOrNull(Map<String, Object?> json, String key) => switch (json[key]) {
  null => null,
  final int value => value,
  _ => throw FormatException('$key must be an integer.'),
};

double? _doubleOrNull(Map<String, Object?> json, String key) =>
    switch (json[key]) {
      null => null,
      final num value => value.toDouble(),
      _ => throw FormatException('$key must be a number.'),
    };

DateTime _time(Map<String, Object?> json, String key) =>
    _timeOrNull(json, key) ?? (throw FormatException('$key is missing.'));

DateTime? _timeOrNull(Map<String, Object?> json, String key) =>
    switch (_intOrNull(json, key)) {
      null => null,
      final int ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
    };

T _enum<T extends Enum>(
  List<T> values,
  Map<String, Object?> json,
  String key,
) =>
    _enumOrNull(values, json, key) ??
    (throw FormatException('$key is missing.'));

T? _enumOrNull<T extends Enum>(
  List<T> values,
  Map<String, Object?> json,
  String key,
) {
  final raw = json[key];
  if (raw == null) return null;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('$key has an unknown value.');
}
