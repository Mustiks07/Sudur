import 'package:contracts/contracts.dart';
import 'package:planner/planner.dart';
import 'package:storage/storage.dart';
import 'package:sudur/data/models/canon_index.dart';
import 'package:sudur/data/repositories/plan_state_codec.dart';
import 'package:sudur/data/services/app_canon_service.dart';
import 'package:sudur/data/services/app_storage_service.dart';

// The class names keep the repository easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor
// ignore_for_file: prefer_initializing_formals

/// One step of an exercise with its words.
final class ExerciseStepData {
  /// Creates the step.
  const ExerciseStepData({
    required this.from,
    required this.to,
    required this.mode,
    required this.span,
  });

  /// First word.
  final WordKey from;

  /// Last word.
  final WordKey to;

  /// How it is read.
  final ExerciseReadMode mode;

  /// Which part of the place it is.
  final ExerciseSpan span;
}

/// An exercise for one place (docs/tz 13.5).
final class ExercisePlanData {
  /// Creates the plan.
  ExercisePlanData({
    required this.kind,
    required this.place,
    required List<ExerciseStepData> steps,
  }) : steps = List.unmodifiable(steps);

  /// Type (УП-01…05).
  final ExerciseKind kind;

  /// The place being trained: first word of the event.
  final WordKey place;

  /// Steps in order; the last one is the check (УП-07).
  final List<ExerciseStepData> steps;

  /// Whether a step reads a similar place from D01 (shown with the note
  /// “pairs not checked by a specialist”).
  bool get usesSimilarPairs => steps.any((s) => s.span == ExerciseSpan.other);
}

/// What happened, as the exercise sees it (3.3, table under УП-06).
ExerciseTrigger triggerOf(CheckEvent check, CanonIndex canon) {
  if (check.state == CheckState.unverified) return ExerciseTrigger.unverified;
  return switch (check.kind) {
    CheckKind.jump => ExerciseTrigger.jumpToSimilar,
    CheckKind.hesitation ||
    CheckKind.repetition => ExerciseTrigger.frequentHints,
    CheckKind.omission || CheckKind.substitution || CheckKind.insertion =>
      check.words.isNotEmpty &&
              check.words.first.word == 1 &&
              check.words.first.ayah > 1
          ? ExerciseTrigger.missedAyahStart
          : ExerciseTrigger.omissionOrSubstitution,
  };
}

/// Builds exercises from the canon and remembers places to come back to.
abstract interface class ExerciseRepository {
  /// The exercise for [check] (УП-06).
  Future<Result<ExercisePlanData>> plan(CheckEvent check);

  /// The exercise ended: when the check was not clean, the place becomes a
  /// hard spot due tomorrow, under [parentUnitId] (3.4, УП-07).
  Future<Result<void>> finish({
    required ExercisePlanData plan,
    required bool closed,
    String? parentUnitId,
  });
}

/// Storage-backed implementation.
final class LocalExerciseRepository implements ExerciseRepository {
  /// Creates the repository.
  LocalExerciseRepository({
    required AppCanonService canon,
    required AppStorageService storage,
    required Clock clock,
    required String Function() createId,
    ExerciseParams params = ExerciseParams.defaults,
  }) : _canon = canon,
       _storage = storage,
       _clock = clock,
       _createId = createId,
       _params = params;

  final AppCanonService _canon;
  final AppStorageService _storage;
  final Clock _clock;
  final String Function() _createId;
  final ExerciseParams _params;

