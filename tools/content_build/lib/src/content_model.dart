import 'package:meta/meta.dart';

/// Version of the JSON format written by [ContentData.toJson].
const int contentJsonFormat = 1;

/// One row of the `surah` table (docs/tz section 12.2).
@immutable
final class SurahRow {
  /// Creates a surah row.
  const SurahRow({
    required this.number,
    required this.nameAr,
    required this.ayahCount,
    required this.revelation,
  });

  /// Surah number, 1..114.
  final int number;

  /// Arabic name exactly as given by the text source.
  final String nameAr;

  /// Number of ayahs in the whole surah (not only in the build scope).
  final int ayahCount;

  /// `makkah` or `madinah`, as given by the layout source.
  final String revelation;

  /// JSON form. Localized names are `null` until a licensed source exists
  /// (TODO_CONTENT).
  Map<String, Object?> toJson() => {
        'number': number,
        'nameAr': nameAr,
        'nameRu': null,
        'nameKk': null,
        'nameUz': null,
        'ayahCount': ayahCount,
        'revelation': revelation,
      };
}

/// Position of a glyph on a mushaf page.
@immutable
final class GlyphPlace {
  /// Creates a glyph place.
  const GlyphPlace({
    required this.page,
    required this.line,
    required this.linePosition,
    required this.glyphCode,
  });

  /// Page number in the layout.
  final int page;

  /// Line on the page, 1-based.
  final int line;

  /// Order of the glyph within the line, 1-based, counting words and
  /// ayah-end markers.
  final int linePosition;

  /// Code point(s) of the glyph in the page font.
  final String glyphCode;
}

/// One row of the `ayah` table (docs/tz section 12.2), plus the place of the
/// ayah-end marker that the page renderer needs.
@immutable
final class AyahRow {
  /// Creates an ayah row.
  const AyahRow({
    required this.surah,
    required this.ayah,
    required this.firstWordIndex,
    required this.wordCount,
    required this.page,
    required this.juz,
    required this.hizb,
    required this.sajda,
    required this.end,
  });

  /// Surah number.
  final int surah;

  /// Ayah number within the surah.
  final int ayah;

  /// Global index of the first word of the ayah.
  final int firstWordIndex;

  /// Number of words in the ayah.
  final int wordCount;

  /// Page of the first word.
  final int page;

  /// Juz number, 1..30.
  final int juz;

  /// Hizb number, 1..60.
  final int hizb;

  /// Whether the ayah contains a sajda.
  final bool sajda;

  /// Place of the ayah-end marker glyph.
  final GlyphPlace end;

  /// JSON form.
  Map<String, Object?> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'firstWordIndex': firstWordIndex,
        'wordCount': wordCount,
        'page': page,
        'juz': juz,
        'hizb': hizb,
        'sajda': sajda,
        'endPage': end.page,
        'endLine': end.line,
        'endLinePosition': end.linePosition,
        'endGlyphCode': end.glyphCode,
      };
}

/// One row of the `word` table (docs/tz section 12.2).
@immutable
final class WordRow {
  /// Creates a word row.
  const WordRow({
    required this.wordIndex,
    required this.surah,
    required this.ayah,
    required this.position,
    required this.textUthmani,
    required this.place,
  });

  /// Global 1-based index of the word in the Quran.
  final int wordIndex;

  /// Surah number.
  final int surah;

  /// Ayah number.
  final int ayah;

  /// Word number within the ayah, 1-based.
  final int position;

  /// Canonical text, a verbatim slice of the source ayah text.
  final String textUthmani;

  /// Where the word is drawn.
  final GlyphPlace place;

  /// JSON form.
  Map<String, Object?> toJson() => {
        'wordIndex': wordIndex,
        'surah': surah,
        'ayah': ayah,
        'position': position,
        'textUthmani': textUthmani,
        'page': place.page,
        'line': place.line,
        'linePosition': place.linePosition,
        'glyphCode': place.glyphCode,
      };
}

/// One row of the `page` table (docs/tz section 12.2).
@immutable
final class PageRow {
  /// Creates a page row.
  const PageRow({
    required this.number,
    required this.layoutId,
    required this.firstWordIndex,
    required this.lastWordIndex,
  });

  /// Page number.
  final int number;

  /// Layout identifier from the build config.
  final String layoutId;

  /// First word on the page.
  final int firstWordIndex;

  /// Last word on the page.
  final int lastWordIndex;

  /// JSON form.
  Map<String, Object?> toJson() => {
        'number': number,
        'layoutId': layoutId,
        'firstWordIndex': firstWordIndex,
        'lastWordIndex': lastWordIndex,
      };
}

/// Kind of a mushaf line.
enum LineKind {
  /// Line with ayah words.
  ayah,

  /// Surah name header.
  surahName,

  /// Basmala before a surah.
  basmala,
}

/// One row of the `line` table (docs/tz section 12.2).
@immutable
final class LineRow {
  /// Creates a line row.
  const LineRow({
    required this.page,
    required this.line,
    required this.kind,
    required this.centered,
    this.surah,
    this.firstWordIndex,
    this.lastWordIndex,
  });

  /// Page number.
  final int page;

  /// Line number, 1-based.
  final int line;

  /// What the line shows.
  final LineKind kind;

  /// Whether the line is centered instead of justified.
  final bool centered;

  /// Surah of a header line; `null` for ayah lines.
  final int? surah;

  /// First word on the line; `null` for header lines.
  final int? firstWordIndex;

  /// Last word on the line; `null` for header lines.
  final int? lastWordIndex;

  /// JSON form.
  Map<String, Object?> toJson() => {
        'page': page,
        'line': line,
        'kind': kind.name,
        'centered': centered,
        'surah': surah,
        'firstWordIndex': firstWordIndex,
        'lastWordIndex': lastWordIndex,
      };
}

/// Everything a content build produces, in table form.
@immutable
final class ContentData {
  /// Creates content data.
  const ContentData({
    required this.version,
    required this.surahs,
    required this.ayahs,
    required this.words,
    required this.pages,
    required this.lines,
  });

  /// `content_version` key/value pairs: version, sources, licenses,
  /// checksums and the verbatim source notices.
  final Map<String, String> version;

  /// Surahs touched by the build scope.
  final List<SurahRow> surahs;

  /// Ayahs in the build scope.
  final List<AyahRow> ayahs;

  /// Words in the build scope.
  final List<WordRow> words;

  /// Pages in the build scope.
  final List<PageRow> pages;

  /// Lines of the pages in the build scope.
  final List<LineRow> lines;

  /// JSON form, mirroring the tables of docs/tz section 12.2.
  Map<String, Object?> toJson() => {
        'format': contentJsonFormat,
        'contentVersion': version,
        'surahs': [for (final s in surahs) s.toJson()],
        'ayahs': [for (final a in ayahs) a.toJson()],
        'words': [for (final w in words) w.toJson()],
        'pages': [for (final p in pages) p.toJson()],
        'lines': [for (final l in lines) l.toJson()],
      };
}
