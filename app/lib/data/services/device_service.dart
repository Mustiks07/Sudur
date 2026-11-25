import 'dart:typed_data';

import 'package:app_settings/app_settings.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sudur/data/services/prototype_session.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The phone itself: keeping the screen on and opening the app's settings.
abstract interface class DeviceService {
  /// Keeps the screen on while [on] (ЭЧ-09: it does not go dark while
  /// reading).
  Future<void> keepScreenOn({required bool on});

  /// Opens the system settings of the app («Открыть настройки», 13.3).
  Future<void> openAppSettings();

  /// Plays [audio] from memory, never from a file («Послушать себя»).
  Future<void> play(ReviewAudio audio);

  /// Stops what [play] started.
  Future<void> stopPlaying();

  /// Opens the share sheet with [text] («Поделиться итогом», РБ-06).
  Future<void> shareText(String text);
}

/// `wakelock_plus` and `app_settings`.
final class PluginDeviceService implements DeviceService {
  /// Creates the service.
  new();

  @override
  Future<void> keepScreenOn({required bool on}) =>
      on ? WakelockPlus.enable() : WakelockPlus.disable();

  @override
  Future<void> openAppSettings() => AppSettings.openAppSettings();

  // Created on first «Послушать себя», not at start-up.
  AudioPlayer? _audioPlayer;
  AudioPlayer get _player => _audioPlayer ??= AudioPlayer();

  @override
  Future<void> play(ReviewAudio audio) async {
    await _player.stop();
    await _player.play(BytesSource(wavBytes(audio), mimeType: 'audio/wav'));
  }

  @override
  Future<void> stopPlaying() async {
    await _audioPlayer?.stop();
  }

  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

const int _bytesPerSample = 2;
const int _pcmMax = 32767;
const int _wavHeaderBytes = 44;

/// [audio] as a mono 16-bit PCM WAV file in memory.
Uint8List wavBytes(ReviewAudio audio) {
  final samples = audio.samples;
  final dataBytes = samples.length * _bytesPerSample;
  final out = ByteData(_wavHeaderBytes + dataBytes);
  void text(int at, String value) {
    for (var i = 0; i < value.length; i++) {
      out.setUint8(at + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  out.setUint32(4, _wavHeaderBytes - 8 + dataBytes, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  out
    ..setUint32(16, 16, Endian.little) // PCM format chunk size.
    ..setUint16(20, 1, Endian.little) // PCM.
    ..setUint16(22, 1, Endian.little) // Mono.
    ..setUint32(24, audio.sampleRate, Endian.little)
    ..setUint32(28, audio.sampleRate * _bytesPerSample, Endian.little)
    ..setUint16(32, _bytesPerSample, Endian.little)
    ..setUint16(34, 8 * _bytesPerSample, Endian.little);
  text(36, 'data');
  out.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    out.setInt16(
      _wavHeaderBytes + i * _bytesPerSample,
      (clamped * _pcmMax).round(),
      Endian.little,
    );
  }
  return out.buffer.asUint8List();
}
