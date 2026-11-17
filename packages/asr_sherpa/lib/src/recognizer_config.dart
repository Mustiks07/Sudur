/// Runtime parameters for simulated streaming recognition.
final class SherpaRecognizerConfig {
  /// Creates recognizer parameters.
  const SherpaRecognizerConfig({
    this.asrThreads = 2,
    this.partialIntervalMs = 500,
    this.maxPartialWindowMs = 8000,
    this.deviceTestAudioMs = 10000,
  })  : assert(asrThreads > 0, 'asrThreads must be positive.'),
        assert(partialIntervalMs > 0, 'partialIntervalMs must be positive.'),
        assert(
          maxPartialWindowMs >= partialIntervalMs,
          'The partial window must be at least one partial interval.',
        ),
        assert(deviceTestAudioMs > 0, 'deviceTestAudioMs must be positive.');

  /// Native decoder worker count.
  final int asrThreads;

  /// Audio interval between partial decodes.
  final int partialIntervalMs;

  /// Maximum tail of the open segment used for a partial decode.
  final int maxPartialWindowMs;

  /// Duration of the generated in-memory phone benchmark sample.
  final int deviceTestAudioMs;
}
