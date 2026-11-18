import 'dart:convert';

import 'package:content_build/src/content_build_exception.dart';
import 'package:content_build/src/content_model.dart';
import 'package:content_build/src/text_model.dart';
import 'package:contracts/contracts.dart';
import 'package:meta/meta.dart';
import 'package:quran_text/quran_text.dart';

// Derived data of the content database (docs/tz 12.2): default passages and
// similar places, computed from the Tanzil text. The text is only read.

/// Parameters of the derived data (`config/derived.json`).
@immutable
final class DerivedParams {
  /// Creates parameters.
  const DerivedParams({
    required this.passageMaxAyahs,
    required this.halfPageWords,
    required this.pageFraction,
    required this.similar,
  });

  /// Reads `config/derived.json`. Throws [ContentBuildException].
  factory DerivedParams.fromJson(String source) {
    try {
      final root = jsonDecode(source) as Map<String, Object?>;
      final similar = root['similar']! as Map<String, Object?>;
      return DerivedParams(
        passageMaxAyahs: root['passageMaxAyahs']! as int,
        halfPageWords: root['halfPageWords']! as int,
        pageFraction: (root['pageFraction']! as num).toDouble(),
        similar: SimilarPlaceParams(
          minPhraseWords: similar['minPhraseWords']! as int,
          minAyahWords: similar['minAyahWords']! as int,
          wordSimilarity: (similar['wordSimilarity']! as num).toDouble(),
        ),
      );
      // A missing or mistyped field is a config error.
      // ignore: avoid_catching_errors
    } on TypeError catch (e) {
      throw ContentBuildException('derived.json: $e');
    } on FormatException catch (e) {
      throw ContentBuildException('derived.json is not JSON: ${e.message}');
    }
  }

  /// At most this many ayahs in a passage (docs/tz 12.4 `passageMaxAyahs`).
  final int passageMaxAyahs;

  /// Half a page in words, for the text without page layout: 77 433 words
  /// on 604 pages of the Madinah mushaf ≈ 128 words a page. A passage has
  /// at most this many words; an ayah with more is a passage of its own
  /// («длинный аят»). Proposed, to be confirmed by the owner.
  final int halfPageWords;

  /// Share of a page a passage may take where the layout is known
  /// (docs/tz 4.8: «не больше половины страницы»).
  final double pageFraction;

  /// Similar places.
  final SimilarPlaceParams similar;

  /// As JSON, for the fixture header.
  Map<String, Object?> toJson() => {
        'passageMaxAyahs': passageMaxAyahs,
        'halfPageWords': halfPageWords,
        'pageFraction': pageFraction,
        'similar': {
          'minPhraseWords': similar.minPhraseWords,
          'minAyahWords': similar.minAyahWords,
          'wordSimilarity': similar.wordSimilarity,
        },
      };
}

/// An ayah as a span of word indexes.
@immutable
final class AyahSpan {
  /// Creates a span.
  const AyahSpan({
    required this.surah,
    required this.ayah,
    required this.firstWordIndex,
    required this.wordCount,
  });

  /// Surah number.
  final int surah;

  /// Ayah number.
  final int ayah;

  /// First word index (1-based, whole text).
  final int firstWordIndex;

  /// Words in the ayah.
  final int wordCount;

  /// Last word index.
  int get lastWordIndex => firstWordIndex + wordCount - 1;
}

/// Where a word stands on a page of the layout.
typedef WordPlace = ({int page, int line});

/// A passage: inclusive word index range.
typedef Passage = ({int from, int to});

