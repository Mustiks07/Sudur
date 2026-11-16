import 'dart:convert';
import 'dart:io';

import 'package:content_build/content_build.dart';
import 'package:contracts/contracts.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  ContentData assemble({List<LayoutVerse>? verses}) => assembleContent(
        config: syntheticConfig(),
        quran: syntheticQuran(),
        verses: mergeLayoutVerses(verses ?? syntheticLayout()),
        chapters: syntheticChapters(),
        version: const {'version': 'test'},
      );

  group('assembleContent', () {
    test('words carry verbatim text, global index and glyph place', () {
      final data = assemble();
      expect(data.words.map((w) => w.textUthmani), [
        'a1',
        'b1',
        'c1 $pauseMark',
        'd1',
        'e2',
        'f2',
        'g2',
        'h2',
        'i2',
      ]);
      expect(data.words.map((w) => w.wordIndex), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      final g2 = data.words[6];
      expect(
        (g2.place.page, g2.place.line, g2.place.linePosition),
        (11, 3, 3),
      );
      expect(g2.place.glyphCode, 'G2.1.3');
    });

    test('ayahs know their first word, count and end marker', () {
      final ayah = assemble().ayahs[2];
      expect((ayah.surah, ayah.ayah), (2, 1));
      expect((ayah.firstWordIndex, ayah.wordCount, ayah.page), (5, 3, 11));
      expect((ayah.end.line, ayah.end.linePosition), (3, 4));
    });

    test('empty lines before a surah become its name and basmala', () {
      final lines = assemble().lines;
      expect(lines, hasLength(8));
      final page11 = lines.where((l) => l.page == 11).toList();
      expect(page11.map((l) => l.kind), [
        LineKind.surahName,
        LineKind.basmala,
        LineKind.ayah,
        LineKind.ayah,
      ]);
      expect(page11.first.surah, 2);
      expect(page11.first.centered, isFalse);
      expect(page11[1].centered, isTrue);
      expect(page11.first.firstWordIndex, isNull);
      expect((page11[2].firstWordIndex, page11[2].lastWordIndex), (5, 7));
      expect(lines.where((l) => l.page == 10).map((l) => l.kind).toSet(), {
        LineKind.ayah,
      });
    });

    test('pages know their first and last word', () {
      final pages = assemble().pages;
      expect(pages.map((p) => (p.firstWordIndex, p.lastWordIndex)), [
        (1, 4),
        (5, 9),
      ]);
    });

    test('refuses empty lines that are not a surah header', () {
      // Surah 2 ayah 2 removed: line 4 of page 11 becomes empty.
      final verses = syntheticLayout()
          .where((v) => !(v.surah == 2 && v.ayah == 2))
          .toList();
      expect(
        () => assemble(verses: verses),
        throwsA(isA<ContentBuildException>()),
      );
    });

    test('refuses a surah header at the bottom of a page', () {
      // Surah 1 moved up: lines 3–4 of page 10 are empty, surah 2 starts on
      // the next page. Not supported: the build fails instead of guessing.
      final verses = [
        ...parseLayoutPage(
          pageJson([
            verseJson(1, 1, [('w', 10, 1), ('w', 10, 1), ('e', 10, 1)]),
            verseJson(1, 2, [('w', 10, 2), ('w', 10, 2), ('e', 10, 2)]),
          ]),
        ),
        ...parseLayoutPage(syntheticPage11()),
      ];
      expect(
        () => assemble(verses: verses),
        throwsA(isA<ContentBuildException>()),
      );
    });

    test('merges an ayah listed by two page responses', () {
      final twice = [...syntheticLayout(), ...syntheticLayout()];
      expect(mergeLayoutVerses(twice), hasLength(4));
    });
  });

  group('writers', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('content_build'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('SQLite and JSON hold the same rows', () {
      final data = assemble();
      final dbPath = p.join(dir.path, 'content.sqlite');
      final jsonPath = p.join(dir.path, 'content.json');
      writeContentDatabase(data, dbPath);
      writeContentJson(data, jsonPath);

      final db = sqlite3.open(dbPath);
      addTearDown(db.dispose);
      final row = db.select(
        'SELECT text_uthmani, glyph_code FROM word WHERE word_index = 3',
      );
      expect(row.single['text_uthmani'], 'c1 $pauseMark');
      expect(row.single['glyph_code'], 'G1.2.1');
      expect(db.select('SELECT * FROM line'), hasLength(8));

      final json = jsonDecode(File(jsonPath).readAsStringSync());
      expect(json, isA<Map<String, Object?>>());
      final words = (json as Map<String, Object?>)['words'];
      expect(words, isA<List<Object?>>());
      expect(words! as List<Object?>, hasLength(9)); // Checked by isA above.
    });
  });

  group('ContentBuilder', () {
    test('builds from fetched sources and checks them', () async {
      final fetcher = _FakeFetcher({
        'https://text.test/quran.xml': syntheticTanzilXml(),
        'https://layout.test/10': syntheticPage10(),
        'https://layout.test/11': syntheticPage11(),
        'https://layout.test/c/1': chapterJson(syntheticChapters()[1]!),
        'https://layout.test/c/2': chapterJson(syntheticChapters()[2]!),
      });
      final result = await ContentBuilder(
        config: syntheticConfig(),
        fetcher: fetcher,
        logger: Logger('test'),
      ).build();
      switch (result) {
        case Ok(:final value):
          expect(value.words, hasLength(9));
          expect(value.version['textLicense'], 'CC-BY-3.0');
          expect(value.version['textNotice'], contains('Tanzil'));
          expect(value.version['canonSha256'], isNotEmpty);
        case Error(:final error):
          fail('build failed: $error');
      }
    });

    test('returns an error when a check fails', () async {
      final fetcher = _FakeFetcher({
        'https://text.test/quran.xml': syntheticTanzilXml(),
      });
      final result = await ContentBuilder(
        config: syntheticConfig(canonSha256: 'pinned'),
        fetcher: fetcher,
        logger: Logger('test'),
      ).build();
      expect(result, isA<Error<ContentData>>());
    });
  });
}

final class _FakeFetcher implements SourceFetcher {
  _FakeFetcher(this._responses);

  final Map<String, String> _responses;

  @override
  Future<List<int>> fetch(Uri url, String cacheName) async {
    final body = _responses[url.toString()];
    if (body == null) throw ContentBuildException('No fake for $url');
    return utf8.encode(body);
  }
}
