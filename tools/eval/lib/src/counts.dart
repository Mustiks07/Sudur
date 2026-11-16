import 'package:contracts/contracts.dart';
import 'package:eval/src/annotation.dart';
import 'package:meta/meta.dart';

/// What following and checking produced for one recording.
@immutable
final class RecordingOutcome {
  /// Creates an outcome.
  const RecordingOutcome({required this.revealed, this.checkEvents});

  /// Words revealed because they were heard.
  final Set<WordKey> revealed;

  /// All check events in order, or `null` if checking did not run (then
  /// check metrics have no data).
  final List<CheckEvent>? checkEvents;
}

/// Kinds of check events that are reading mistakes (docs/tz ПО-01).
const Set<CheckKind> mistakeKinds = {
  CheckKind.omission,
  CheckKind.substitution,
  CheckKind.insertion,
  CheckKind.jump,
};

/// Numerators and denominators of the docs/tz 5.3 metrics for a set of
/// recordings. Counts add up, so metrics of any group, and of bootstrap
/// samples, come from summed counts.
@immutable
final class Counts {
  /// Creates counts; every field defaults to zero.
  const Counts({
    this.readCleanly = 0,
    this.revealedReadCleanly = 0,
    this.revealed = 0,
    this.revealedNotRead = 0,
    this.hasCheck = false,
    this.confirmed = 0,
    this.confirmedTrue = 0,
    this.omitted = 0,
    this.omittedFound = 0,
    this.substituted = 0,
    this.substitutedFound = 0,
    this.normalWords = 0,
    this.normalUnverified = 0,
    this.selfCorrected = 0,
    this.selfCorrectedFound = 0,
  });

  /// Sum of many counts; the sum of none has check data vacuously.
  factory Counts.sum(Iterable<Counts> all) =>
      all.fold(const Counts(hasCheck: true), (a, b) => a + b);

  /// Counts one recording.
  ///
  /// Words marked `unclear` are left out everywhere. [normalNoise] are the
  /// noise conditions of "recordings of normal quality" (docs/tz КЧ-06).
  /// Insertions and jumps are matched to annotated spans by time, with
  /// [timeToleranceMs] slack.
  factory Counts.of(
    Annotation annotation,
    RecordingOutcome outcome, {
    required Set<String> normalNoise,
    required int timeToleranceMs,
  }) {
    final words = {
      for (final w in annotation.words)
        if (w.status != WordStatus.unclear) w.key: w,
    };
    final unclear = {
      for (final w in annotation.words)
        if (w.status == WordStatus.unclear) w.key,
    };
    final revealed = outcome.revealed.difference(unclear);

    final counts = Counts(
      readCleanly: words.values.where((w) => w.readCleanly).length,
      revealedReadCleanly: words.values
          .where((w) => w.readCleanly && revealed.contains(w.key))
          .length,
      revealed: revealed.length,
      revealedNotRead:
          revealed.where((k) => !(words[k]?.wasRead ?? false)).length,
    );

    final events = outcome.checkEvents;
    if (events == null) return counts;

    // The last state of every event counts.
    final finals = <String, CheckEvent>{};
    for (final e in events) {
      finals[e.eventId] = e;
    }
    final confirmed = finals.values
        .where(
          (e) =>
              mistakeKinds.contains(e.kind) &&
              (e.state == CheckState.confirmed ||
                  e.state == CheckState.disputed),
        )
        .toList();

    bool overlaps(CheckEvent e, List<AnnotatedSpan> spans) => spans.any(
          (s) =>
              s.startMs <= e.audioEndMs + timeToleranceMs &&
              e.audioStartMs <= s.endMs + timeToleranceMs,
        );

    bool isTrue(CheckEvent e) => switch (e.kind) {
          CheckKind.omission || CheckKind.substitution => e.words.any(
              (k) => words[k]?.isMistake ?? false,
            ),
          CheckKind.insertion => overlaps(e, annotation.insertions),
          CheckKind.jump => overlaps(e, annotation.jumps),
          CheckKind.repetition || CheckKind.hesitation => false,
        };

    final flagged = {
      for (final e in confirmed)
        if (e.kind == CheckKind.omission || e.kind == CheckKind.substitution)
          ...e.words,
    };
    Set<WordKey> inState(CheckState state) => {
          for (final e in finals.values)
            if (e.state == state) ...e.words,
        };
    final unverified = inState(CheckState.unverified);
    final corrected = inState(CheckState.corrected);
    final normal = normalNoise.contains(annotation.noise);

    List<AnnotatedWord> withStatus(WordStatus s) =>
        words.values.where((w) => w.status == s).toList();
    final omitted = withStatus(WordStatus.omitted);
    final substituted = withStatus(WordStatus.substituted);
    final selfCorrected = withStatus(WordStatus.selfCorrected);

    return Counts(
      readCleanly: counts.readCleanly,
      revealedReadCleanly: counts.revealedReadCleanly,
      revealed: counts.revealed,
      revealedNotRead: counts.revealedNotRead,
      hasCheck: true,
      confirmed: confirmed.length,
      confirmedTrue: confirmed.where(isTrue).length,
      omitted: omitted.length,
      omittedFound: omitted.where((w) => flagged.contains(w.key)).length,
      substituted: substituted.length,
      substitutedFound:
          substituted.where((w) => flagged.contains(w.key)).length,
      normalWords: normal ? words.length : 0,
      normalUnverified:
          normal ? words.keys.where(unverified.contains).length : 0,
      selfCorrected: selfCorrected.length,
      selfCorrectedFound:
          selfCorrected.where((w) => corrected.contains(w.key)).length,
    );
  }