/// Default passages (docs/tz 4.8, 12.2 `passage_default`):
///
/// - 1 to `passageMaxAyahs` ayahs, never across a surah;
/// - without layout: at most `halfPageWords` words; a longer ayah alone;
/// - where [layout] covers every word of the ayahs: on one page and on at
///   most `pageFraction × linesPerPage` lines; an ayah over two pages or
///   over more lines alone (ADR 0004: page rules only where layout exists);
/// - a run of ayahs that may join is split into the fewest passages, as
///   even in length as the limits allow.
List<Passage> buildPassages(
  List<AyahSpan> ayahs,
  Map<int, WordPlace> layout, {
  required int linesPerPage,
  required DerivedParams params,
}) {
  final maxLines = (linesPerPage * params.pageFraction).floor();
  // Places of an ayah's first and last word, if the layout covers it all.
  ({WordPlace first, WordPlace last})? placeOf(AyahSpan a) {
    for (var w = a.firstWordIndex; w <= a.lastWordIndex; w++) {
      if (!layout.containsKey(w)) return null;
    }
    final first = layout[a.firstWordIndex];
    final last = layout[a.lastWordIndex];
    return first == null || last == null ? null : (first: first, last: last);
  }

  bool alone(AyahSpan a) {
    final place = placeOf(a);
    if (place == null) return a.wordCount > params.halfPageWords;
    return place.first.page != place.last.page ||
        place.last.line - place.first.line + 1 > maxLines;
  }

  bool fits(List<AyahSpan> group) {
    if (group.length > params.passageMaxAyahs) return false;
    final place = placeOf(group.first);
    if (place == null) {
      final words = group.fold(0, (n, a) => n + a.wordCount);
      return group.length == 1 || words <= params.halfPageWords;
    }
    final last = placeOf(group.last);
    if (last == null) return false;
    return place.first.page == last.last.page &&
        last.last.line - place.first.line + 1 <= maxLines;
  }

  bool canFollow(AyahSpan prev, AyahSpan next) {
    if (prev.surah != next.surah || alone(prev) || alone(next)) return false;
    final a = placeOf(prev);
    final b = placeOf(next);
    if ((a == null) != (b == null)) return false; // Coverage changes.
    return a == null || b == null || a.last.page == b.first.page;
  }

  // Runs of ayahs that may share passages.
  final runs = <List<AyahSpan>>[];
  for (final a in ayahs) {
    if (runs.isNotEmpty && canFollow(runs.last.last, a)) {
      runs.last.add(a);
    } else {
      runs.add([a]);
    }
  }

  final passages = <Passage>[];
  for (final run in runs) {
    // Fewest passages, greedily.
    final greedy = <List<AyahSpan>>[];
    for (final a in run) {
      if (greedy.isNotEmpty && fits([...greedy.last, a])) {
        greedy.last.add(a);
      } else {
        greedy.add([a]);
      }
    }
    // The same number of passages, even in ayahs, when that fits.
    final k = greedy.length;
    final even = <List<AyahSpan>>[];
    var start = 0;
    for (var i = 0; i < k; i++) {
      final size = (run.length - start) ~/ (k - i) +
          ((run.length - start) % (k - i) == 0 ? 0 : 1);
      even.add(run.sublist(start, start + size));
      start += size;
    }
    final groups = even.every(fits) ? even : greedy;
    for (final g in groups) {
      passages.add((from: g.first.firstWordIndex, to: g.last.lastWordIndex));
    }
  }
  return passages;
}

/// Derived data of a text: passages and similar places.
@immutable
final class DerivedContent {
  /// Creates the data.
  const DerivedContent({
    required this.params,
    required this.passages,
    required this.pairs,
  });

  /// Parameters it was built with.
  final DerivedParams params;

  /// Default passages in text order.
  final List<Passage> passages;

  /// Similar places; none is verified by a specialist.
  final List<SimilarPlacePair> pairs;

  /// The test fixture form: one passage or pair per line.
  String toJson({required String canonSha256}) {
    final b = StringBuffer()
      ..writeln('{')
      ..writeln('  "format": 1,')
      ..writeln('  "kind": "derived",')
      ..writeln('  "textCanonSha256": ${jsonEncode(canonSha256)},')
      ..writeln('  "params": ${jsonEncode(params.toJson())},')
      ..writeln('  "verified": false,')
      ..writeln('  "passages": [');
    for (final (i, p) in passages.indexed) {
      b.writeln('    [${p.from},${p.to}]${i < passages.length - 1 ? ',' : ''}');
    }
    b
      ..writeln('  ],')
      ..writeln('  "similarPairs": [');
    for (final (i, p) in pairs.indexed) {
      b.writeln(
        '    [${p.aFrom},${p.aTo},${p.bFrom},${p.bTo}]'
        '${i < pairs.length - 1 ? ',' : ''}',
      );
    }
    b
      ..writeln('  ]')
      ..writeln('}');
    return b.toString();
  }
}

/// Words of the text with keys from the built-in normalizer of
/// docs/tz 10.1 — derived data must not depend on a model.
List<Word> textWords(List<AyahSpan> ayahs, List<String> wordTexts) => [
      for (final a in ayahs)
        for (var i = 0; i < a.wordCount; i++)
          Word(
            key: WordKey(a.surah, a.ayah, i + 1),
            index: a.firstWordIndex + i,
            text: wordTexts[a.firstWordIndex - 1 + i],
          ),
    ];

/// Builds passages and similar places for [words] (the whole text, in
/// order) grouped by [ayahs], with [layout] where pages are known.
DerivedContent deriveContent({
  required List<AyahSpan> ayahs,
  required List<Word> words,
  required Map<int, WordPlace> layout,
  required int linesPerPage,
  required DerivedParams params,
}) {
  final text = InMemoryQuranText(
    words: words,
    normalizers: [Normalizer.builtIn],
    params: SearchParams.defaults,
  );
  return DerivedContent(
    params: params,
    passages: buildPassages(
      ayahs,
      layout,
      linesPerPage: linesPerPage,
      params: params,
    ),
    pairs: findSimilarPlaces(
      words,
      text.keysFor(Normalizer.builtIn.id),
      params.similar,
    ),
  );
}

