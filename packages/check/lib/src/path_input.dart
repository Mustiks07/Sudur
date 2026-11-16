import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';
import 'package:quran_text/quran_text.dart';

// Input of check: the final alignment path of `follow` (docs/tz 10.4).
// `check` may depend only on `contracts` and `quran_text` (AGENTS.md), so
// the path has its own types here; the session copies follow's
// `AlignmentStep`, `HeardWord` and `JumpCandidate` into them field by field.
// Moving these types to `contracts` needs an ADR.

/// A stable recognized word, numbered across the session.
@immutable
final class PathWord {
  /// Creates a heard word.
  const PathWord({
    required this.index,
    required this.text,
    required this.key,
    required this.atMs,
  });

  /// 0-based number among all stable words of the session.
  final int index;

  /// Exactly as recognized (docs/tz ПО-13).
  final String text;

  /// Search key.
  final SearchKey key;

  /// Time of the word, ms from session start.
  final int atMs;
}

/// Kind of a path step; the same as in `follow`.
enum PathStepKind {
  /// Matched the next expected word.
  match,

  /// Skipped expected words, then matched.
  skip,

  /// Went back and matched an earlier word.
  back,

  /// An extra word.
  insert,

  /// Not aligned: the position was lost.
  unaligned,
}

/// One final step of the alignment path.
@immutable
final class PathStep {
  /// Creates a step.
  const PathStep({
    required this.kind,
    required this.heard,
    this.expected,
    this.similarity,
    this.skipped = const [],
  });

  /// What happened.
  final PathStepKind kind;

  /// The heard word.
  final PathWord heard;

  /// Matched expected word, for match, skip and back.
  final WordKey? expected;

  /// Similarity of heard and expected keys.
  final double? similarity;

  /// Skipped expected words, for skip.
  final List<WordKey> skipped;
}

/// Heard words that fit another place of the Quran.
@immutable
final class JumpInput {
  /// Creates a jump input.
  const JumpInput({
    required this.to,
    required this.heard,
    required this.matchedNgrams,
    this.from,
  });

  /// Last confidently followed word, if any.
  final WordKey? from;

  /// Where the heard words would start.
  final WordKey to;

  /// The heard words.
  final List<PathWord> heard;

  /// How many n-grams matched there.
  final int matchedNgrams;
}
