import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:quran_text/quran_text.dart';

/// Parsed canonical prototype content ready for `mushaf_view`.
final class PrototypeMushafContent {
  /// Creates parsed pages and the surah 78 reading sequence.
  const new({required this.pages, required this.sessionWords});

  /// Pages 582 and 583.
  final List<MushafPageData> pages;

  /// Surah 78 words in canonical reading order.
  final List<WordKey> sessionWords;
}

/// Adapts the checked `content_build` JSON without changing Quran text.
final class PrototypeContentParser {
  /// Creates a parser.
  const new();

  /// Parses the pinned pages 582–583 fixture.
  PrototypeMushafContent parse(String json) {
    final canonical = switch (ContentJsonSource(json).loadWords()) {
      Ok<List<Word>>(value: final words) => words,
      Error<List<Word>>(:final error) => throw error,
    };
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?> || decoded['format'] != 1) {
      throw const FormatException('Unsupported prototype content format.');
    }
    final wordRows = _objectList(decoded, 'words');
    final lineRows = _objectList(decoded, 'lines');
    final ayahRows = _objectList(decoded, 'ayahs');
    final pages = <MushafPageData>[
      for (final pageNumber in const <int>[582, 583])
        _page(
          pageNumber: pageNumber,
          canonical: canonical,
          wordRows: wordRows,
          lineRows: lineRows,
          ayahRows: ayahRows,
        ),
    ];
    final sessionWords = canonical
        .where((word) => word.key.surah == 78)
        .map((word) => word.key)
        .toList(growable: false);
    if (sessionWords.isEmpty) {
      throw const FormatException('Surah 78 is absent from prototype content.');
    }
    return PrototypeMushafContent(
      pages: List.unmodifiable(pages),
      sessionWords: List.unmodifiable(sessionWords),
    );
  }

  MushafPageData _page({
    required int pageNumber,
    required List<Word> canonical,
    required List<Map<String, Object?>> wordRows,
    required List<Map<String, Object?>> lineRows,
    required List<Map<String, Object?>> ayahRows,
  }) {
    final canonicalByKey = <WordKey, Word>{
      for (final word in canonical) word.key: word,
    };
    final lines = <MushafLineData>[];
    for (var lineNumber = 1; lineNumber <= 15; lineNumber += 1) {
      final line = lineRows.singleWhere(
        (row) =>
            _integer(row, 'page') == pageNumber &&
            _integer(row, 'line') == lineNumber,
      );
      final positioned = <({int position, MushafFragment fragment})>[];
      for (final row in wordRows.where(
        (row) =>
            _integer(row, 'page') == pageNumber &&
            _integer(row, 'line') == lineNumber,
      )) {
        final key = WordKey(
          _integer(row, 'surah'),
          _integer(row, 'ayah'),
          _integer(row, 'position'),
        );
        if (!canonicalByKey.containsKey(key)) {
          throw FormatException('Missing canonical word $key.');
        }
        positioned.add((
          position: _integer(row, 'linePosition'),
          fragment: MushafFragment(
            glyph: _string(row, 'glyphCode'),
            kind: MushafFragmentKind.word,
            wordKey: key,
          ),
        ));
      }
      for (final row in ayahRows.where(
        (row) =>
            _integer(row, 'endPage') == pageNumber &&
            _integer(row, 'endLine') == lineNumber,
      )) {
        positioned.add((
          position: _integer(row, 'endLinePosition'),
          fragment: MushafFragment(
            glyph: _string(row, 'endGlyphCode'),
            kind: MushafFragmentKind.ayahEnd,
          ),
        ));
      }
      positioned.sort((left, right) => left.position.compareTo(right.position));
      final fragments = positioned.map((entry) => entry.fragment).toList();
      if (fragments.isEmpty) {
        final kind = switch (_string(line, 'kind')) {
          'surahName' => MushafFragmentKind.surahTitle,
          'basmala' => MushafFragmentKind.basmala,
          _ => throw FormatException(
            'Empty ayah line $pageNumber:$lineNumber.',
          ),
        };
        // The content fixture intentionally contains no licensed header glyph.
        fragments.add(MushafFragment(glyph: '', kind: kind));
      }
      lines.add(MushafLineData(List.unmodifiable(fragments)));
    }
    return MushafPageData(
      pageNumber: pageNumber,
      lines: List.unmodifiable(lines),
      // Full canonical ayah strings are not present in the v0 fixture. They
      // are deliberately not reconstructed from word slices.
      ayahSemantics: const <MushafAyahSemantics>[],
    );
  }
}

List<Map<String, Object?>> _objectList(Map<String, Object?> root, String key) {
  final value = root[key];
  if (value is! List<Object?>) {
    throw FormatException('$key must be a list.');
  }
  return value
      .map((item) {
        if (item is! Map<String, Object?>) {
          throw FormatException('$key must contain objects.');
        }
        return item;
      })
      .toList(growable: false);
}

int _integer(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! int) throw FormatException('$key must be an integer.');
  return field;
}

String _string(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! String) throw FormatException('$key must be a string.');
  return field;
}