/// Ayah spans of [words] (the whole text, in order).
List<AyahSpan> ayahSpansOf(List<Word> words) {
  final spans = <AyahSpan>[];
  for (final w in words) {
    final last = spans.lastOrNull;
    if (last != null && last.surah == w.key.surah && last.ayah == w.key.ayah) {
      spans.last = AyahSpan(
        surah: last.surah,
        ayah: last.ayah,
        firstWordIndex: last.firstWordIndex,
        wordCount: last.wordCount + 1,
      );
    } else {
      spans.add(
        AyahSpan(
          surah: w.key.surah,
          ayah: w.key.ayah,
          firstWordIndex: w.index,
          wordCount: 1,
        ),
      );
    }
  }
  return spans;
}

/// Ayah spans of the assembled text.
List<AyahSpan> ayahSpansOfText(QuranTextData text) => [
      for (final a in text.ayahs)
        AyahSpan(
          surah: a.surah,
          ayah: a.ayah,
          firstWordIndex: a.firstWordIndex,
          wordCount: a.words.length,
        ),
    ];

/// Word places of the layout of a build.
Map<int, WordPlace> layoutPlaces(ContentData layout) => {
      for (final w in layout.words)
        w.wordIndex: (page: w.place.page, line: w.place.line),
    };

/// Word places from a pages fixture (`content_p582_583.json`, format 1).
Map<int, WordPlace> layoutPlacesFromJson(String json) {
  final root = jsonDecode(json);
  if (root case {'words': final List<Object?> words}) {
    return {
      for (final w in words)
        if (w
            case {
              'wordIndex': final int index,
              'page': final int page,
              'line': final int line,
            })
          index: (page: page, line: line),
    };
  }
  throw const ContentBuildException('pages JSON has no words');
}

/// A plain-text report: counts, examples by word keys, pairs by surah.
/// Word keys only, never text: the report goes to logs and PRs.
String derivedReport(
  DerivedContent derived,
  List<Word> words, {
  required int bytes,
}) {
  WordKey key(int index) => words[index - 1].key;
  final b = StringBuffer();
  final passages = derived.passages;
  final ayahsIn = <int, int>{};
  for (final p in passages) {
    final n = {
      for (var w = p.from; w <= p.to; w++) (key(w).surah, key(w).ayah),
    }.length;
    ayahsIn[n] = (ayahsIn[n] ?? 0) + 1;
  }
  b
    ..writeln('Passages: ${passages.length}')
    ..writeln(
      '  by ayahs: ${[
        for (final n in ayahsIn.keys.toList()..sort()) '$n → ${ayahsIn[n]}',
      ].join(', ')}',
    );
  final pairs = derived.pairs;
  final whole = pairs.where((p) => p.wholeAyahs).length;
  final cross = pairs.where((p) => key(p.aFrom).surah != key(p.bFrom).surah);
  b
    ..writeln('Similar pairs: ${pairs.length}')
    ..writeln('  repeated whole ayahs: $whole')
    ..writeln('  shared phrases: ${pairs.length - whole}')
    ..writeln('  in different surahs: ${cross.length}');
  final lengths = <String, int>{};
  for (final p in pairs) {
    final bucket = switch (p.length) {
      < 5 => '1–4',
      < 8 => '5–7',
      < 13 => '8–12',
      < 21 => '13–20',
      _ => '21+',
    };
    lengths[bucket] = (lengths[bucket] ?? 0) + 1;
  }
  b.writeln(
    '  by length in words: ${[
      for (final k in ['1–4', '5–7', '8–12', '13–20', '21+'])
        if (lengths[k] != null) '$k → ${lengths[k]}',
    ].join(', ')}',
  );
  final bySurah = <int, int>{};
  for (final p in pairs) {
    for (final s in {key(p.aFrom).surah, key(p.bFrom).surah}) {
      bySurah[s] = (bySurah[s] ?? 0) + 1;
    }
  }
  final top = bySurah.entries.toList()
    ..sort((x, y) => y.value.compareTo(x.value));
  b
    ..writeln(
      '  surahs with most pairs: '
      '${top.take(10).map((e) => '${e.key} (${e.value})').join(', ')}',
    )
    ..writeln('  surahs without pairs: ${114 - bySurah.length}')
    ..writeln('Examples (word keys):');
  final examples = [
    ...pairs.where((p) => p.wholeAyahs).take(3),
    ...cross.where((p) => !p.wholeAyahs).take(5),
  ];
  for (final p in examples) {
    b.writeln(
      '  ${key(p.aFrom)}–${key(p.aTo)} ~ ${key(p.bFrom)}–${key(p.bTo)}'
      '${p.wholeAyahs ? ' (whole ayah)' : ''}',
    );
  }
  b.writeln('derived.json: ${(bytes / 1024).toStringAsFixed(0)} KB');
  return b.toString();
}
