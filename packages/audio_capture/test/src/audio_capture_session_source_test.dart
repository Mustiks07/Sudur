import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_event.dart' as capture;
import 'package:audio_capture/src/audio_capture_session_source.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps segment frames and shared signal quality', () {
    final mapper = AudioCaptureSessionEventMapper();
    final opened = mapper.map(
      const capture.SpeechSegmentOpened(atMs: 100, segmentId: 2),
    );
    final frame = mapper.map(
      capture.SpeechSegmentAudioFrame(
        atMs: 120,
        segmentId: 2,
        samples: Float32List(320),
        sampleRate: 16000,
        startMs: 100,
        endMs: 120,
      ),
    );
    final quality = mapper.map(
      const SignalQuality(
        sessionId: 'source-session',
        atMs: 120,
        level: SignalQualityLevel.tooQuiet,
        sinceMs: 80,
        dbfs: -50,
        clippedRatio: 0,
      ),
    );

    expect(opened, isA<SessionAudioSegmentOpened>());
    switch (frame) {
      case SessionAudioFrame():
        expect(frame.sampleRateHz, 16000);
      default:
        fail('Expected a session audio frame.');
    }
    switch (quality) {
      case SignalQuality():
        expect(quality.sessionId, 'source-session');
        expect(quality.level, SignalQualityLevel.tooQuiet);
        expect(quality.sinceMs, 80);
      default:
        fail('Expected shared signal quality.');
    }
  });

  test('keeps pause before the next segment', () {
    final mapper = AudioCaptureSessionEventMapper();
    expect(
      mapper.map(
        capture.SpeechSegmentReady(
          atMs: 400,
          segmentId: 1,
          samples: Float32List(1),
          sampleRate: 16000,
          audioStartMs: 0,
          audioEndMs: 400,
          speechStartMs: 100,
          speechEndMs: 300,
          pauseBeforeMs: 0,
        ),
      ),
      isNull,
    );
    final mapped = mapper.map(
      const capture.SpeechSegmentOpened(atMs: 800, segmentId: 2),
    );
    switch (mapped) {
      case SessionAudioSegmentOpened():
        expect(mapped.pauseBeforeMs, 500);
      default:
        fail('Expected a segment-open event.');
    }
  });
}
