import 'package:contracts/src/session_audio.dart';
import 'package:contracts/src/session_commands.dart';
import 'package:contracts/src/versions.dart';
import 'package:contracts/src/word_key.dart';
import 'package:meta/meta.dart';

/// How sure the following module is about the reading position.
enum PositionConfidence {
  /// The position is unambiguous.
  high,

  /// Several positions are possible until a distinguishing word is heard.
  low,
}

/// Why a hidden word became visible.
enum RevealReason {
  /// The word was heard.
  heard,

  /// The reader asked for a hint.
  hint,

  /// The word was revealed after a confirmed mistake, for example a skip.
  afterConfirm,
}

/// Kind of a check event (docs/tz section 10.5).
enum CheckKind {
  /// An expected word was skipped.
  omission,

  /// A different word was read instead of the expected one.
  substitution,

  /// An extra word was read.
  insertion,

  /// The reader moved to another place of the Quran.
  jump,

  /// The reader repeated words. A signal, not a mistake.
  repetition,

  /// A long pause inside an ayah. A signal, not a mistake.
  hesitation,
}

/// State of a check event (docs/tz section 10.5).
enum CheckState {
  /// Detected but not yet confirmed by enough context.
  preliminary,

  /// Confirmed mistake.
  confirmed,

  /// The reader corrected it within the self-correction window.
  corrected,

  /// Could not be verified, for example because of poor audio.
  unverified,

  /// The reader disagreed with the mistake.
  disputed,
}

/// Event emitted by a reading session to the UI (docs/tz section 4.5).
@immutable
sealed class SessionEvent {
  /// Creates a session event.
  const SessionEvent({required this.sessionId, required this.atMs});

  /// Reading session the event belongs to.
  final String sessionId;

  /// Time of the event, in milliseconds from session start.
  final int atMs;
}

/// The reader's current position changed.
final class PositionUpdate extends SessionEvent {
  /// Creates a position update.
  const PositionUpdate({
    required super.sessionId,
    required super.atMs,
    required this.word,
    required this.confidence,
    this.candidates = const [],
  });

  /// Most likely current word.
  final WordKey word;

  /// How sure the position is.
  final PositionConfidence confidence;

  /// Other possible positions when [confidence] is low.
  final List<WordKey> candidates;
}

/// A hidden word became visible.
///
/// Revealing a word does not mean it was read correctly; correctness comes
/// only from [CheckEvent] (docs/tz requirement СЛ-06).
final class WordRevealed extends SessionEvent {
  /// Creates a reveal event.
  const WordRevealed({
    required super.sessionId,
    required super.atMs,
    required this.word,
    required this.reason,
  });

  /// The revealed word.
  final WordKey word;

  /// Why it was revealed.
  final RevealReason reason;
}

/// The reading position was lost.
final class PositionLost extends SessionEvent {
  /// Creates a position-lost event.
  const PositionLost({
    required super.sessionId,
    required super.atMs,
    this.lastConfidentWord,
  });

  /// Last word the position was sure about, if any.
  final WordKey? lastConfidentWord;
}

/// A possible or confirmed reading mistake, or a signal such as hesitation.
final class CheckEvent extends SessionEvent {
  /// Creates a check event.
  const CheckEvent({
    required super.sessionId,
    required super.atMs,
    required this.eventId,
    required this.kind,
    required this.state,
    required this.words,
    required this.expectedText,
    required this.heardText,
    required this.audioStartMs,
    required this.audioEndMs,
    required this.versions,
    this.jumpTo,
  });

  /// Stable identifier of the event across state changes.
  final String eventId;

  /// What happened.
  final CheckKind kind;

  /// Current state.
  final CheckState state;

  /// Affected expected words.
  final List<WordKey> words;

  /// Expected canonical text of [words], for display only.
  final String expectedText;

  /// What was recognized, exactly as recognized.
  final String heardText;

  /// Where the reader jumped to, for [CheckKind.jump].
  final WordKey? jumpTo;

  /// Start of the related audio, in milliseconds from session start.
  final int audioStartMs;

  /// End of the related audio, in milliseconds from session start.
  final int audioEndMs;

  /// Model, rules and text versions the event was produced with (ПО-11).
  final ReadingVersions versions;
}

