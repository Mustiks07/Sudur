import 'package:audio_capture/audio_capture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the platform recorder is not created until it is used', () async {
    // No Flutter binding here: creating `AudioRecorder` would throw. A
    // session is built before the microphone is needed (review of #27,
    // app test «concurrent starts await one isolate spawn»).
    final port = RecordAudioRecorderPort();
    final service = AudioCaptureService(sessionId: 'lazy');
    await port.dispose();
    await service.dispose();
  });
}
