import 'package:content_build/src/build_config.dart';
import 'package:content_build/src/content_build_exception.dart';
import 'package:content_build/src/content_model.dart';
import 'package:content_build/src/layout_parser.dart';
import 'package:content_build/src/tanzil_parser.dart';
import 'package:content_build/src/word_segmenter.dart';

/// Merges verses of several page responses: an ayah that spans two pages
/// can appear in both. Glyphs at the same position must agree.
List<LayoutVerse> mergeLayoutVerses(Iterable<LayoutVerse> verses) {
  final byKey = <(int, int), LayoutVerse>{};
  for (final verse in verses) {
    final key = (verse.surah, verse.ayah);
    final known = byKey[key];
    if (known == null) {
      byKey[key] = verse;
      continue;
    }
    final tokens = {for (final t in known.tokens) t.position: t};
    for (final t in verse.tokens) {
      final other = tokens[t.position];
      if (other != null &&
          (other.kind != t.kind ||
              other.page != t.page ||
              other.line != t.line ||
              other.glyphCode != t.glyphCode)) {
        throw ContentBuildException(
          'Conflicting glyphs for ${verse.surah}:${verse.ayah}:${t.position}.',
        );
      }
      tokens[t.position] = t;
    }
    final positions = tokens.keys.toList()..sort();
    byKey[key] = LayoutVerse(
      surah: known.surah,
      ayah: known.ayah,
      juz: known.juz,
      hizb: known.hizb,
      sajda: known.sajda,
      tokens: [for (final p in positions) tokens[p]!], // key from `positions`.
    );
  }
  final keys = byKey.keys.toList()
    ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  return [for (final k in keys) byKey[k]!]; // key from `byKey.keys`.
}

/// Builds the content tables from verified sources.
///
/// Call only after `checkCanon` and `checkLayout` returned no failures; a
/// violated assumption still throws [ContentBuildException] instead of
/// producing wrong data.
ContentData assembleContent({
  required BuildConfig config,
  required TanzilQuran quran,
  required List<LayoutVerse> verses,
  required Map<int, LayoutChapter> chapters,
  required Map<String, String> version,
}) {
  final firstWordIndex = _firstWordIndexes(quran);

  // Number glyphs within each line in reading order.
  final lineGlyphs = <(int, int), int>{};
  final linePositions = <(int, int, int), int>{};
  for (final verse in verses) {
    for (final token in verse.tokens) {
      final line = (token.page, token.line);
      final position = (lineGlyphs[line] ?? 0) + 1;
      lineGlyphs[line] = position;
      linePositions[(verse.surah, verse.ayah, token.position)] = position;
    }
  }

  GlyphPlace placeOf(LayoutVerse verse, LayoutToken token) => GlyphPlace(
        page: token.page,
        line: token.line,
        linePosition: linePositions[(verse.surah, verse.ayah, token.position)]!,
        glyphCode: token.glyphCode,
      ); // Every token was numbered in the loop above.

  final ayahs = <AyahRow>[];
  final words = <WordRow>[];
  for (final verse in verses) {
    final text = quran.surah(verse.surah).ayahs[verse.ayah - 1].text;
    final canonWords = segmentAyah(text);
    final layoutWords = verse.words.toList();
    if (canonWords.length != layoutWords.length) {
      throw ContentBuildException(
        'Word count mismatch in ${verse.surah}:${verse.ayah}.',
      );
    }
    final first = firstWordIndex[(verse.surah, verse.ayah)]!; // Whole text.
    for (var i = 0; i < canonWords.length; i++) {
      words.add(
        WordRow(
          wordIndex: first + i,
          surah: verse.surah,
          ayah: verse.ayah,
          position: i + 1,
          textUthmani: canonWords[i],
          place: placeOf(verse, layoutWords[i]),
        ),
      );
    }
    final end = verse.tokens.last;
    ayahs.add(
      AyahRow(
        surah: verse.surah,
        ayah: verse.ayah,
        firstWordIndex: first,
        wordCount: canonWords.length,
        page: layoutWords.first.page,
        juz: verse.juz,
        hizb: verse.hizb,
        sajda: verse.sajda,
        end: placeOf(verse, end),
      ),
    );
  }

  final surahs = [
    for (final number in verses.map((v) => v.surah).toSet())
      SurahRow(
        number: number,
        nameAr: quran.surah(number).name,
        ayahCount: quran.surah(number).ayahs.length,
        revelation: chapters[number]!.revelation, // Checked by checkLayout.
      ),
  ];

  return ContentData(
    version: version,
    surahs: surahs,
    ayahs: ayahs,
    words: words,
    pages: _pages(config, words),
    lines: _lines(config, quran, verses, words),
  );
}

