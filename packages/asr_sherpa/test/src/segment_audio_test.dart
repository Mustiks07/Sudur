import 'dart:typed_data';

import 'package:asr_sherpa/src/segment_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the full segment and bounded tail in memory', () {
    final segment = SegmentAudio()
      ..add(Float32List.fromList(<double>[1, 2, 3]), 1000, 100)
      ..add(Float32List.fromList(<double>[4, 5]), 1000, 103);

    expect(segment.startMs, 100);
    expect(segment.endMs, 105);
    expect(segment.allSamples(), <double>[1, 2, 3, 4, 5]);
    expect(segment.tail(3), <double>[3, 4, 5]);

    segment.clear();
    expect(segment.length, 0);
    expect(segment.startMs, isNull);
  });
}
