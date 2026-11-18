import 'package:planner/planner.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  final params = PlannerParams.defaults;

  group('grading table', () {
    test('clean voice reading is Good', () {
      final assessment = assessAttempt(attempt(unitId: 'u'), const [], params);

      expect(assessment.rating, PlannerRating.good);
    });

    test('two interval clean readings faster than average are Easy', () {
      final first = attempt(
        unitId: 'u',
        at: epoch,
        duration: const Duration(seconds: 20),
      );
      final current = attempt(
        unitId: 'u',
        at: epoch.add(const Duration(days: 1)),
      );

      final assessment = assessAttempt(
        current,
        [record(attempt: first, rating: PlannerRating.good)],
        params,
      );

      expect(assessment.rating, PlannerRating.easy);
    });

    test('self-correction or one hint is Hard', () {
      expect(
        assessAttempt(
          attempt(unitId: 'u', result: AttemptResult.selfCorrected),
          const [],
          params,
        ).rating,
        PlannerRating.hard,
      );
      expect(
        assessAttempt(attempt(unitId: 'u', hints: 1), const [], params).rating,
        PlannerRating.hard,
      );
    });

    test('confirmed error or two hints is Again', () {
      expect(
        assessAttempt(
          attempt(unitId: 'u', result: AttemptResult.confirmedError),
          const [],
          params,
        ).rating,
        PlannerRating.again,
      );
      expect(
        assessAttempt(attempt(unitId: 'u', hints: 2), const [], params).rating,
        PlannerRating.again,
      );
    });

    test('self-report has no Easy rating', () {
      for (final pair in [
        (AttemptResult.remembered, PlannerRating.good),
        (AttemptResult.rememberedWithDifficulty, PlannerRating.hard),
        (AttemptResult.forgotten, PlannerRating.again),
      ]) {
        final assessment = assessAttempt(
          attempt(unitId: 'u', mode: AttemptMode.selfReport, result: pair.$1),
          const [],
          params,
        );
        expect(assessment.rating, pair.$2);
      }
    });

    test('unsupported, failed and disputed checks do not rate', () {
      final supported = assessAttempt(
        attempt(unitId: 'u', mode: AttemptMode.supported),
        const [],
        params,
      );
      final failed = assessAttempt(
        attempt(unitId: 'u', result: AttemptResult.unableToVerify),
        const [],
        params,
      );
      final disputed = assessAttempt(
        attempt(unitId: 'u', result: AttemptResult.disputed),
        const [],
        params,
      );

      expect(supported.rating, isNull);
      expect(failed.rating, isNull);
      expect(disputed.rating, isNull);
      expect(disputed.needsRecheck, isTrue);
    });
  });
}