/// Level of the microphone signal (docs/tz 10.2).
enum SignalQualityLevel {
  /// The signal can be checked.
  ok,

  /// Speech stayed below `quietDbfs` for `signalHoldMs`.
  tooQuiet,

  /// More than `clippingRatio` of samples hit the limit within the window.
  clipping,

  /// The level in pauses stayed above `noisyDbfs` for `signalHoldMs`.
  noisy,
}

/// The signal level changed (docs/tz 4.5). Emitted by `audio_capture` when
/// the level differs from the previous one. While the level is not `ok`,
/// `check` leaves candidates there `unverified` (docs/tz 10.5).
final class SignalQuality extends SessionEvent implements SessionAudioEvent {
  /// Creates a signal quality event.
  const SignalQuality({
    required super.sessionId,
    required super.atMs,
    required this.level,
    this.sinceMs,
    this.dbfs,
    this.clippedRatio,
  });

  /// The new level; it holds until the next [SignalQuality].
  final SignalQualityLevel level;

  /// Start of the audio the level was measured on, if known. A level found
  /// after a hold time (for example 3 s of quiet speech) applies from here,
  /// not only from `atMs`; without it consumers use `atMs`.
  final int? sinceMs;

  /// RMS level of the measurement window, dBFS.
  final double? dbfs;

  /// Share of samples at the limit in the window.
  final double? clippedRatio;
}

/// A reading session was prepared and started.
final class SessionStarted extends SessionEvent {
  /// Creates a session-started event.
  const SessionStarted({
    required super.sessionId,
    required super.atMs,
    required this.fromWordKey,
    required this.toWordKey,
    required this.mode,
    required this.versions,
  });

  /// First word in the session, inclusive.
  final WordKey fromWordKey;

  /// Last word in the session, inclusive.
  final WordKey toWordKey;

  /// Reading mode selected for the session.
  final SessionMode mode;

  /// Model, rules and text versions used by the session.
  final ReadingVersions versions;
}

/// A requested hint was applied.
final class HintGiven extends SessionEvent {
  /// Creates a hint event.
  const HintGiven({
    required super.sessionId,
    required super.atMs,
    required this.kind,
    required this.wordKey,
  });

  /// Kind of hint that was applied.
  final HintKind kind;

  /// First word affected by the hint.
  final WordKey wordKey;
}

/// A check event moved to another state.
final class CheckStateChanged extends SessionEvent {
  /// Creates a check-state event.
  const CheckStateChanged({
    required super.sessionId,
    required super.atMs,
    required this.eventId,
    required this.from,
    required this.to,
    required this.reason,
  });

  /// Check event whose state changed.
  final String eventId;

  /// Previous state.
  final CheckState from;

  /// New state.
  final CheckState to;

  /// Stable machine-readable reason for the transition.
  final String reason;
}

/// Result of one word when a session finishes (docs/tz section 10.6).
enum SessionWordOutcome {
  /// The word was read without a recorded mistake or hint.
  read,

  /// The word was revealed or completed with a hint.
  readWithHint,

  /// A mistake affecting the word remained confirmed.
  error,

  /// The reader corrected a preliminary mistake.
  corrected,

  /// Audio or context was insufficient to check the word.
  unverified,

  /// The reader stopped before reaching the word; this is not a mistake.
  notRead,
}

/// Final result for one word in the requested range.
@immutable
final class SessionWordResult {
  /// Creates a word result.
  const SessionWordResult({required this.wordKey, required this.outcome});

  /// Word this result belongs to.
  final WordKey wordKey;

  /// Final outcome of the word.
  final SessionWordOutcome outcome;
}

/// Final aggregate emitted after the session reaches `finished`.
final class SessionFinished extends SessionEvent {
  /// Creates a session-finished event.
  const SessionFinished({
    required super.sessionId,
    required super.atMs,
    required this.words,
    required this.eventIds,
    required this.durationMs,
    required this.audioWasSuitable,
  });

  /// Exactly one result for every word in the requested range.
  final List<SessionWordResult> words;

  /// Check events produced during the session.
  final List<String> eventIds;

  /// Session duration in milliseconds.
  final int durationMs;

  /// Whether captured audio was suitable for checking.
  final bool audioWasSuitable;
}
