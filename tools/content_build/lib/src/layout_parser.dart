import 'dart:convert';

import 'package:content_build/src/content_build_exception.dart';
import 'package:meta/meta.dart';

/// Kind of a glyph in the page layout.
enum LayoutTokenKind {
  /// A Quran word.
  word,

  /// The ayah-end marker with the ayah number.
  ayahEnd,
}

/// One glyph of a page layout: a word or an ayah-end marker.
@immutable
final class LayoutToken {
  /// Creates a layout token.
  const LayoutToken({
    required this.position,
    required this.kind,
    required this.page,
    required this.line,
    required this.glyphCode,
  });

  /// Position within the ayah, 1-based; the ayah-end marker comes last.
  final int position;

  /// Word or ayah-end marker.
  final LayoutTokenKind kind;

  /// Page in the layout.
  final int page;

  /// Line on the page.
  final int line;

  /// Glyph code in the page font.
  final String glyphCode;
}

/// One ayah of the layout source with its glyphs and metadata.
@immutable
final class LayoutVerse {
  /// Creates a layout verse.
  const LayoutVerse({
    required this.surah,
    required this.ayah,
    required this.juz,
    required this.hizb,
    required this.sajda,
    required this.tokens,
  });

  /// Surah number.
  final int surah;

  /// Ayah number.
  final int ayah;

  /// Juz number.
  final int juz;

  /// Hizb number.
  final int hizb;

  /// Whether the ayah has a sajda.
  final bool sajda;

  /// Glyphs in reading order.
  final List<LayoutToken> tokens;

  /// Word glyphs only.
  Iterable<LayoutToken> get words =>
      tokens.where((t) => t.kind == LayoutTokenKind.word);
}

/// Surah metadata from the layout source.
@immutable
final class LayoutChapter {
  /// Creates chapter metadata.
  const LayoutChapter({
    required this.number,
    required this.ayahCount,
    required this.revelation,
  });

  /// Surah number.
  final int number;

  /// Number of ayahs.
  final int ayahCount;

  /// `makkah` or `madinah`.
  final String revelation;
}

/// Parses a `verses/by_page` response of the Quran.com API v4 requested with
/// `mushaf=1` (KFGQPC V2 layout) and the word fields `code_v2`, `location`,
/// `v2_page`, `line_v2`.
///
/// Throws [ContentBuildException] on unexpected structure.
List<LayoutVerse> parseLayoutPage(String source) {
  final root = _object(_decode(source), 'response');
  final pagination = _object(root['pagination'], 'pagination');
  if (pagination['next_page'] != null) {
    throw const ContentBuildException(
      'Layout page response is paginated; raise per_page in the config.',
    );
  }
  return [
    for (final verse in _list(root['verses'], 'verses'))
      _parseVerse(_object(verse, 'verse')),
  ];
}

/// Parses a `chapters/{n}` response of the Quran.com API v4.
LayoutChapter parseLayoutChapter(String source) {
  final root = _object(_decode(source), 'response');
  final chapter = _object(root['chapter'], 'chapter');
  return LayoutChapter(
    number: _int(chapter['id'], 'chapter.id'),
    ayahCount: _int(chapter['verses_count'], 'chapter.verses_count'),
    revelation: _string(
      chapter['revelation_place'],
      'chapter.revelation_place',
    ),
  );
}

LayoutVerse _parseVerse(Map<String, Object?> verse) {
  final key = _string(verse['verse_key'], 'verse_key').split(':');
  if (key.length != 2) {
    throw ContentBuildException('Bad verse_key: ${verse['verse_key']}');
  }
  final surah = int.parse(key[0]);
  final ayah = int.parse(key[1]);
  final tokens = <LayoutToken>[];
  for (final item in _list(verse['words'], 'words')) {
    final word = _object(item, 'word');
    final location = _string(word['location'], 'location').split(':');
    if (location.length != 3 ||
        int.parse(location[0]) != surah ||
        int.parse(location[1]) != ayah) {
      throw ContentBuildException(
        'Word ${word['location']} does not belong to $surah:$ayah.',
      );
    }
    final type = _string(word['char_type_name'], 'char_type_name');
    final kind = switch (type) {
      'word' => LayoutTokenKind.word,
      'end' => LayoutTokenKind.ayahEnd,
      _ => throw ContentBuildException(
          'Unknown char_type_name "$type" at ${word['location']}.',
        ),
    };
    tokens.add(
      LayoutToken(
        position: int.parse(location[2]),
        kind: kind,
        page: _int(word['v2_page'], 'v2_page'),
        line: _int(word['line_v2'], 'line_v2'),
        glyphCode: _string(word['code_v2'], 'code_v2'),
      ),
    );
  }
  return LayoutVerse(
    surah: surah,
    ayah: ayah,
    juz: _int(verse['juz_number'], 'juz_number'),
    hizb: _int(verse['hizb_number'], 'hizb_number'),
    sajda: verse['sajdah_number'] != null,
    tokens: tokens,
  );
}

Object? _decode(String source) {
  try {
    return jsonDecode(source);
  } on FormatException catch (e) {
    throw ContentBuildException('Layout response is not JSON: ${e.message}');
  }
}

Map<String, Object?> _object(Object? value, String what) {
  if (value is Map<String, Object?>) return value;
  throw ContentBuildException('Expected an object for $what.');
}

List<Object?> _list(Object? value, String what) {
  if (value is List<Object?>) return value;
  throw ContentBuildException('Expected a list for $what.');
}

String _string(Object? value, String what) {
  if (value is String && value.isNotEmpty) return value;
  throw ContentBuildException('Expected a non-empty string for $what.');
}

int _int(Object? value, String what) {
  if (value is int) return value;
  throw ContentBuildException('Expected an integer for $what.');
}
