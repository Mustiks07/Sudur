/// Tunable audio parameters from specification section 12.4.
final class AudioCaptureConfig {
  /// Creates audio pipeline parameters.
  const AudioCaptureConfig({
    this.sampleRate = 16000,
    this.ringBufferSec = 30,
    this.preRollMs = 300,
    this.postRollMs = 300,
    this.segmentEndPauseMs = 300,
    this.maxSegmentMs = 15000,
    this.reviewSnippetPadMs = 3000,
    this.maxReviewSnippetBytes = 20 * 1024 * 1024,
    this.quietDbfs = -42,
    this.noisyDbfs = -35,
    this.clippingRatio = 0.01,
    this.signalHoldMs = 3000,
    this.signalWindowMs = 1000,
    this.vadThreshold = 0.5,
    this.vadMinSpeechMs = 250,
    this.vadMinSilenceMs = 10,
    this.vadWindowSize = 512,
    this.quietSplitWindowMs = 2000,
    this.captureFrameMs = 40,
  })  : assert(sampleRate > 0, 'sampleRate must be positive.'),
        assert(ringBufferSec > 0, 'ringBufferSec must be positive.'),
        assert(preRollMs >= 0, 'preRollMs must not be negative.'),
        assert(postRollMs >= 0, 'postRollMs must not be negative.'),
        assert(segmentEndPauseMs > 0, 'segmentEndPauseMs must be positive.'),
        assert(maxSegmentMs > 0, 'maxSegmentMs must be positive.'),
        assert(
          reviewSnippetPadMs >= 0,
          'Snippet padding must not be negative.',
        ),
        assert(
          maxReviewSnippetBytes > 0,
          'Review snippet memory limit must be positive.',
        ),
        assert(
          clippingRatio >= 0 && clippingRatio <= 1,
          'Invalid clipping ratio.',
        ),
        assert(signalHoldMs > 0, 'signalHoldMs must be positive.'),
        assert(signalWindowMs > 0, 'signalWindowMs must be positive.'),
        assert(vadThreshold > 0 && vadThreshold < 1, 'Invalid VAD threshold.'),
        assert(vadMinSpeechMs >= 0, 'VAD minimum speech must not be negative.'),
        assert(
          vadMinSilenceMs >= 0,
          'VAD minimum silence must not be negative.',
        ),
        assert(vadWindowSize > 0, 'VAD window must be positive.'),
        assert(quietSplitWindowMs > 0, 'Split search window must be positive.'),
        assert(
          captureFrameMs >= 20 && captureFrameMs <= 40,
          'Frame must be 20–40 ms.',
        );

  /// Deserializes configuration inside the worker isolate.
  factory AudioCaptureConfig.fromMessage(Map<String, Object?> value) =>
      AudioCaptureConfig(
        sampleRate: _int(value, 'sampleRate'),
        ringBufferSec: _int(value, 'ringBufferSec'),
        preRollMs: _int(value, 'preRollMs'),
        postRollMs: _int(value, 'postRollMs'),
        segmentEndPauseMs: _int(value, 'segmentEndPauseMs'),
        maxSegmentMs: _int(value, 'maxSegmentMs'),
        reviewSnippetPadMs: _int(value, 'reviewSnippetPadMs'),
        maxReviewSnippetBytes: _int(value, 'maxReviewSnippetBytes'),
        quietDbfs: _double(value, 'quietDbfs'),
        noisyDbfs: _double(value, 'noisyDbfs'),
        clippingRatio: _double(value, 'clippingRatio'),
        signalHoldMs: _int(value, 'signalHoldMs'),
        signalWindowMs: _int(value, 'signalWindowMs'),
        vadThreshold: _double(value, 'vadThreshold'),
        vadMinSpeechMs: _int(value, 'vadMinSpeechMs'),
        vadMinSilenceMs: _int(value, 'vadMinSilenceMs'),
        vadWindowSize: _int(value, 'vadWindowSize'),
        quietSplitWindowMs: _int(value, 'quietSplitWindowMs'),
        captureFrameMs: _int(value, 'captureFrameMs'),
      );

  /// PCM samples per second.
  final int sampleRate;

  /// In-memory ring capacity in seconds.
  final int ringBufferSec;

  /// Audio retained before detected speech.
  final int preRollMs;

  /// Audio retained after detected speech.
  final int postRollMs;

  /// Silence that closes a segment.
  final int segmentEndPauseMs;

  /// Maximum segment length.
  final int maxSegmentMs;

  /// Padding around requested review snippets.
  final int reviewSnippetPadMs;

  /// Maximum memory retained for event-centred review snippets.
  final int maxReviewSnippetBytes;

  /// Speech level threshold in dBFS.
  final double quietDbfs;

  /// Non-speech noise threshold in dBFS.
  final double noisyDbfs;

  /// Fraction of saturated samples that indicates clipping.
  final double clippingRatio;

  /// Duration a quiet/noisy condition must persist.
  final int signalHoldMs;

  /// Signal quality measurement window.
  final int signalWindowMs;

  /// Silero speech probability threshold.
  final double vadThreshold;

  /// Silero minimum speech duration.
  final int vadMinSpeechMs;

  /// Silero silence used only to release its speech state promptly.
  final int vadMinSilenceMs;

  /// Silero inference window size.
  final int vadWindowSize;

  /// Tail searched for the quietest forced split.
  final int quietSplitWindowMs;

  /// Requested microphone/file chunk duration.
  final int captureFrameMs;

  /// PCM16 bytes requested from `record` for one frame.
  int get streamBufferBytes => sampleRate * captureFrameMs ~/ 1000 * 2;

  /// Serializes configuration for the worker isolate.
  Map<String, Object?> toMessage() => <String, Object?>{
        'sampleRate': sampleRate,
        'ringBufferSec': ringBufferSec,
        'preRollMs': preRollMs,
        'postRollMs': postRollMs,
        'segmentEndPauseMs': segmentEndPauseMs,
        'maxSegmentMs': maxSegmentMs,
        'reviewSnippetPadMs': reviewSnippetPadMs,
        'maxReviewSnippetBytes': maxReviewSnippetBytes,
        'quietDbfs': quietDbfs,
        'noisyDbfs': noisyDbfs,
        'clippingRatio': clippingRatio,
        'signalHoldMs': signalHoldMs,
        'signalWindowMs': signalWindowMs,
        'vadThreshold': vadThreshold,
        'vadMinSpeechMs': vadMinSpeechMs,
        'vadMinSilenceMs': vadMinSilenceMs,
        'vadWindowSize': vadWindowSize,
        'quietSplitWindowMs': quietSplitWindowMs,
        'captureFrameMs': captureFrameMs,
      };
}

int _int(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! int) {
    throw FormatException('$key must be an integer.');
  }
  return field;
}

double _double(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! num) {
    throw FormatException('$key must be a number.');
  }
  return field.toDouble();
}
