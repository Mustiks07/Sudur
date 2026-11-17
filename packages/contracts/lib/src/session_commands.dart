import 'package:contracts/src/word_key.dart';
import 'package:meta/meta.dart';

/// Reading mode selected for a session (docs/tz section 4.5).
enum SessionMode {
  /// The text is visible and the learner reads with support.
  supported,

  /// The learner recalls text that may be hidden.
  recall,

  /// The learner is checked without reading support.
  test,
}

/// How strictly the session reacts to a confirmed mistake.
enum SessionBehavior {
  /// Keep following after a mistake.
  gentle,

  /// Wait for the expected word or a hint after a mistake.
  strict,
}

/// Kind of help requested by the reader (docs/tz section 10.6).
enum HintKind {
  /// Reveal the first letter of the next word.
  firstLetter,

  /// Reveal the next word.
  word,

  /// Reveal the first word of the next ayah.
  nextAyahStart,

  /// Reveal the current ayah.
  wholeAyah,
}

/// Command sent by the reading screen to a session.
@immutable
sealed class SessionCommand {
  /// Creates a session command.
  const SessionCommand();
}

/// Starts a reading session for an inclusive word range.
final class StartSession extends SessionCommand {
  /// Creates a start command.
  const StartSession({
    required this.fromWordKey,
    required this.toWordKey,
    required this.mode,
    required this.behavior,
  });

  /// First word in the session, inclusive.
  final WordKey fromWordKey;

  /// Last word in the session, inclusive.
  final WordKey toWordKey;

  /// Reading mode.
  final SessionMode mode;

  /// Mistake handling behavior.
  final SessionBehavior behavior;
}

/// Pauses an active session without losing its position.
final class Pause extends SessionCommand {
  /// Creates a pause command.
  const Pause();
}

/// Resumes a paused session.
final class Resume extends SessionCommand {
  /// Creates a resume command.
  const Resume();
}

/// Finishes a session at its current position.
final class Stop extends SessionCommand {
  /// Creates a stop command.
  const Stop();
}

/// Requests a reading hint.
final class RequestHint extends SessionCommand {
  /// Creates a hint command.
  const RequestHint({required this.kind});

  /// Requested kind of hint.
  final HintKind kind;
}

/// Marks a check event as disputed by the reader.
final class DisputeEvent extends SessionCommand {
  /// Creates a dispute command.
  const DisputeEvent({required this.eventId});

  /// Check event to dispute.
  final String eventId;
}
