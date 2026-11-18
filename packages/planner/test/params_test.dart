import 'package:planner/planner.dart';
import 'package:test/test.dart';

void main() {
  test('defaults match docs/tz 12.4 plan group', () {
    final params = PlannerParams.defaults;

    expect(params.newShare, 0.2);
    expect(params.recentShare, 0.3);
    expect(params.oldShare, 0.5);
    expect(params.hardSpotMaxShare, 0.25);
    expect(params.recentDays, 30);
    expect(params.recentLadderDays, [1, 2, 4, 7]);
    expect(params.desiredRetention, 0.9);
    expect(params.breakDays, 7);
    expect((params.diagnosticMinSize, params.diagnosticMaxSize), (3, 5));
    expect(params.afterBreakNewFactor, 0.5);
    expect(params.afterBreakDays, 7);
    expect(params.defaultSecondsPerWord, 1);
    expect(params.speedWindow, 10);
    expect(params.debtLimitFactor, 1);
    expect(params.passageMaxAyahs, 5);
    expect(
      (
        params.recallMultiplier,
        params.hardSpotMultiplier,
        params.newLearningMultiplier,
      ),
      (1.3, 3, 8),
    );
    expect((params.learnListenRepeats, params.learnSupportedRepeats), (3, 2));
    expect(params.recentStrongAttempts, 2);
    expect(params.easyConsecutiveCleanAttempts, 2);
    expect(params.memoryConfirmationAttempts, 2);
    expect(params.unfinishedLookbackDays, 1);
  });

  test('fromJson overrides selected values and keeps defaults', () {
    final params = PlannerParams.fromJson({
      'newShare': 0.1,
      'recentLadderDays': <Object?>[1, 3, 5],
    });

    expect(params.newShare, 0.1);
    expect(params.recentLadderDays, [1, 3, 5]);
    expect(params.desiredRetention, 0.9);
  });

  test('fromJson rejects a wrong value type', () {
    expect(
      () => PlannerParams.fromJson({'breakDays': 'seven'}),
      throwsFormatException,
    );
  });
}
