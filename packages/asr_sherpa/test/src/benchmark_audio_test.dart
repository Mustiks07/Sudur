import 'package:asr_sherpa/src/benchmark_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds ten seconds of deterministic non-silent noise', () {
    final first = generateBenchmarkNoise(
      sampleRate: 16000,
      durationMs: 10000,
    );
    final second = generateBenchmarkNoise(
      sampleRate: 16000,
      durationMs: 10000,
    );

    expect(first, hasLength(160000));
    expect(first, orderedEquals(second));
    expect(first.any((sample) => sample != 0), isTrue);
  });
}
