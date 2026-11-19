/// Lifecycle phase from docs/tz section 10.6.
enum ReadingSessionPhase {
  /// No session has started.
  idle,

  /// Model, text range and audio are being prepared.
  preparing,

  /// Audio is active and the session is waiting for speech.
  ready,

  /// Speech is being processed.
  listening,

  /// Processing is paused while the current position is retained.
  paused,

  /// Open recognition and preliminary checks are being completed.
  finishing,

  /// The final summary was emitted.
  finished,

  /// Voice checking cannot continue normally.
  error,
}

/// Error shown by the reading screen (docs/tz section 10.6).
enum ReadingSessionError {
  /// The recognition model is absent or could not be loaded.
  modelMissing,

  /// Microphone access is unavailable.
  micDenied,

  /// Recognition is slower than three times its audio window.
  deviceTooSlow,
}

/// Observable reading-session state.
final class ReadingSessionState {
  /// Creates a state.
  const ReadingSessionState(this.phase, {this.error});

  /// Initial idle state.
  static const idle = ReadingSessionState(ReadingSessionPhase.idle);

  /// Current lifecycle phase.
  final ReadingSessionPhase phase;

  /// Error kind when [phase] is [ReadingSessionPhase.error].
  final ReadingSessionError? error;
}

/// A rejected session command or failed session operation.
final class ReadingSessionException implements Exception {
  /// Creates an exception safe to show in diagnostics without user content.
  const ReadingSessionException(this.code, this.message);

  /// Stable machine-readable code.
  final String code;

  /// Description without audio or recognized text.
  final String message;

  @override
  String toString() => 'ReadingSessionException($code): $message';
}
