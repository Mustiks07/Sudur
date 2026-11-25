import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects small, tiny, slow partials, and self-check at thresholds', () {
    expect(
      selectAsrDeviceDecision(smallSpeedRatio: 0.3, tinySpeedRatio: 0.2),
      AsrDeviceDecision.small,
    );
    expect(
      selectAsrDeviceDecision(smallSpeedRatio: 0.4, tinySpeedRatio: 0.3),
      AsrDeviceDecision.tiny,
    );
    expect(
      selectAsrDeviceDecision(smallSpeedRatio: 0.4, tinySpeedRatio: 0.4),
      AsrDeviceDecision.smallWithSlowPartials,
    );
    expect(
      selectAsrDeviceDecision(smallSpeedRatio: 0.7, tinySpeedRatio: 0.7),
      AsrDeviceDecision.selfCheck,
    );
  });

  test('runs the full table and reruns on every request', () async {
    var runs = 0;
    final ratios = <String, double>{
      'quran-asr-small': 0.4,
      'quran-asr-tiny': 0.4,
    };
    final selector = AsrDeviceModelSelector(
      benchmark: (packageId) async {
        runs++;
        return Result.ok(
          AsrDeviceBenchmark(
            modelId: packageId,
            audioDurationMs: 10000,
            decodeMs: (ratios[packageId]! * 10000).round(),
          ),
        );
      },
    );

    final first = (await selector.run() as Ok<AsrDeviceSelection>).value;
    expect(first.decision, AsrDeviceDecision.smallWithSlowPartials);
    expect(first.packageId, 'quran-asr-small');
    expect(first.partialIntervalMs, 1000);
    expect(runs, 2);

    ratios['quran-asr-small'] = 0.2;
    final rerun = (await selector.run() as Ok<AsrDeviceSelection>).value;
    expect(rerun.decision, AsrDeviceDecision.small);
    expect(rerun.partialIntervalMs, 500);
    expect(runs, 3);
  });

  test('selects tiny or self-check from slow phone measurements', () async {
    Future<AsrDeviceSelection> select(double tinyRatio) async {
      final selector = AsrDeviceModelSelector(
        benchmark: (packageId) async => Result.ok(
          AsrDeviceBenchmark(
            modelId: packageId,
            audioDurationMs: 10000,
            decodeMs: packageId.endsWith('small')
                ? 7000
                : (tinyRatio * 10000).round(),
          ),
        ),
      );
      return (await selector.run() as Ok<AsrDeviceSelection>).value;
    }

    expect((await select(0.5)).decision, AsrDeviceDecision.tiny);
    expect((await select(0.7)).decision, AsrDeviceDecision.selfCheck);
    expect((await select(0.7)).packageId, isNull);
  });
}
