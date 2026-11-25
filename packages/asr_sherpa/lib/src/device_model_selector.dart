import 'package:asr_sherpa/src/device_benchmark.dart';
import 'package:contracts/contracts.dart';

/// Runs the in-memory phone benchmark for one installed model package.
typedef AsrBenchmarkRunner = Future<Result<AsrDeviceBenchmark>> Function(
  String packageId,
);

/// Complete model/partial-interval choice for voice mode.
final class AsrDeviceSelection {
  /// Creates a phone-test outcome.
  const AsrDeviceSelection({
    required this.decision,
    required this.packageId,
    required this.partialIntervalMs,
    required this.small,
    this.tiny,
  });

  /// Rule-table decision.
  final AsrDeviceDecision decision;

  /// Selected model package; null means self-check mode.
  final String? packageId;

  /// Partial interval for the selected model; null in self-check mode.
  final int? partialIntervalMs;

  /// Small-model measurement.
  final AsrDeviceBenchmark small;

  /// Tiny-model measurement when the small model was not fast enough.
  final AsrDeviceBenchmark? tiny;
}

/// Repeatable implementation of the model-selection table in section 10.3.
final class AsrDeviceModelSelector {
  /// Creates a selector around an installed-model benchmark runner.
  const AsrDeviceModelSelector({
    required AsrBenchmarkRunner benchmark,
    this.smallPackageId = 'quran-asr-small',
    this.tinyPackageId = 'quran-asr-tiny',
    this.normalPartialIntervalMs = 500,
    this.slowPartialIntervalMs = 1000,
    this.smallMax = 0.3,
    this.tinyMax = 0.6,
  }) : _benchmark = benchmark;

  final AsrBenchmarkRunner _benchmark;

  /// Content package id of the higher-accuracy model.
  final String smallPackageId;

  /// Content package id of the fallback model.
  final String tinyPackageId;

  /// Normal partial result interval.
  final int normalPartialIntervalMs;

  /// Partial interval used on a borderline phone.
  final int slowPartialIntervalMs;

  /// Fast threshold from section 10.3.
  final double smallMax;

  /// Maximum usable ratio from section 10.3.
  final double tinyMax;

  /// Runs or reruns the test; no result is cached.
  Future<Result<AsrDeviceSelection>> run() async {
    final smallResult = await _benchmark(smallPackageId);
    final AsrDeviceBenchmark small;
    switch (smallResult) {
      case Error<AsrDeviceBenchmark>(:final error):
        return Result.error(error);
      case Ok<AsrDeviceBenchmark>(:final value):
        small = value;
    }
    if (small.speedRatio <= smallMax) {
      return Result.ok(
        AsrDeviceSelection(
          decision: AsrDeviceDecision.small,
          packageId: smallPackageId,
          partialIntervalMs: normalPartialIntervalMs,
          small: small,
        ),
      );
    }

    final tinyResult = await _benchmark(tinyPackageId);
    final AsrDeviceBenchmark tiny;
    switch (tinyResult) {
      case Error<AsrDeviceBenchmark>(:final error):
        return Result.error(error);
      case Ok<AsrDeviceBenchmark>(:final value):
        tiny = value;
    }
    final decision = selectAsrDeviceDecision(
      smallSpeedRatio: small.speedRatio,
      tinySpeedRatio: tiny.speedRatio,
      smallMax: smallMax,
      tinyMax: tinyMax,
    );
    return Result.ok(
      AsrDeviceSelection(
        decision: decision,
        packageId: switch (decision) {
          AsrDeviceDecision.small ||
          AsrDeviceDecision.smallWithSlowPartials =>
            smallPackageId,
          AsrDeviceDecision.tiny => tinyPackageId,
          AsrDeviceDecision.selfCheck => null,
        },
        partialIntervalMs: switch (decision) {
          AsrDeviceDecision.small => normalPartialIntervalMs,
          AsrDeviceDecision.tiny => normalPartialIntervalMs,
          AsrDeviceDecision.smallWithSlowPartials => slowPartialIntervalMs,
          AsrDeviceDecision.selfCheck => null,
        },
        small: small,
        tiny: tiny,
      ),
    );
  }
}
