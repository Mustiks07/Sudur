import 'dart:convert';

import 'package:content_build/src/canon_checksum.dart';
import 'package:content_build/src/layout_parser.dart';
import 'package:content_build/src/tanzil_parser.dart';
import 'package:content_build/src/word_segmenter.dart';
import 'package:meta/meta.dart';

/// Version of the text JSON format written by [QuranTextData.toJson]
/// (ADR 0004).
const int textJsonFormat = 2;

/// One surah of the text package.
@immutable
final class TextSurah {
  /// Creates a surah.
  const TextSurah({
    required this.number,
    required this.nameAr,
    required this.ayahCount,
    this.revelation,
  });

  /// Surah number, 1..114.
  final int number;

  /// Arabic name exactly as given by the text source.
  final String nameAr;

  /// Number of ayahs.
  final int ayahCount;

  /// `makkah` or `madinah`, where a source gave it; else `null`.
  final String? revelation;
}

/// One ayah of the text package: its words, cut from the source text
/// without changing a character (see `segmentAyah`).
@immutable
final class TextAyah {
  /// Creates an ayah.
  const TextAyah({
    required this.surah,
    required this.ayah,
    required this.firstWordIndex,
    required this.words,
    this.juz,
    this.hizb,
    this.sajda,
  });

  /// Surah number.
  final int surah;

  /// Ayah number.
  final int ayah;

  /// Global index of the first word.
  final int firstWordIndex;

  /// Canonical words; joined with a space they give the source text.
  final List<String> words;

  /// Juz, where a source gave it.
  final int? juz;

  /// Hizb, where a source gave it.
  final int? hizb;

  /// Whether the ayah has a sajda, where a source gave it.
  final bool? sajda;
}

/// The text of the whole Quran (text package, ADR 0004): every surah, ayah
/// and word, with no page layout.
@immutable
final class QuranTextData {
  /// Creates text data.
  const QuranTextData({
    required this.version,
    required this.surahs,
    required this.ayahs,
  });

  /// `content_version` pairs, including the verbatim Tanzil notice.
  final Map<String, String> version;

  /// All surahs.
  final List<TextSurah> surahs;

  /// All ayahs in order.
  final List<TextAyah> ayahs;

  /// Number of words.
  int get wordCount => ayahs.fold(0, (n, a) => n + a.words.length);

  /// Keys of [version] that describe the text package: its version,
  /// source, license, the verbatim Tanzil notice and checksums. Layout and
  /// font entries belong to the layout package.
  static const Set<String> textVersionKeys = {
    'version',
    'buildId',
    'textSource',
    'textUrl',
    'textLicense',
    'textAttribution',
    'textNotice',
    'textFileSha256',
    'canonSha256',
  };

  /// [version] restricted to [textVersionKeys].
  Map<String, String> get textVersion => {
        for (final e in version.entries)
          if (textVersionKeys.contains(e.key)) e.key: e.value,
      };

  /// The text fixture JSON (ADR 0004): one ayah per line as
  /// `[surah, ayah, [words…]]`; word indexes follow from the order.
  String toJson() {
    String encode(Object? value) => jsonEncode(value);
    final b = StringBuffer()
      ..writeln('{')
      ..writeln('"format": $textJsonFormat,')
      ..writeln('"kind": "text",')
      ..writeln('"contentVersion": ${encode(textVersion)},')
      ..writeln('"surahs": [');
    for (var i = 0; i < surahs.length; i++) {
      final s = surahs[i];
      b.writeln(
        '${encode({
              'number': s.number,
              'nameAr': s.nameAr,
              'ayahCount': s.ayahCount,
              'revelation': s.revelation,
            })}'
        '${i < surahs.length - 1 ? ',' : ''}',
      );
    }
    b
      ..writeln('],')
      ..writeln('"ayahs": [');
    for (var i = 0; i < ayahs.length; i++) {
      final a = ayahs[i];
      b.writeln(
        '${encode([a.surah, a.ayah, a.words])}'
        '${i < ayahs.length - 1 ? ',' : ''}',
      );
    }
    b
      ..writeln(']')
      ..writeln('}');
    return b.toString();
  }
}

/// Builds the text of the whole Quran from the verified source. Juz, hizb
/// and sajda come from the layout source where it covers an ayah;
/// revelation from [chapters] where given.
QuranTextData assembleText({
  required TanzilQuran quran,
  required List<LayoutVerse> verses,
  required Map<int, LayoutChapter> chapters,
  required Map<String, String> version,
}) {
  final meta = {for (final v in verses) (v.surah, v.ayah): v};
  final ayahs = <TextAyah>[];
  var next = 1;
  for (final surah in quran.surahs) {
    for (final ayah in surah.ayahs) {
      final words = segmentAyah(ayah.text);
      final m = meta[(surah.index, ayah.index)];
      ayahs.add(
        TextAyah(
          surah: surah.index,
          ayah: ayah.index,
          firstWordIndex: next,
          words: List.unmodifiable(words),
          juz: m?.juz,
          hizb: m?.hizb,
          sajda: m?.sajda,
        ),
      );
      next += words.length;
    }
  }
  return QuranTextData(
    version: version,
    surahs: [
      for (final s in quran.surahs)
        TextSurah(
          number: s.index,
          nameAr: s.name,
          ayahCount: s.ayahs.length,
          revelation: chapters[s.index]?.revelation,
        ),
    ],
    ayahs: ayahs,
  );
}

/// SHA-256 of the text, computed like `canonChecksum` from the words
/// joined back into ayahs: it equals the pinned canon checksum only if no
/// character changed on the way (ADR 0004: the fixture is checked so).
String textCanonChecksum(QuranTextData text) {
  final b = StringBuffer();
  for (final a in text.ayahs) {
    b
      ..write(a.surah)
      ..write('|')
      ..write(a.ayah)
      ..write('|')
      ..write(a.words.join(tanzilTokenSeparator))
      ..write('\n');
  }
  return bytesChecksum(utf8.encode(b.toString()));
}
