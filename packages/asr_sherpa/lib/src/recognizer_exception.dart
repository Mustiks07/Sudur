/// A safe recognizer failure that never includes audio or recognized text.
final class SherpaRecognizerException implements Exception {
  /// Creates a recognizer failure.
  const SherpaRecognizerException(this.code, this.message);

  /// Stable machine-readable error code.
  final String code;

  /// Safe diagnostic message.
  final String message;

  @override
  String toString() => 'SherpaRecognizerException($code, $message)';
}
