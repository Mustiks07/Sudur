/// A safe audio failure that contains neither audio nor recognized text.
final class AudioCaptureException implements Exception {
  /// Creates an audio pipeline failure.
  const AudioCaptureException(this.code, this.message);

  /// Stable machine-readable error code.
  final String code;

  /// Safe user-facing or diagnostic message.
  final String message;

  @override
  String toString() => 'AudioCaptureException($code, $message)';
}
