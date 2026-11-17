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
final class SignalQuality extends SessionEvent {
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
