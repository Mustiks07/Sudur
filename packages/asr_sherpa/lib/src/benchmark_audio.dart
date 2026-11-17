import 'dart:math' as math;
import 'dart:typed_data';

/// Fixed seed used by the reproducible phone-speed sample.
const benchmarkNoiseSeed = 0x5D0D;

/// Peak amplitude of the low-level synthetic benchmark noise.
const benchmarkNoiseAmplitude = 0.02;

/// Generates deterministic non-silent Float32 noise entirely in memory.
Float32List generateBenchmarkNoise({
  required int sampleRate,
  required int durationMs,
  int seed = benchmarkNoiseSeed,
}) {
  assert(sampleRate > 0, 'sampleRate must be positive.');
  assert(durationMs > 0, 'durationMs must be positive.');
  final random = math.Random(seed);
  final samples = Float32List(sampleRate * durationMs ~/ 1000);
  for (var index = 0; index < samples.length; index++) {
    samples[index] = (random.nextDouble() * 2 - 1) * benchmarkNoiseAmplitude;
  }
  return samples;
}
