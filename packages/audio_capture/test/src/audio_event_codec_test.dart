import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_capture/audio_capture.dart';
import 'package:audio_capture/src/audio_event_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes open audio and close events for one segment', () {
    final opened = audioEventFromMessage(<String, Object?>{
      'kind': 'segmentOpened',
      'atMs': 100,
      'segmentId': 7,
    });
    final sourceSamples = Float32List.fromList(<double>[0.1, -0.2]);
    final audio = audioEventFromMessage(<String, Object?>{
      'kind': 'segmentAudio',
      'atMs': 140,
      'segmentId': 7,
      'samples': TransferableTypedData.fromList(<TypedData>[
        sourceSamples.buffer.asUint8List(),
      ]),
      'sampleRate': 16000,
      'startMs': 100,
      'endMs': 140,
    });
    final closed = audioEventFromMessage(<String, Object?>{
      'kind': 'segmentClosed',
      'atMs': 900,
      'segmentId': 7,
    });

    expect(opened, isA<SpeechSegmentOpened>());
    expect((opened as SpeechSegmentOpened).segmentId, 7);
    expect(audio, isA<SpeechSegmentAudioFrame>());
    final frame = audio as SpeechSegmentAudioFrame;
    expect(frame.segmentId, 7);
    expect(frame.startMs, 100);
    expect(frame.endMs, 140);
    expect(frame.samples, hasLength(2));
    expect(frame.samples[0], closeTo(0.1, 0.000001));
    expect(frame.samples[1], closeTo(-0.2, 0.000001));
    expect(closed, isA<SpeechSegmentClosed>());
    expect((closed as SpeechSegmentClosed).segmentId, 7);
  });
}
