import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';

/// What following produced for one recognition result.
@immutable
final class FollowUpdate {
  /// Creates an update.
  const FollowUpdate({
    this.events = const [],
    this.path = const [],
    this.jumps = const [],
  });

  /// `PositionUpdate`, `WordRevealed` and `PositionLost` events, in order.
  final List<SessionEvent> events;

  /// Alignment steps that became final, in heard order. Final steps never
  /// change later.
  final List<AlignmentStep> path;

  /// Jump candidates found while the position was lost.
  final List<JumpCandidate> jumps;

  /// Whether nothing happened.
  bool get isEmpty => events.isEmpty && path.isEmpty && jumps.isEmpty;
}