  /// Words read correctly without trouble (status correct or repeated).
  final int readCleanly;

  /// Of [readCleanly], those revealed (docs/tz КЧ-01).
  final int revealedReadCleanly;

  /// All revealed words.
  final int revealed;

  /// Revealed words that were not read: omitted, substituted, or not in the
  /// annotation at all (docs/tz КЧ-02).
  final int revealedNotRead;

  /// Whether checking ran for every counted recording.
  final bool hasCheck;

  /// Confirmed mistake events.
  final int confirmed;

  /// Of [confirmed], those at a true mistake (docs/tz КЧ-03).
  final int confirmedTrue;

  /// Omitted words.
  final int omitted;

  /// Of [omitted], those flagged by a confirmed omission or substitution.
  final int omittedFound;

  /// Substituted words.
  final int substituted;

  /// Of [substituted], those flagged by a confirmed omission or
  /// substitution.
  final int substitutedFound;

  /// Words of recordings of normal quality.
  final int normalWords;

  /// Of [normalWords], those in an `unverified` event (docs/tz КЧ-06).
  final int normalUnverified;

  /// Self-corrected words.
  final int selfCorrected;

  /// Of [selfCorrected], those in a `corrected` event (docs/tz КЧ-07).
  final int selfCorrectedFound;

  /// False alarms: confirmed mistakes that are not true mistakes.
  int get falseAlarms => confirmed - confirmedTrue;

  /// Sum of two counts. Check data stays only if both have it.
  Counts operator +(Counts o) => Counts(
        readCleanly: readCleanly + o.readCleanly,
        revealedReadCleanly: revealedReadCleanly + o.revealedReadCleanly,
        revealed: revealed + o.revealed,
        revealedNotRead: revealedNotRead + o.revealedNotRead,
        hasCheck: hasCheck && o.hasCheck,
        confirmed: confirmed + o.confirmed,
        confirmedTrue: confirmedTrue + o.confirmedTrue,
        omitted: omitted + o.omitted,
        omittedFound: omittedFound + o.omittedFound,
        substituted: substituted + o.substituted,
        substitutedFound: substitutedFound + o.substitutedFound,
        normalWords: normalWords + o.normalWords,
        normalUnverified: normalUnverified + o.normalUnverified,
        selfCorrected: selfCorrected + o.selfCorrected,
        selfCorrectedFound: selfCorrectedFound + o.selfCorrectedFound,
      );
}
