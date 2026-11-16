import 'package:content_build/content_build.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('BuildConfig', () {
    test('refuses a source without a license identifier (ПР-02)', () {
      expect(
        () => syntheticConfig(textLicense: ' '),
        throwsA(
          isA<ContentBuildException>().having(
            (e) => e.message,
            'message',
            contains('license'),
          ),
        ),
      );
    });
  });

  group('checkCanon (ПР-04)', () {
    test('passes on matching counts and checksum', () {
      expect(checkCanon(syntheticQuran(), syntheticConfig()), isEmpty);
    });

    test('reports wrong surah and ayah counts', () {
      final failures = checkCanon(
        syntheticQuran(),
        syntheticConfig(surahs: 114, ayahs: 6236),
      );
      expect(failures, hasLength(2));
      expect(failures.first, contains('114 surahs'));
      expect(failures.last, contains('6236 ayahs'));
    });

    test('reports a changed canon checksum', () {
      final failures = checkCanon(
        syntheticQuran(),
        syntheticConfig(canonSha256: 'pinned'),
      );
      expect(failures.single, contains('checksum'));
    });
  });

  group('checkLayout (ПР-04)', () {
    List<String> check(List<LayoutVerse> verses) => checkLayout(
          quran: syntheticQuran(),
          verses: verses,
          chapters: syntheticChapters(),
          config: syntheticConfig(),
        );

    test('passes on the synthetic layout', () {
      expect(check(syntheticLayout()), isEmpty);
    });

    test('reports an ayah missing from the layout source', () {
      // Ayah 1:2 removed from page 10.
      final verses = syntheticLayout()
          .where((v) => !(v.surah == 1 && v.ayah == 2))
          .toList();
      final failures = check(verses);
      expect(failures, contains(contains('skips from 1:1 to 2:1')));
    });

    test('reports a scope that does not start or end at a page edge', () {
      // First and last ayahs removed: the scope has holes at both ends.
      final verses = syntheticLayout()
          .where((v) => !(v.surah == 1 && v.ayah == 1))
          .where((v) => !(v.surah == 2 && v.ayah == 2))
          .toList();
      final failures = check(verses);
      expect(failures, contains(contains('Scope starts at 1:2')));
      expect(failures, contains(contains('Scope ends at 2:1')));
    });

    test('reports a word count that differs from the text', () {
      final verses = parseLayoutPage(
        pageJson([
          verseJson(1, 1, [('w', 10, 1), ('e', 10, 1)]),
        ]),
      );
      expect(check(verses), contains(contains('text source has 2 words')));
    });

    test('reports glyphs outside the scope pages or lines', () {
      final verses = parseLayoutPage(
        pageJson([
          verseJson(1, 1, [('w', 10, 1), ('w', 12, 1), ('e', 10, 5)]),
        ]),
      );
      final failures = check(verses);
      expect(failures, contains(contains('page 12, outside scope')));
      expect(failures, contains(contains('has line 5')));
    });

    test('reports a missing ayah-end marker', () {
      final verses = parseLayoutPage(
        pageJson([
          verseJson(1, 1, [('w', 10, 1), ('w', 10, 1)]),
        ]),
      );
      expect(check(verses), contains(contains('ayah-end marker')));
    });

    test('reports an ayah count that differs from the chapter source', () {
      final failures = checkLayout(
        quran: syntheticQuran(),
        verses: syntheticLayout(),
        chapters: {
          ...syntheticChapters(),
          2: const LayoutChapter(number: 2, ayahCount: 3, revelation: 'x'),
        },
        config: syntheticConfig(),
      );
      expect(failures.single, contains('Surah 2'));
    });
  });

  group('parseLayoutPage', () {
    test('refuses unknown glyph kinds and paginated responses', () {
      final unknown = pageJson([
        verseJson(1, 1, [('w', 10, 1)]),
      ]).replaceFirst('"word"', '"pause"');
      expect(
        () => parseLayoutPage(unknown),
        throwsA(isA<ContentBuildException>()),
      );
      final paginated = pageJson([]).replaceFirst('null', '2');
      expect(
        () => parseLayoutPage(paginated),
        throwsA(isA<ContentBuildException>()),
      );
    });
  });
}
