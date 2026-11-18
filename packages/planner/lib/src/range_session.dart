import 'package:planner/src/models.dart';

/// Creates one attempt for every plan unit read completely in a range session.
///
/// A partially covered unit is deliberately omitted (PL-12). The session
/// duration is apportioned by word count only among the complete units; the
/// caller may replace it with measured per-unit durations when available.
List<Attempt> attemptsForCompletedUnits({
  required PassageRange sessionRange,
  required List<PlanUnit> units,
  required DateTime at,
  required AttemptMode mode,
  required AttemptResult result,
  required int hints,
  required VerificationMethod verification,
  required Duration duration,
}) {
  final complete =
      units.where((unit) => unit.range.isInside(sessionRange)).toList()
        ..sort(
          (left, right) => left.range.from.compareTo(right.range.from),
        );
  if (complete.isEmpty) return const [];
  final completeWords = complete.fold(
    0,
    (sum, unit) => sum + unit.range.wordCount,
  );
  return List.unmodifiable(
    complete.map((unit) {
      final microseconds =
          duration.inMicroseconds * unit.range.wordCount ~/ completeWords;
      return Attempt(
        unitId: unit.id,
        at: at,
        mode: mode,
        result: result,
        hints: hints,
        verification: verification,
        duration: Duration(microseconds: microseconds),
        wordCount: unit.range.wordCount,
      );
    }),
  );
}
