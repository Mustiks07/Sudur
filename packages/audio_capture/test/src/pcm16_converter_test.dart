import 'dart:typed_data';

import 'package:audio_capture/src/pcm16_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts little-endian PCM16 to normalized Float32', () {
    final bytes = Uint8List(6);
    ByteData.sublistView(bytes)
      ..setInt16(0, -32768, Endian.little)
      ..setInt16(2, 0, Endian.little)
      ..setInt16(4, 32767, Endian.little);

    final samples = pcm16ToFloat32(bytes);

    expect(samples[0], -1);
    expect(samples[1], 0);
    expect(samples[2], closeTo(1, 0.0001));
  });
}
