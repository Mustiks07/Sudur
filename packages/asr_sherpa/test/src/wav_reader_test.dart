import 'dart:typed_data';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads PCM16 stereo as mono without writing audio', () {
    final audio = decodePcm16Wav(_stereoWav(), targetSampleRate: 8000);

    expect(audio.sampleRate, 8000);
    expect(audio.samples, hasLength(2));
    expect(audio.samples[0], closeTo(0, 0.0001));
    expect(audio.samples[1], closeTo(0.5, 0.0001));
  });
}

Uint8List _stereoWav() {
  const samples = <int>[-32768, 32767, 16384, 16384];
  final bytes = Uint8List(44 + samples.length * 2);
  final data = ByteData.sublistView(bytes);
  _writeAscii(bytes, 0, 'RIFF');
  data.setUint32(4, bytes.length - 8, Endian.little);
  _writeAscii(bytes, 8, 'WAVE');
  _writeAscii(bytes, 12, 'fmt ');
  data
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 2, Endian.little)
    ..setUint32(24, 8000, Endian.little)
    ..setUint32(28, 32000, Endian.little)
    ..setUint16(32, 4, Endian.little)
    ..setUint16(34, 16, Endian.little);
  _writeAscii(bytes, 36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var index = 0; index < samples.length; index++) {
    data.setInt16(44 + index * 2, samples[index], Endian.little);
  }
  return bytes;
}

void _writeAscii(Uint8List bytes, int offset, String value) {
  bytes.setRange(offset, offset + value.length, value.codeUnits);
}
