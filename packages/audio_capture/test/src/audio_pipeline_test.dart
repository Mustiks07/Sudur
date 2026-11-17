import 'dart:typed_data';

import 'package:audio_capture/audio_capture.dart';
import 'package:audio_capture/src/audio_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports frames while a segment is open and its transitions', () {
    const config = AudioCaptureConfig(
      sampleRate: 1000,
      segmentEndPauseMs: 200,
    );
    final pipeline = AudioPipeline(config);
    final silence = Float32List(100);
    final speech = Float32List.fromList(List<double>.filled(100, 0.2));

    pipeline.processFrame(Float32List(300), isSpeech: false);
    final opened = pipeline.processFrame(speech, isSpeech: true);
    final continuing = pipeline.processFrame(speech, isSpeech: true);
    pipeline.processFrame(silence, isSpeech: false);
    final closed = pipeline.processFrame(silence, isSpeech: false);

    expect(opened.wasSegmentOpen, isFalse);
    expect(opened.isSegmentOpen, isTrue);
    expect(opened.openedAtSample, 300);
    expect(opened.openedAudioStartSample, 0);
    expect(opened.openedSamples, hasLength(400));
    expect(opened.frameStart, 300);
    expect(opened.frameEnd, 400);
    expect(continuing.wasSegmentOpen, isTrue);
    expect(continuing.isSegmentOpen, isTrue);
    expect(closed.wasSegmentOpen, isTrue);
    expect(closed.isSegmentOpen, isFalse);
    expect(closed.segments, hasLength(1));
  });

  test('adds pre/post roll and preserves pause duration', () {
    const config = AudioCaptureConfig(
      sampleRate: 1000,
    );
    final pipeline = AudioPipeline(config);
    final silence = Float32List(100);
    final speech = Float32List.fromList(List<double>.filled(100, 0.2));
    final segments = <ProcessedSegment>[];

    for (var index = 0; index < 3; index++) {
      segments.addAll(pipeline.processFrame(silence, isSpeech: false).segments);
    }
    for (var index = 0; index < 2; index++) {
      segments.addAll(pipeline.processFrame(speech, isSpeech: true).segments);
    }
    for (var index = 0; index < 7; index++) {
      segments.addAll(pipeline.processFrame(silence, isSpeech: false).segments);
    }

    expect(segments, hasLength(1));
    final first = segments.single;
    expect(first.boundary.audioStart, 0);
    expect(first.boundary.audioEnd, 800);
    expect(first.boundary.speechStart, 300);
    expect(first.boundary.speechEnd, 500);
    expect(first.boundary.pauseBefore, 0);
    expect(first.samples, hasLength(800));

    pipeline
      ..processFrame(silence, isSpeech: false)
      ..processFrame(speech, isSpeech: true)
      ..processFrame(speech, isSpeech: true);
    for (var index = 0; index < 7; index++) {
      segments.addAll(pipeline.processFrame(silence, isSpeech: false).segments);
    }
    expect(segments[1].boundary.pauseBefore, 800);
  });

  test('forced maximum length splits at the quietest recent frame', () {
    const config = AudioCaptureConfig(
      sampleRate: 1000,
      preRollMs: 100,
      postRollMs: 100,
      maxSegmentMs: 1000,
      quietSplitWindowMs: 500,
    );
    final pipeline = AudioPipeline(config);
    AudioPipelineOutput? output;
    for (var frame = 0; frame < 10; frame++) {
      final amplitude = frame == 6 ? 0.01 : 0.2;
      output = pipeline.processFrame(
        Float32List.fromList(List<double>.filled(100, amplitude)),
        isSpeech: true,
      );
    }

    expect(output?.segments, hasLength(1));
    expect(output?.segments.single.boundary.speechEnd, 650);
    expect(output?.isSegmentOpen, isTrue);
    expect(output?.openedAtSample, 650);
    expect(output?.openedAudioStartSample, 550);
    expect(output?.openedSamples, hasLength(450));
  });

  test('review snippets exist only inside the retained ring', () {
    const config = AudioCaptureConfig(
      sampleRate: 1000,
      ringBufferSec: 3,
      reviewSnippetPadMs: 0,
    );
    final pipeline = AudioPipeline(config);
    for (var index = 0; index < 5; index++) {
      pipeline.processFrame(Float32List(1000), isSpeech: false);
    }

    expect(pipeline.snippet(2500, 3500), hasLength(1000));
    expect(
      () => pipeline.snippet(1000, 2000),
      throwsA(isA<AudioCaptureException>()),
    );
  });

  test('clamps pre-roll after pause and closes the complete segment', () {
    const config = AudioCaptureConfig(sampleRate: 1000);
    final pipeline = AudioPipeline(config)
      ..processFrame(Float32List(500), isSpeech: false)
      ..clear(preserveTimeline: true);

    final opened = pipeline.processFrame(
      Float32List.fromList(List<double>.filled(100, 0.2)),
      isSpeech: true,
    );
    final closed = pipeline.flush();

    expect(pipeline.currentSample, 600);
    expect(opened.frameStart, 500);
    expect(opened.openedAtSample, 500);
    expect(opened.openedAudioStartSample, 500);
    expect(opened.openedSamples, hasLength(100));
    expect(closed?.boundary.audioStart, 500);
    expect(closed?.samples, hasLength(100));
  });

  test('preserves quality timestamps when audio memory is cleared', () {
    const config = AudioCaptureConfig(sampleRate: 1000);
    final pipeline = AudioPipeline(config);
    for (var second = 0; second < 5; second++) {
      pipeline.processFrame(Float32List(1000), isSpeech: false);
    }
    pipeline.clear(preserveTimeline: true);

    final output = pipeline.processFrame(
      Float32List(1000),
      isSpeech: false,
    );

    expect(output.qualityReadings.single.endSample, 6000);
  });
}
