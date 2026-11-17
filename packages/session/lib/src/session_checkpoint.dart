import 'package:contracts/contracts.dart';
import 'package:session/src/session_state.dart';

/// Minimal resumable state persisted without audio or recognized text.
final class SessionCheckpoint {
  /// Creates a checkpoint.
  const SessionCheckpoint({
    required this.sessionId,
    required this.fromWordKey,
    required this.toWordKey,
    required this.mode,
    required this.behavior,
    required this.phase,
    required this.atMs,
    this.lastPosition,
  });

  /// Reading session identifier.
  final String sessionId;

  /// First requested word, inclusive.
  final WordKey fromWordKey;

  /// Last requested word, inclusive.
  final WordKey toWordKey;

  /// Reading mode.
  final SessionMode mode;

  /// Mistake handling behavior.
  final SessionBehavior behavior;

  /// Session phase at the time of persistence.
  final ReadingSessionPhase phase;

  /// Latest audio timeline position.
  final int atMs;

  /// Last position reported by `follow`, if any.
  final WordKey? lastPosition;
}

/// Persists crash-recovery checkpoints (НФ-21).
abstract interface class SessionCheckpointStore {
  /// Saves or replaces the checkpoint for its session.
  Future<Result<void>> save(SessionCheckpoint checkpoint);
}
