// Action value names are the product vocabulary and are self-documenting.
// ignore_for_file: public_member_api_docs

import 'package:planner/src/models.dart';
import 'package:planner/src/params.dart';

/// One action in learning a new passage.
enum LearningActionKind {
  listen,
  supportedRead,
  tryRecall,
  selfCheck,
  junction,
  combinedPassages,
}

/// Immutable learning action.
final class LearningAction {
  /// Creates an action for [unitId].
  const LearningAction({required this.kind, required this.unitId});

  final LearningActionKind kind;
  final String unitId;
}

/// Default ZN-01 learning sequence.
///
/// `tryRecall` repeats in the UI until an attempt is clean without hints;
/// the returned list describes the ordered action kinds, not that dynamic
/// repetition count.
List<LearningAction> learningSequence(
  PlanUnit unit,
  PlannerParams params,
) {
  final actions = <LearningAction>[];
  if (!unit.acceleratedLearning) {
    for (var index = 0; index < params.learnListenRepeats; index++) {
      actions.add(
        LearningAction(kind: LearningActionKind.listen, unitId: unit.id),
      );
    }
    for (var index = 0; index < params.learnSupportedRepeats; index++) {
      actions.add(
        LearningAction(
          kind: LearningActionKind.supportedRead,
          unitId: unit.id,
        ),
      );
    }
  }
  actions
    ..add(
      LearningAction(kind: LearningActionKind.tryRecall, unitId: unit.id),
    )
    ..add(
      LearningAction(kind: LearningActionKind.selfCheck, unitId: unit.id),
    );
  return List.unmodifiable(actions);
}

/// Actions added after learning the second and later passage of a surah.
List<LearningAction> afterLearningSequence(PlanUnit unit) {
  if (unit.previousUnitId == null) return const [];
  return List.unmodifiable([
    LearningAction(kind: LearningActionKind.junction, unitId: unit.id),
    LearningAction(
      kind: LearningActionKind.combinedPassages,
      unitId: unit.id,
    ),
  ]);
}

/// Orders new passages by explicit active goals, then by the default
/// end-of-Quran-to-start order (surah descending, words within a surah
/// ascending).
List<PlanUnit> orderNewUnits(
  List<PlanUnit> units,
  List<PlanGoal> goals,
) {
  final byId = {for (final unit in units) unit.id: unit};
  final ordered = <PlanUnit>[];
  final seen = <String>{};
  for (final goal in goals.where((goal) => goal.active)) {
    for (final id in goal.unitIds) {
      final unit = byId[id];
      if (unit != null && seen.add(id)) ordered.add(unit);
    }
  }
  final rest = units.where((unit) => seen.add(unit.id)).toList()
    ..sort((left, right) {
      final bySurah = right.range.surah.compareTo(left.range.surah);
      if (bySurah != 0) return bySurah;
      return left.range.from.compareTo(right.range.from);
    });
  return List.unmodifiable([...ordered, ...rest]);
}
