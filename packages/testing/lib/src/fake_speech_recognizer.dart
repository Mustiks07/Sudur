import 'dart:async';
import 'dart:typed_data';

import 'package:contracts/contracts.dart';

/// A [SpeechRecognizer] that plays back prepared results instead of
/// recognizing audio (docs/tz СЛ-07, ПО-12: work on saved results).
final class FakeSpeechRecognizer implements SpeechRecognizer {
  /// Creates a recognizer that will emit [script] on [play].
  FakeSpeechRecognizer(this.script, {required this.info});

  /// Results to play, in order.
  final List<RecognitionResult> script;

  @override
  final RecognizerInfo info;

  final StreamController<RecognitionResult> _results =
      StreamController<RecognitionResult>();

  /// Whether [load] was called.
  bool loaded = false;

  @override
  Future<Result<void>> load(String modelDirectory) async {
    loaded = true;
    return const Result.ok(null);
  }

  @override
  Stream<RecognitionResult> get results => _results.stream;

  @override
  void acceptAudio(Float32List samples, int sampleRateHz, int startMs) {}

  @override
  void closeSegment(int segmentId) {}

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
