import 'dart:io';
import 'dart:typed_data';

import 'package:asr_sherpa/src/recognizer_exception.dart';

/// Mono floating-point audio read from a PCM16 WAV file.
final class WavAudio {
  /// Creates decoded WAV audio.
  const WavAudio({required this.samples, required this.sampleRate});

  /// Mono samples normalized to -1 through 1.
  final Float32List samples;

  /// Samples per second.
  final int sampleRate;
}

/// Reads PCM16 WAV without writing or retaining another audio file.
Future<WavAudio> readPcm16Wav(
  String path, {
  int targetSampleRate = 16000,
}) async {
  final bytes = await File(path).readAsBytes();
  return decodePcm16Wav(bytes, targetSampleRate: targetSampleRate);
}

/// Decodes PCM16 WAV bytes entirely in memory.
WavAudio decodePcm16Wav(
  Uint8List bytes, {
  int targetSampleRate = 16000,
}) {
  if (bytes.length < 44 ||
      _ascii(bytes, 0, 4) != 'RIFF' ||
      _ascii(bytes, 8, 4) != 'WAVE') {
    throw const SherpaRecognizerException(
      'invalidWav',
      'Input is not a RIFF/WAVE file.',
    );
  }
  final data = ByteData.sublistView(bytes);
  var offset = 12;
  int? format;
  int? channels;
  int? sampleRate;
  int? bitsPerSample;
  int? audioOffset;
  int? audioLength;
  while (offset + 8 <= bytes.length) {
    final chunkId = _ascii(bytes, offset, 4);
    final chunkLength = data.getUint32(offset + 4, Endian.little);
    final chunkStart = offset + 8;
    final chunkEnd = chunkStart + chunkLength;
    if (chunkEnd > bytes.length) {
      throw const SherpaRecognizerException(
        'invalidWav',
        'A WAV chunk is truncated.',
      );
    }
    if (chunkId == 'fmt ' && chunkLength >= 16) {
      format = data.getUint16(chunkStart, Endian.little);
      channels = data.getUint16(chunkStart + 2, Endian.little);
      sampleRate = data.getUint32(chunkStart + 4, Endian.little);
      bitsPerSample = data.getUint16(chunkStart + 14, Endian.little);
    } else if (chunkId == 'data') {
      audioOffset = chunkStart;
      audioLength = chunkLength;
    }
    offset = chunkEnd + chunkLength.remainder(2);
  }
  if (format != 1 ||
      channels == null ||
      channels <= 0 ||
      sampleRate == null ||
      sampleRate <= 0 ||
      bitsPerSample != 16 ||
      audioOffset == null ||
      audioLength == null) {
    throw const SherpaRecognizerException(
      'unsupportedWav',
      'WAV must contain PCM16 audio with at least one channel.',
    );
  }
  final frameBytes = channels * 2;
  if (audioLength.remainder(frameBytes) != 0) {
    throw const SherpaRecognizerException(
      'invalidWav',
      'WAV audio frames are truncated.',
    );
  }
  final frameCount = audioLength ~/ frameBytes;
  final mono = Float32List(frameCount);
  for (var frame = 0; frame < frameCount; frame++) {
    var sum = 0;
    for (var channel = 0; channel < channels; channel++) {
      sum += data.getInt16(
        audioOffset + frame * frameBytes + channel * 2,
        Endian.little,
      );
    }
    mono[frame] = sum / channels / 32768;
  }
  if (sampleRate == targetSampleRate) {
    return WavAudio(samples: mono, sampleRate: sampleRate);
  }
  return WavAudio(
    samples: _resampleLinear(mono, sampleRate, targetSampleRate),
    sampleRate: targetSampleRate,
  );
}

Float32List _resampleLinear(
  Float32List input,
  int sourceRate,
  int targetRate,
) {
  if (input.isEmpty) {
    return Float32List(0);
  }
  final outputLength = (input.length * targetRate / sourceRate).round();
  final output = Float32List(outputLength);
  for (var index = 0; index < outputLength; index++) {
    final sourcePosition = index * sourceRate / targetRate;
    final left = sourcePosition.floor().clamp(0, input.length - 1);
    final right = (left + 1).clamp(0, input.length - 1);
    final fraction = sourcePosition - left;
    output[index] = input[left] * (1 - fraction) + input[right] * fraction;
  }
  return output;
}

String _ascii(Uint8List bytes, int offset, int length) =>
    String.fromCharCodes(bytes.sublist(offset, offset + length));
