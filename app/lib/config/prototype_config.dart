/// Prototype transport limits, separate from recognition quality thresholds.
final class PrototypeConfig {
  /// Uses the slow-partial fallback from spec 10.3.
  const new({
    this.slowPartialIntervalMs = 1000,
    this.drainTimeout = const Duration(seconds: 30),
    this.maxPendingAudioRequests = 750,
    this.followTimeout = const Duration(seconds: 15),
  });

  /// ASR interval after the phone test recommends slow partials.
  final int slowPartialIntervalMs;

  /// Maximum wait before declaring an unfinished run invalid.
  final Duration drainTimeout;

  /// Bounds queued in-memory audio at approximately one 30-second buffer.
  final int maxPendingAudioRequests;

  /// Failing workers must not leave UI operations pending forever.
  final Duration followTimeout;
}
