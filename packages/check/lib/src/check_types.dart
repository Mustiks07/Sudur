import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';

/// Versions stored with every check event (docs/tz ПО-11).
///
/// `CheckEvent` in `contracts` has no field for them, so they travel next
/// to the event in [CheckOutput]; adding the field to the contract needs an
/// ADR.
@immutable
final class CheckVersions {
  /// Creates versions.
  const CheckVersions({
    required this.modelId,
    required this.modelVersion,
    required this.rulesVersion,
    required this.textVersion,
  });

  /// Recognition model id.
  final String modelId;

  /// Recognition model version.
  final String modelVersion;

  /// Version of the check rules and thresholds.
  final String rulesVersion;

  /// Version of the content (canonical text) package.
  final String textVersion;

  /// JSON form for `check_event.versions` (docs/tz 12.1).
  Map<String, String> toJson() => {
        'model': '$modelId@$modelVersion',
        'rules': rulesVersion,
        'text': textVersion,
      };
}

/// A check event with the versions it was produced with.
@immutable
final class CheckOutput {
  /// Creates an output.
  const CheckOutput(this.event, this.versions);

  /// The event; a state change is a new event with the same `eventId`.
  final CheckEvent event;

  /// Versions of model, rules and text (docs/tz ПО-11).
  final CheckVersions versions;
}

/// A pause between words, from voice activity detection.
@immutable
final class SpeechPause {
  /// Creates a pause.
  const SpeechPause({required this.startMs, required this.endMs});

  /// Start, ms from session start.
  final int startMs;

  /// End, ms from session start.
  final int endMs;

  /// Length in ms.
  int get durationMs => endMs - startMs;
}

/// Why a stretch of audio cannot be trusted.
enum UnreliableReason {
  /// `SignalQuality` was not `ok` (too quiet, clipping, noisy).
  poorSignal,

  /// Recognition was late (`deviceTooSlow`).
  deviceTooSlow,
}

/// A stretch of audio where no candidate may be confirmed (docs/tz 10.5
/// «Плохой сигнал»).
@immutable
final class UnreliableSpan {
  /// Creates a span.
  const UnreliableSpan({
    required this.startMs,
    required this.endMs,
    required this.reason,
  });

  /// Start, ms.
  final int startMs;

  /// End, ms.
  final int endMs;

  /// Why.
  final UnreliableReason reason;

  /// Whether the span overlaps [startMs]..[endMs].
  bool overlaps(int start, int end) => startMs <= end && start <= endMs;
}

/// Strict behavior signals for the session (docs/tz 10.5, ЭЧ-05).
@immutable
sealed class StrictSignal {
  const StrictSignal({required this.word, required this.atMs});

  /// The word the reader must read.
  final WordKey word;

  /// When, ms.
  final int atMs;
}

/// Stop revealing words after [word] until it is read or a hint is taken.
final class WaitForWord extends StrictSignal {
  /// Creates the signal.
  const WaitForWord({required super.word, required super.atMs});
}

/// Offer a hint for [word]: too many failed tries or too long a wait.
final class OfferHint extends StrictSignal {
  /// Creates the signal.
  const OfferHint({required super.word, required super.atMs});
}

/// How a strict wait ended.
enum WaitEnd {
  /// The word was read with a strong match.
  read,

  /// The reader took a hint.
  hint,
}

/// The wait for [word] is over; revealing may go on.
final class StopWaiting extends StrictSignal {
  /// Creates the signal.
  const StopWaiting({
    required super.word,
    required super.atMs,
    required this.how,
  });

  /// How it ended.
  final WaitEnd how;
}

/// What checking produced for one input.
@immutable
final class CheckUpdate {
  /// Creates an update.
  const CheckUpdate({this.events = const [], this.strict = const []});

  /// New events and state changes, in order.
  final List<CheckOutput> events;

  /// Strict behavior signals, in order.
  final List<StrictSignal> strict;

  /// Whether nothing happened.
  bool get isEmpty => events.isEmpty && strict.isEmpty;
}
