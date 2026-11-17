import 'dart:convert';

import 'package:content_build/content_build.dart';

// Synthetic sources for algorithm tests. Text is Latin placeholders, never
// Arabic: real Quran text in tests comes only from the generated fixture.

/// A pause-mark code point, written as a number so no Quran text is typed.
final String pauseMark = String.fromCharCode(quranicSignFirst);

/// Synthetic text: surah 1 without basmala, surah 2 with one.
String syntheticTanzilXml({String notice = 'Tanzil test notice'}) => '''
<?xml version="1.0" encoding="utf-8" ?>
<!-- $notice -->
<quran>
  <sura index="1" name="one">
    <aya index="1" text="a1 b1" />
    <aya index="2" text="c1 $pauseMark d1" />
  </sura>
  <sura index="2" name="two">
    <aya index="1" text="e2 f2 g2" bismillah="x y" />
    <aya index="2" text="h2 i2" />
  </sura>
</quran>
''';

/// Parsed [syntheticTanzilXml].
TanzilQuran syntheticQuran() => parseTanzilXml(syntheticTanzilXml());

/// A config for the synthetic sources: pages 10–11, 4 lines per page.
BuildConfig syntheticConfig({
  String? canonSha256,
  int surahs = 2,
  int ayahs = 4,
  String textLicense = 'CC-BY-3.0',
}) {
  Map<String, String> source(String name, String url, String license) => {
        'name': name,
        'url': url,
        'license': license,
        'attribution': '$name attribution',
      };
  return BuildConfig.fromJson(
    jsonEncode({
      'id': 'test',
      'version': '0.0.1',
      'pages': [10, 11],
      'layoutId': 'test-layout',
      'linesPerPage': 4,
      'expected': {
        'surahs': surahs,
        'ayahs': ayahs,
        'canonSha256': canonSha256 ?? canonChecksum(syntheticQuran()),
        'firstAyah': '1:1',
        'lastAyah': '2:2',
      },
      'text': source('text', 'https://text.test/quran.xml', textLicense),
      'layout': source('layout', 'https://layout.test/{page}', 'X-1'),
      'chapters': source('chapters', 'https://layout.test/c/{surah}', 'X-2'),
      'fonts': source('fonts', 'https://fonts.test/p{page}.ttf', 'X-3'),
    }),
  );
}

/// One glyph: `w` (word) or `e` (ayah end), page, line.
typedef Glyph = (String, int, int);

/// A layout API verse object.
Map<String, Object?> verseJson(int surah, int ayah, List<Glyph> glyphs) => {
      'verse_key': '$surah:$ayah',
      'juz_number': 1,
      'hizb_number': 1,
      'sajdah_number': null,
      'words': [
        for (var i = 0; i < glyphs.length; i++)
          {
            'location': '$surah:$ayah:${i + 1}',
            'char_type_name': glyphs[i].$1 == 'w' ? 'word' : 'end',
            'v2_page': glyphs[i].$2,
            'line_v2': glyphs[i].$3,
            'code_v2': 'G$surah.$ayah.${i + 1}',
          },
      ],
    };

/// A `verses/by_page` response.
String pageJson(List<Map<String, Object?>> verses) => jsonEncode({
      'verses': verses,
      'pagination': {'next_page': null},
    });

/// Layout of the synthetic text. Page 10: surah 1 on all four lines.
/// Page 11: header of surah 2 on lines 1–2, then surah 2.
List<LayoutVerse> syntheticLayout() => [
      ...parseLayoutPage(syntheticPage10()),
      ...parseLayoutPage(syntheticPage11()),
    ];

/// Page 10 response of the synthetic layout.
String syntheticPage10() => pageJson([
      verseJson(1, 1, [('w', 10, 1), ('w', 10, 2), ('e', 10, 2)]),
      verseJson(1, 2, [('w', 10, 3), ('w', 10, 4), ('e', 10, 4)]),
    ]);

/// Page 11 response of the synthetic layout.
String syntheticPage11() => pageJson([
      verseJson(2, 1, [('w', 11, 3), ('w', 11, 3), ('w', 11, 3), ('e', 11, 3)]),
      verseJson(2, 2, [('w', 11, 4), ('w', 11, 4), ('e', 11, 4)]),
    ]);

/// Chapter metadata of the synthetic text.
Map<int, LayoutChapter> syntheticChapters() => {
      1: const LayoutChapter(number: 1, ayahCount: 2, revelation: 'makkah'),
      2: const LayoutChapter(number: 2, ayahCount: 2, revelation: 'madinah'),
    };

/// A chapter API response.
String chapterJson(LayoutChapter c) => jsonEncode({
      'chapter': {
        'id': c.number,
        'verses_count': c.ayahCount,
        'revelation_place': c.revelation,
      },
    });