  @override
  Future<Result<ExercisePlanData>> plan(CheckEvent check) async {
    try {
      final canon = await _canon.load();
      if (check.words.isEmpty) throw const FormatException('No words.');
      final kind = chooseExercise(triggerOf(check, canon));
      final first = canon.indexOf(check.words.first);
      final last = canon.indexOf(check.words.last);
      final ayah = canon.ayahOf(first);
      final lastAyah = canon.ayahOf(last);
      final ayahRange = (ayah.firstWordIndex, lastAyah.lastWordIndex);
      final placeRange = (
        _max(first - _params.contextWords, ayah.firstWordIndex),
        _min(last + _params.contextWords, lastAyah.lastWordIndex),
      );
      final previous = ayah.ayah > 1
          ? canon.ayahsOf(ayah.surah)[ayah.ayah - 2]
          : null;
      final junctionRange = previous == null
          ? placeRange
          : (
              _max(
                previous.lastWordIndex - _params.junctionWords + 1,
                previous.firstWordIndex,
              ),
              _min(
                ayah.firstWordIndex + _params.junctionWords - 1,
                ayah.lastWordIndex,
              ),
            );
      final similar = canon.similarTo(ayahRange.$1, ayahRange.$2);
      final steps = <ExerciseStepData>[];
      for (final step in exerciseSteps(kind, _params)) {
        final range = switch (step.span) {
          ExerciseSpan.place => placeRange,
          ExerciseSpan.ayah => ayahRange,
          ExerciseSpan.junction => junctionRange,
          // “If the second place was not learned, it is not forced” (УП-05):
          // it is only shown with support.
          ExerciseSpan.other => similar.firstOrNull,
        };
        if (range == null) continue;
        steps.add(
          ExerciseStepData(
            from: canon.keyOf(range.$1),
            to: canon.keyOf(range.$2),
            mode: step.mode,
            span: step.span,
          ),
        );
      }
      return Result.ok(
        ExercisePlanData(kind: kind, place: check.words.first, steps: steps),
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<void>> finish({
    required ExercisePlanData plan,
    required bool closed,
    String? parentUnitId,
  }) async {
    if (closed) return const Result.ok(null);
    try {
      final canon = await _canon.load();
      final storage = await _storage.storage;
      final place = plan.steps.firstWhere(
        (s) => s.span != ExerciseSpan.other,
        orElse: () => plan.steps.first,
      );
      final from = canon.indexOf(place.from);
      final to = canon.indexOf(place.to);
      final profiles = _unwrap(await storage.profiles.list());
      if (profiles.isEmpty) throw StateError('The profile is missing.');
      final profileId = profiles.first.id;
      final now = _clock.now().toUtc();
      final tomorrow = now.add(const Duration(days: 1));
      final existing = _unwrap(await storage.units.listForProfile(profileId))
          .where(
            (u) =>
                u.kind == UnitKind.hardSpot &&
                u.fromWordIndex == from &&
                u.toWordIndex == to,
          );
      final written = await storage.transaction(() async {
        final id = existing.isEmpty ? _createId() : existing.first.id;
        if (existing.isEmpty) {
          _unwrap(
            await storage.units.putUnit((
              id: id,
              profileId: profileId,
              kind: UnitKind.hardSpot,
              fromWordIndex: from,
              toWordIndex: to,
              skillId: null,
              surah: place.from.surah,
              origin: UnitOrigin.error,
              parentUnitId: parentUnitId,
              createdAt: now.millisecondsSinceEpoch,
            )),
          );
        }
        final state = _unwrap(await storage.units.getState(id));
        _unwrap(
          await storage.units.putState((
            unitId: id,
            queue: UnitQueue.learning,
            memoryState:
                state?.memoryState ??
                JsonObjectData.fromJson(
                  const PlanMemoryState(hardSpotStage: HardSpotStage.open)
                      .toJson(),
                ),
            fsrsCard:
                state?.fsrsCard ??
                JsonObjectData.fromJson(
                  encodeFsrsCard(
                    FsrsCardSnapshot.initial(
                      cardId: now.millisecondsSinceEpoch,
                      now: now,
                    ),
                  ),
                ),
            dueAt: tomorrow.millisecondsSinceEpoch,
            recentSince: state?.recentSince,
            lastAttemptAt: now.millisecondsSinceEpoch,
            lastMethod: state?.lastMethod,
            updatedAt: now.millisecondsSinceEpoch,
          )),
        );
      });
      _unwrap(written);
      return const Result.ok(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}

int _max(int a, int b) => a > b ? a : b;
int _min(int a, int b) => a < b ? a : b;

T _unwrap<T>(Result<T> result) => switch (result) {
  Ok<T>(:final value) => value,
  Error<T>(:final error) => throw error,
};
