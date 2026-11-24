import 'dart:async';
import 'dart:typed_data';

import 'package:contracts/contracts.dart';
import 'package:testing/src/model_output.dart';

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

  /// A recognizer that plays only text the model could output: the 29
  /// bare letters of docs/tz 12.3 ([isModelOutput]). Throws an
  /// [ArgumentError] for a result that holds anything else — for example
  /// canonical search keys with harakat.
  factory FakeSpeechRecognizer.modelOutput(
    List<RecognitionResult> script, {
    required RecognizerInfo info,
    Result<void> loadResult = const Result<void>.ok(null),
    void Function(int segmentId)? onCloseSegment,
  }) {
    for (final r in script) {
      if (!isModelOutput(r.text)) {
        throw ArgumentError.value(
          r.segmentId,
          'segment',
          'result text is not model output (docs/tz 12.3)',
        );
      }
    }
    return FakeSpeechRecognizer(
      script,
      info: info,
      loadResult: loadResult,
      onCloseSegment: onCloseSegment,
    );
  }

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
