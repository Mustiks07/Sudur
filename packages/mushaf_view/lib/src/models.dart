import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';

/// Supplies page layout data, independently of its storage implementation.
abstract interface class MushafLayoutSource {
  /// Loads one 1-based Mushaf page.
  Future<MushafPageData> loadPage(int pageNumber);
}

/// The visual role of a fragment in a Mushaf line.
enum MushafFragmentKind {
  /// A tappable Quran word identified by a [WordKey].
  word,

  /// An ayah-end sign, which remains visible when words are hidden.
  ayahEnd,

  /// A surah title, which remains visible when words are hidden.
  surahTitle,

  /// A basmala line, which remains visible when words are hidden.
  basmala,
}

/// One separately styled page-font fragment.
@immutable
final class MushafFragment {
  /// Creates a visual fragment.
  ///
  /// A word must have [wordKey]. Non-word fragments must not have one.
  const MushafFragment({
    required this.glyph,
    required this.kind,
    this.wordKey,
  }) : assert(
          (kind == MushafFragmentKind.word) == (wordKey != null),
          'Only word fragments have a WordKey',
        );

  /// The page-font glyph or glyph sequence used only for visual rendering.
  final String glyph;

  /// The semantic role of this fragment.
  final MushafFragmentKind kind;

  /// The stable Quran word identifier, present only for words.
  final WordKey? wordKey;

  /// Whether this fragment stays visible in hidden-word mode.
  bool get isAlwaysVisible => kind != MushafFragmentKind.word;
}

/// One visual line of a 15-line Mushaf page.
@immutable
final class MushafLineData {
  /// Creates a line from page-font fragments in logical reading order.
  const MushafLineData(this.fragments);

  /// The fragments rendered by the line's single text painter.
  final List<MushafFragment> fragments;
}

/// Canonical, non-glyph accessibility content for one ayah.
@immutable
final class MushafAyahSemantics {
  /// Creates accessibility content for an ayah.
  const MushafAyahSemantics({
    required this.surah,
    required this.ayah,
    required this.canonicalText,
  })  : assert(surah >= 1 && surah <= 114, 'surah must be in 1..114'),
        assert(ayah >= 1, 'ayah must be positive');

  /// The 1-based surah number.
  final int surah;

  /// The 1-based ayah number.
  final int ayah;

  /// Plain canonical ayah text, never derived from page-font glyphs.
  final String canonicalText;
}

/// Complete render data for one 15-line Mushaf page.
@immutable
final class MushafPageData {
  /// Creates a page.
  const MushafPageData({
    required this.pageNumber,
    required this.lines,
    required this.ayahSemantics,
  })  : assert(pageNumber >= 1, 'pageNumber must be positive'),
        assert(lines.length == 15, 'A Mushaf page must contain 15 lines');

  /// The 1-based page number.
  final int pageNumber;

  /// Exactly 15 visual lines.
  final List<MushafLineData> lines;

  /// Canonical accessibility nodes in reading order.
  final List<MushafAyahSemantics> ayahSemantics;
}

/// The visual state of an open or hidden word.
enum MushafWordState {
  /// Default word styling.
  normal,

  /// Transparent text with preserved layout metrics.
  hidden,

  /// The word currently being recited.
  current,

  /// A word recognized as correct.
  correct,

  /// A word that may contain an error.
  possibleError,

  /// A confirmed error.
  error,

  /// A previously wrong word that was corrected.
  corrected,

  /// A word for which recognition had insufficient evidence.
  notHeard,

  /// A word revealed by a hint.
  revealedByHint,
}
