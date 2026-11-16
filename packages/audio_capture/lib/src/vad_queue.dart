import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Drops completed native VAD segments after their state has been consumed.
int discardCompletedVadSegments(sherpa.VoiceActivityDetector vad) {
  var discarded = 0;
  while (!vad.isEmpty()) {
    vad.pop();
    discarded++;
  }
  return discarded;
}
