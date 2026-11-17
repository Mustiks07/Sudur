/// Speed measurement for a generated in-memory sample.
final class AsrDeviceBenchmark {
  /// Creates a speed measurement.
  const AsrDeviceBenchmark({
    required this.modelId,
    required this.audioDurationMs,
    required this.decodeMs,
  });

  /// Identifier from the loaded model package.
  final String modelId;

  /// Duration of decoded audio.
  final int audioDurationMs;

  /// Wall-clock decoder time.
  final int decodeMs;

  /// Processing time divided by audio duration.
  double get speedRatio => decodeMs / audioDurationMs;
}

/// Voice-mode decision from the small and tiny model speed tests.
enum AsrDeviceDecision {
  /// Use the small model with the normal partial interval.
  small,

  /// Use the tiny model.
  tiny,

  /// Use small with a 1000 ms partial interval.
  smallWithSlowPartials,

  /// Disable recognition and offer self-check mode.
  selfCheck,
}

/// Applies the thresholds from specification section 10.3.
AsrDeviceDecision selectAsrDeviceDecision({
  required double smallSpeedRatio,
  required double tinySpeedRatio,
  double smallMax = 0.3,
  double tinyMax = 0.6,
}) {
  if (smallSpeedRatio <= smallMax) {
    return AsrDeviceDecision.small;
  }
  if (smallSpeedRatio <= tinyMax) {
    return tinySpeedRatio <= smallMax
        ? AsrDeviceDecision.tiny
        : AsrDeviceDecision.smallWithSlowPartials;
  }
  return tinySpeedRatio <= tinyMax
      ? AsrDeviceDecision.tiny
      : AsrDeviceDecision.selfCheck;
}
