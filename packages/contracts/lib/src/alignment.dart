import 'package:contracts/src/search_key.dart';
import 'package:contracts/src/word_key.dart';
import 'package:meta/meta.dart';

// The alignment path is produced by `follow` and consumed by `check`
// (docs/tz 10.4, 10.5; ADR 0003).

/// A stable recognized word, numbered across the session.
@immutable
final class HeardWord {
  /// Creates a heard word.
  const HeardWord({
    required this.index,
    required this.text,
    required this.key,
    required this.segmentId,
    required this.atMs,
  });

  /// 0-based number of the word among all stable words of the session.
  final int index;

  /// The token exactly as recognized (docs/tz ПО-13).
  final String text;

  /// Its search key.
  final SearchKey key;

  /// Speech segment it came from.
  final int segmentId;

  /// End of the audio of the result where it became stable, in ms.
  final int atMs;
}

/// Kind of an alignment step (docs/tz section 10.4).
enum AlignmentStepKind {
  /// The heard word matched the next expected word.
  match,

  /// Expected words were skipped, then the heard word matched.
  skip,

  /// The reader went back and the heard word matched an earlier word.
  back,

  /// The heard word is extra: the position did not move.
  insert,

  /// The heard word was not aligned to the passage because the position
  /// was lost (it may belong to another place of the Quran).
  unaligned,
}

/// One step of the alignment path: what one heard word was taken for.
///
/// This is the input of `check`; following itself does not decide whether
/// the reading was correct (docs/tz СЛ-06).
@immutable
final class AlignmentStep {
  /// Creates a step.
  const AlignmentStep({
    required this.kind,
    required this.heard,
    required this.cost,
    this.expected,
    this.similarity,
    this.skipped = const [],
  });

  /// What happened.
  final AlignmentStepKind kind;

  /// The heard word, as recognized.
  final HeardWord heard;

  /// Cost of the step in the beam.
  final double cost;

  /// Expected word the heard word was matched to; `null` for [insert] and
  /// [unaligned] steps.
  ///
  /// [insert]: AlignmentStepKind.insert
  /// [unaligned]: AlignmentStepKind.unaligned
  final WordKey? expected;

  /// Similarity of the heard key and the expected key, if matched.
  final double? similarity;

  /// Expected words skipped before [expected], for skip steps.
  final List<WordKey> skipped;

  @override
  String toString() => 'AlignmentStep(${kind.name}, heard #${heard.index}, '
      'expected: $expected, skipped: $skipped)';
}

/// A possible jump to a place outside the passage, for `check` to confirm
/// (docs/tz СЛ-04, ПО-07). Words there are never revealed.
@immutable
final class JumpCandidate {
  /// Creates a candidate.
  const JumpCandidate({
    required this.to,
    required this.heard,
    required this.matchedNgrams,
    this.from,
  });

  /// Last confidently followed word in the passage, if any.
  final WordKey? from;

  /// Where in the Quran the heard words would start.
  final WordKey to;

  /// The heard words that were searched.
  final List<HeardWord> heard;

  /// How many n-grams matched there.
  final int matchedNgrams;
}
