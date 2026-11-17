// State value names are the product vocabulary and are self-documenting.
// ignore_for_file: public_member_api_docs

import 'package:planner/src/models.dart';
import 'package:planner/src/params.dart';

/// Memory-map states from docs/tz section 3.6 and 11.1.
enum MemoryState {
  acquainted,
  supported,
  independent,
  confirmedLater,
  longUnchecked,
  hasHardSpot,
}

/// Derives the visible memory state exclusively from planner data.
MemoryState memoryStateFor(
  PlanUnit unit, {
  required DateTime now,
  required double retrievability,
  required PlannerParams params,
}) {
  if (unit.hasOpenHardSpot ||
      (unit.kind == PlanUnitKind.hardSpot &&
          unit.hardSpotStage != HardSpotStage.closed)) {
    return MemoryState.hasHardSpot;
  }
  final overdueDays = now.toUtc().difference(unit.due.toUtc()).inDays;
  final hasRatedReview = unit.card.lastReview != null;
  if ((hasRatedReview && overdueDays > params.memoryOverdueDays) ||
      (hasRatedReview && retrievability < params.memoryLowProbability)) {
    return MemoryState.longUnchecked;
  }
  if (unit.history.isEmpty) return MemoryState.acquainted;
  final last = unit.history.last.attempt;
  if (last.mode == AttemptMode.listening) return MemoryState.acquainted;
  if (last.mode == AttemptMode.supported || last.hints > 0) {
    return MemoryState.supported;
  }

  final clean = unit.history
      .where((record) => record.attempt.isCleanWithoutHints)
      .map((record) => record.attempt)
      .toList();
  if (clean.length >= params.memoryConfirmationAttempts) {
    final interval = clean.last.at
        .difference(
          clean[clean.length - params.memoryConfirmationAttempts].at,
        )
        .inDays;
    if (interval >= params.memoryConfirmationIntervalDays) {
      return MemoryState.confirmedLater;
    }
  }
  return MemoryState.independent;
}
