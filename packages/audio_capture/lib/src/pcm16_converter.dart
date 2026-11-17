import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_exception.dart';

/// Converts little-endian signed PCM16 to normalized Float32.
Float32List pcm16ToFloat32(Uint8List bytes) {
  if (bytes.lengthInBytes.isOdd) {
    throw const AudioCaptureException(
      'invalidPcm16',
      'A PCM16 buffer has an odd byte count.',
    );
  }
  final input = ByteData.sublistView(bytes);
  final output = Float32List(bytes.lengthInBytes ~/ 2);
  for (var index = 0; index < output.length; index++) {
    output[index] = input.getInt16(index * 2, Endian.little) / 32768;
  }
  return output;
}