Map<(int, int), int> _firstWordIndexes(TanzilQuran quran) {
  final result = <(int, int), int>{};
  var next = 1;
  for (final surah in quran.surahs) {
    for (final ayah in surah.ayahs) {
      result[(surah.index, ayah.index)] = next;
      next += segmentAyah(ayah.text).length;
    }
  }
  return result;
}

List<PageRow> _pages(BuildConfig config, List<WordRow> words) => [
      for (final page in config.pages)
        () {
          final onPage = words.where((w) => w.place.page == page).toList();
          if (onPage.isEmpty) {
            throw ContentBuildException('Page $page has no words.');
          }
          return PageRow(
            number: page,
            layoutId: config.layoutId,
            firstWordIndex: onPage.first.wordIndex,
            lastWordIndex: onPage.last.wordIndex,
          );
        }(),
    ];

/// Lines with glyphs are ayah lines. Lines without glyphs must be the
/// header of the surah that starts on the next non-empty line: its name,
/// then the basmala if the text source gives one. Anything else fails the
/// build rather than guessing.
List<LineRow> _lines(
  BuildConfig config,
  TanzilQuran quran,
  List<LayoutVerse> verses,
  List<WordRow> words,
) {
  final rows = <LineRow>[];
  for (final page in config.pages) {
    final wordsByLine = <int, List<WordRow>>{};
    for (final w in words.where((w) => w.place.page == page)) {
      (wordsByLine[w.place.line] ??= []).add(w);
    }
    final glyphLines = {
      for (final v in verses)
        for (final t in v.tokens)
          if (t.page == page) t.line,
    };

    final kinds = <int, (LineKind, int?)>{};
    var line = 1;
    while (line <= config.linesPerPage) {
      if (glyphLines.contains(line)) {
        kinds[line] = (LineKind.ayah, null);
        line++;
        continue;
      }
      var next = line;
      while (next <= config.linesPerPage && !glyphLines.contains(next)) {
        next++;
      }
      final header = _header(quran, page, line, next, wordsByLine[next]);
      for (var i = 0; i < header.length; i++) {
        kinds[line + i] = (header[i], wordsByLine[next]!.first.surah);
      } // `_header` verified that line `next` has words.
      line = next;
    }

    for (var l = 1; l <= config.linesPerPage; l++) {
      final (kind, surah) = kinds[l]!; // Every line was classified above.
      final onLine = wordsByLine[l] ?? const <WordRow>[];
      rows.add(
        LineRow(
          page: page,
          line: l,
          kind: kind,
          centered: kind == LineKind.basmala,
          surah: surah,
          firstWordIndex: onLine.isEmpty ? null : onLine.first.wordIndex,
          lastWordIndex: onLine.isEmpty ? null : onLine.last.wordIndex,
        ),
      );
    }
  }
  return rows;
}

List<LineKind> _header(
  TanzilQuran quran,
  int page,
  int from,
  int next,
  List<WordRow>? nextWords,
) {
  final first = nextWords?.first;
  if (first == null || first.ayah != 1 || first.position != 1) {
    throw ContentBuildException(
      'Page $page lines $from..${next - 1} are empty but no surah starts '
      'after them; cannot classify.',
    );
  }
  final hasBasmala = quran.surah(first.surah).ayahs.first.bismillah != null;
  final header = [LineKind.surahName, if (hasBasmala) LineKind.basmala];
  if (next - from != header.length) {
    throw ContentBuildException(
      'Page $page: ${next - from} empty lines before surah ${first.surah}, '
      'expected ${header.length}; cannot classify.',
    );
  }
  return header;
}
