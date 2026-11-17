import 'dart:async';
import 'dart:typed_data';

import 'package:contracts/contracts.dart';

/// A [SpeechRecognizer] that plays back prepared results instead of
/// recognizing audio (docs/tz СЛ-07, ПО-12: work on saved results).
final class FakeSpeechRecognizer implements SpeechRecognizer {
  /// Creates a recognizer that will emit [script] on [play].
  FakeSpeechRecognizer(
    this.script, {
    required this.info,
    this.loadResult = const Result<void>.ok(null),
    this.onCloseSegment,
  });

  /// Results to play, in order.
  final List<RecognitionResult> script;

  @override
  final RecognizerInfo info;

  /// Result returned by [load].
  final Result<void> loadResult;

  /// Optional synchronous hook invoked by [closeSegment].
  final void Function(int segmentId)? onCloseSegment;

  final StreamController<RecognitionResult> _results =
      StreamController<RecognitionResult>.broadcast(sync: true);

  /// Whether [load] was called.
  bool loaded = false;

  /// Model directory passed to [load].
  String? loadedModelDirectory;

  /// Audio calls received from the session.
  final List<({Float32List samples, int sampleRateHz, int startMs})>
      acceptedAudio = [];

  /// Segment ids closed by the session.
  final List<int> closedSegments = [];

  @override
  Future<Result<void>> load(String modelDirectory) async {
    loaded = true;
    loadedModelDirectory = modelDirectory;
    return loadResult;
  }

  @override
  Stream<RecognitionResult> get results => _results.stream;

  @override
  void acceptAudio(Float32List samples, int sampleRateHz, int startMs) {
    acceptedAudio.add(
      (samples: samples, sampleRateHz: sampleRateHz, startMs: startMs),
    );
  }

  @override
  void closeSegment(int segmentId) {
    closedSegments.add(segmentId);
    onCloseSegment?.call(segmentId);
  }

  /// Emits one result without closing the result stream.
  void emit(RecognitionResult result) => _results.add(result);

  /// Emits every scripted result, then closes the stream.
  Future<void> play() async {
    script.forEach(_results.add);
    await _results.close();
  }

  @override
  Future<void> dispose() async {
    if (!_results.isClosed) await _results.close();
  }
}
