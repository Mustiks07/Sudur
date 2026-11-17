import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:contracts/contracts.dart';
import 'package:crypto/crypto.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:quran_text/quran_text.dart';

/// Read-only adapter of the P03 content, including original page glyphs.
final class PrototypeContent {
  /// Parses a locally installed P03 content file without altering its text.
  new(String source) {
    words = switch (ContentJsonSource(source).loadWords()) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    // Field assertions below follow the verified P03 format-1 schema.
    final root = jsonDecode(source) as Map<String, Object?>;
    final rows = (root['words']! as List<Object?>).cast<Map<String, Object?>>();
    final ayahs = (root['ayahs']! as List<Object?>)
        .cast<Map<String, Object?>>();
    final lines = (root['lines']! as List<Object?>)
        .cast<Map<String, Object?>>();
    pages = [
      for (final page
          in words.where((w) => w.key.surah == 78).map((w) => w.page).toSet())
        MushafPageData(
          pageNumber: page,
          lines: [
            for (var line = 1; line <= 15; line++)
              MushafLineData(_fragments(rows, ayahs, lines, page, line)),
          ],
          ayahSemantics: [
            for (final ayah in ayahs.where((a) => a['page'] == page))
              MushafAyahSemantics(
                surah: ayah['surah']! as int,
                ayah: ayah['ayah']! as int,
                canonicalText: words
                    .where(
                      (w) =>
                          w.key.surah == ayah['surah'] &&
                          w.key.ayah == ayah['ayah'],
                    )
                    .map((w) => w.text)
                    .join(' '),
              ),
          ],
        ),
    ];
  }

  /// Loads the sideloaded canonical package.
  static Future<PrototypeContent> load(String root) => Isolate.run(() async {
    final bytes = await File('$root/content.json').readAsBytes();
    const expected =
        '928326595eea80edfac7733b7cb9c5b596457ab5627b9ccf3888cb3537c075d5';
    if (sha256.convert(bytes).toString() != expected) {
      throw const FormatException('Unrecognized prototype content');
    }
    return PrototypeContent(utf8.decode(bytes));
  });

  /// Checks the two pinned QUL fonts before Flutter registers them.
  static Future<void> verifyFonts(String root) => Isolate.run(() async {
    const hashes = {
      582: 'e445dfc1b2063f631724d71291c119086032bf7aac083eeafe6fa44d29298ba5',
      583: 'c8d76486a688a28ad6542f689a4fcbe1fc311267ee3bb8963b1b1ace03d546fb',
    };
    for (final entry in hashes.entries) {
      final bytes = await File('$root/fonts/p${entry.key}.ttf').readAsBytes();
      if (sha256.convert(bytes).toString() != entry.value) {
        throw const FormatException('Unrecognized prototype font');
      }
    }
  });

  /// Canonical words, unchanged from P03.
  late final List<Word> words;

  /// Original fifteen-line layout.
  late final List<MushafPageData> pages;

  List<MushafFragment> _fragments(
    List<Map<String, Object?>> words,
    List<Map<String, Object?>> ayahs,
    List<Map<String, Object?>> lines,
    int page,
    int line,
  ) {
    final positioned = <(int, MushafFragment)>[];
    for (final w in words.where(
      (w) => w['page'] == page && w['line'] == line,
    )) {
      positioned.add((
        w['linePosition']! as int,
        MushafFragment(
          glyph: w['glyphCode']! as String,
          kind: MushafFragmentKind.word,
          wordKey: WordKey(
            w['surah']! as int,
            w['ayah']! as int,
            w['position']! as int,
          ),
        ),
      ));
    }
    for (final a in ayahs.where(
      (a) => a['endPage'] == page && a['endLine'] == line,
    )) {
      positioned.add((
        a['endLinePosition']! as int,
        MushafFragment(
          glyph: a['endGlyphCode']! as String,
          kind: MushafFragmentKind.ayahEnd,
        ),
      ));
    }
    positioned.sort((a, b) => a.$1.compareTo(b.$1));
    // P03 does not supply header/basmala glyphs: never invent Quran content.
    return [for (final item in positioned) item.$2];
  }
}
