import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_exception.dart';
import 'package:audio_capture/src/float_ring_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wraps and addresses retained samples by absolute position', () {
    final ring = FloatRingBuffer(5)
      ..push(Float32List.fromList(<double>[0, 1, 2, 3]))
      ..push(Float32List.fromList(<double>[4, 5, 6]));

    expect(ring.availableStart, 2);
    expect(ring.read(2, 7), <double>[2, 3, 4, 5, 6]);
    expect(() => ring.read(1, 3), throwsA(isA<AudioCaptureException>()));

    ring.clear();
    expect(ring.totalSamples, 0);
  });

  test('can clear audio without resetting the session clock', () {
    final ring = FloatRingBuffer(5)
      ..push(Float32List.fromList(<double>[1, 2, 3]))
      ..clear(preservePosition: true);

    expect(ring.totalSamples, 3);
    expect(ring.availableStart, 3);
    expect(() => ring.read(0, 1), throwsA(isA<AudioCaptureException>()));

    ring.push(Float32List.fromList(<double>[4, 5]));
    expect(ring.read(3, 5), <double>[4, 5]);
  });
}
