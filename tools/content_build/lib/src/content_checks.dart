import 'package:content_build/src/build_config.dart';
import 'package:content_build/src/canon_checksum.dart';
import 'package:content_build/src/content_build_exception.dart';
import 'package:content_build/src/layout_parser.dart';
import 'package:content_build/src/tanzil_parser.dart';
import 'package:content_build/src/word_segmenter.dart';

/// Checks of docs/tz requirement ПР-04 on the whole canonical text.
///
/// Returns human-readable failures; an empty list means all checks passed.
List<String> checkCanon(TanzilQuran quran, BuildConfig config) {
  final failures = <String>[];
  if (quran.surahs.length != config.expectedSurahCount) {
    failures.add(
      'Expected ${config.expectedSurahCount} surahs, '
      'source has ${quran.surahs.length}.',
    );
  }
  if (quran.ayahCount != config.expectedAyahCount) {
    failures.add(
      'Expected ${config.expectedAyahCount} ayahs, '
      'source has ${quran.ayahCount}.',
    );
  }
  final checksum = canonChecksum(quran);
  if (checksum != config.expectedCanonSha256) {
    failures.add(
      'Canon checksum $checksum differs from the pinned '
      '${config.expectedCanonSha256}. The source text changed: a specialist '
      'must review it before the pin is updated (ПР-03).',
    );
  }
  for (final surah in quran.surahs) {
    for (final ayah in surah.ayahs) {
      try {
        final words = segmentAyah(ayah.text);
        if (words.join(tanzilTokenSeparator) != ayah.text) {
          failures
              .add('Segmentation of ${surah.index}:${ayah.index} is lossy.');
        }
      } on ContentBuildException catch (e) {
        failures.add('${surah.index}:${ayah.index}: ${e.message}');
      }
    }
  }
  return failures;
}

/// Checks of docs/tz requirement ПР-04 on the layout of the build scope:
/// ayah and word counts match the text source, and every glyph has a page,
/// a line and a glyph code.
List<String> checkLayout({
  required TanzilQuran quran,
  required List<LayoutVerse> verses,
  required Map<int, LayoutChapter> chapters,
  required BuildConfig config,
}) {
  final failures = <String>[];
  final scopePages = config.pages.toSet();

  for (final surah in verses.map((v) => v.surah).toSet()) {
    final chapter = chapters[surah];
    if (chapter == null) {
      failures.add('No chapter metadata for surah $surah.');
      continue;
    }
    final textCount = quran.surah(surah).ayahs.length;
    if (chapter.ayahCount != textCount) {
      failures.add(
        'Surah $surah: layout source has ${chapter.ayahCount} ayahs, '
        'text source has $textCount.',
      );
    }
  }

  for (final verse in verses) {
    final key = '${verse.surah}:${verse.ayah}';
    final surah = quran.surah(verse.surah);
    if (verse.ayah > surah.ayahs.length) {
      failures.add('Layout has ayah $key that the text source lacks.');
      continue;
    }
    final textWords = segmentAyah(surah.ayahs[verse.ayah - 1].text).length;
    final layoutWords = verse.words.length;
    if (textWords != layoutWords) {
      failures.add(
        'Ayah $key: text source has $textWords words, '
        'layout source has $layoutWords.',
      );
    }
    final positions = [for (final t in verse.tokens) t.position];
    final expectedPositions = [for (var i = 1; i <= positions.length; i++) i];
    if (positions.join(',') != expectedPositions.join(',')) {
      failures.add('Ayah $key: glyph positions are not 1..n in order.');
    }
    final ends = verse.tokens.where((t) => t.kind == LayoutTokenKind.ayahEnd);
    if (ends.length != 1 || verse.tokens.last.kind != LayoutTokenKind.ayahEnd) {
      failures.add('Ayah $key: expected exactly one ayah-end marker, last.');
    }
    for (final token in verse.tokens) {
      final where = '$key:${token.position}';
      if (!scopePages.contains(token.page)) {
        failures.add('Glyph $where is on page ${token.page}, outside scope.');
      }
      if (token.line < 1 || token.line > config.linesPerPage) {
        failures.add('Glyph $where has line ${token.line}.');
      }
      if (token.glyphCode.isEmpty) {
        failures.add('Glyph $where has no glyph code.');
      }
    }
  }
  return failures;
}
