import 'dart:convert';

// The class names keep the immutable model easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';

/// One ayah of the canonical text: where its words are in the whole Quran.
@immutable
final class CanonAyah {
  /// Creates the ayah span.
  const CanonAyah({
    required this.surah,
    required this.ayah,
    required this.firstWordIndex,
    required this.wordCount,
  });

  /// Surah number, 1–114.
  final int surah;

  /// Ayah number in the surah.
  final int ayah;

  /// `word_index` of its first word (docs/tz 12.1: running number, from 1).
  final int firstWordIndex;

  /// Number of words.
  final int wordCount;

  /// `word_index` of its last word.
  int get lastWordIndex => firstWordIndex + wordCount - 1;
}

/// A default passage (docs/tz 3.4, D01): words [fromWordIndex]–[toWordIndex].
@immutable
final class CanonPassage {
  /// Creates the passage.
  const CanonPassage({
    required this.surah,
    required this.fromWordIndex,
    required this.toWordIndex,
  });

  /// Surah of every word of the passage.
  final int surah;

  /// First `word_index`.
  final int fromWordIndex;

  /// Last `word_index`, inclusive.
  final int toWordIndex;
}

/// A pair of similar places from D01 (`similar_pair`, not yet checked by a
/// specialist): word ranges [aFrom]–[aTo] and [bFrom]–[bTo].
@immutable
final class CanonSimilarPair {
  /// Creates the pair.
  const CanonSimilarPair(this.aFrom, this.aTo, this.bFrom, this.bTo);

  /// First place.
  final int aFrom;

  /// End of the first place.
  final int aTo;

  /// Second place.
  final int bFrom;

  /// End of the second place.
  final int bTo;
}

/// Where every ayah and default passage is in the canonical text.
///
/// Holds positions only, never the Arabic words: screens read the text
/// itself from the content package.
@immutable
final class CanonIndex {
  const CanonIndex._(
    this._ayahs,
    this._passages,
    this._surahStarts, [
    this._similar = const [],
  ]);

  /// Reads the whole-Quran text JSON (format 2, ADR 0004) and the derived
  /// content JSON (D01). Throws [FormatException] if either is not in that
  /// format or if they were built from different texts.
  factory CanonIndex.parse(String textJson, String derivedJson) {
    final text = _object(jsonDecode(textJson), 'text');
    if (text['format'] != _textFormat || text['kind'] != 'text') {
      throw const FormatException('Expected the text JSON, format 2.');
    }
    final version = _object(text['contentVersion'], 'contentVersion');
    final canonSha256 = version['canonSha256'];
    final rawAyahs = text['ayahs'];
    if (rawAyahs is! List<Object?>) {
      throw const FormatException('"ayahs" must be a list.');
    }
    final ayahs = <CanonAyah>[];
    final surahStarts = <int, int>{};
    var next = 1;
    for (final entry in rawAyahs) {
      if (entry case [final int surah, final int ayah, final List<Object?> w]
          when w.isNotEmpty) {
        final previous = ayahs.isEmpty ? null : ayahs.last;
        final inOrder = previous == null
            ? surah == 1 && ayah == 1
            : (surah == previous.surah && ayah == previous.ayah + 1) ||
                  (surah == previous.surah + 1 && ayah == 1);
        if (!inOrder) {
          throw FormatException('Ayah $surah:$ayah is out of order.');
        }
        if (ayah == 1) surahStarts[surah] = ayahs.length;
        ayahs.add(
          CanonAyah(
            surah: surah,
            ayah: ayah,
            firstWordIndex: next,
            wordCount: w.length,
          ),
        );
        next += w.length;
      } else {
        throw const FormatException('Each ayah must be [surah, ayah, words].');
      }
    }
    if (surahStarts.length != surahCount) {
      throw const FormatException('The text must hold all 114 surahs.');
    }

    final derived = _object(jsonDecode(derivedJson), 'derived');
    if (derived['format'] != _derivedFormat || derived['kind'] != 'derived') {
      throw const FormatException('Expected the derived JSON, format 1.');
    }
    if (canonSha256 is! String || derived['textCanonSha256'] != canonSha256) {
      throw const FormatException('Passages were built from another text.');
    }
    final rawPassages = derived['passages'];
    if (rawPassages is! List<Object?>) {
      throw const FormatException('"passages" must be a list.');
    }
    final index = CanonIndex._(ayahs, const [], surahStarts);
    final passages = <CanonPassage>[];
    var expected = 1;
    for (final entry in rawPassages) {
      if (entry case [final int from, final int to]
          when from == expected && to >= from && to < next) {
        final surah = index.keyOf(from).surah;
        if (index.keyOf(to).surah != surah) {
          throw FormatException('Passage $from–$to crosses a surah.');
        }
        passages.add(
          CanonPassage(surah: surah, fromWordIndex: from, toWordIndex: to),
        );
        expected = to + 1;
      } else {
        throw FormatException('Passages must cover the text in order: $entry');
      }
    }
    if (expected != next) {
      throw const FormatException('Passages do not cover the whole text.');
    }
    final similar = <CanonSimilarPair>[
      for (final entry in switch (derived['similarPairs']) {
        final List<Object?> list => list,
        _ => const <Object?>[],
      })
        if (entry case [final int a, final int aTo, final int b, final int bTo]
            when a <= aTo && b <= bTo && bTo < next)
          CanonSimilarPair(a, aTo, b, bTo),
    ];
    return CanonIndex._(
      List.unmodifiable(ayahs),
      List.unmodifiable(passages),
      Map.unmodifiable(surahStarts),
      List.unmodifiable(similar),
    );
  }

  /// Number of surahs in the Quran.
  static const int surahCount = 114;

  static const int _textFormat = 2;
  static const int _derivedFormat = 1;

  final List<CanonAyah> _ayahs;
  final List<CanonPassage> _passages;
  final Map<int, int> _surahStarts;
  final List<CanonSimilarPair> _similar;

  /// The other place of every similar pair that overlaps [from]–[to].
  List<(int, int)> similarTo(int from, int to) => [
    for (final pair in _similar)
      if (pair.aFrom <= to && from <= pair.aTo)
        (pair.bFrom, pair.bTo)
      else if (pair.bFrom <= to && from <= pair.bTo)
        (pair.aFrom, pair.aTo),
  ];

  /// The ayah that holds `word_index` [wordIndex].
  CanonAyah ayahOf(int wordIndex) {
    final key = keyOf(wordIndex);
    return ayahsOf(key.surah)[key.ayah - 1];
  }

  /// Number of words in the text.
  int get wordCount => _ayahs.last.lastWordIndex;

  /// Ayahs of [surah] in order. Throws [RangeError] for a wrong number.
  List<CanonAyah> ayahsOf(int surah) {
    final start = _surahStarts[surah];
    if (start == null) throw RangeError.range(surah, 1, surahCount, 'surah');
    final end = _surahStarts[surah + 1] ?? _ayahs.length;
    return _ayahs.sublist(start, end);
  }

  /// Default passages of [surah] in order.
  List<CanonPassage> passagesOf(int surah) {
    ayahsOf(surah); // Checks the number.
    return [
      for (final p in _passages)
        if (p.surah == surah) p,
    ];
  }

  /// The word at `word_index` [wordIndex].
  WordKey keyOf(int wordIndex) {
    if (wordIndex < 1 || wordIndex > wordCount) {
      throw RangeError.range(wordIndex, 1, wordCount, 'wordIndex');
    }
    var low = 0;
    var high = _ayahs.length - 1;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (_ayahs[middle].firstWordIndex <= wordIndex) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    final ayah = _ayahs[low];
    return WordKey(ayah.surah, ayah.ayah, wordIndex - ayah.firstWordIndex + 1);
  }

  /// `word_index` of [key]. Throws [RangeError] if the text has no such word.
  int indexOf(WordKey key) {
    final ayahs = ayahsOf(key.surah);
    if (key.ayah < 1 || key.ayah > ayahs.length) {
      throw RangeError.range(key.ayah, 1, ayahs.length, 'ayah');
    }
    final ayah = ayahs[key.ayah - 1];
    if (key.word < 1 || key.word > ayah.wordCount) {
      throw RangeError.range(key.word, 1, ayah.wordCount, 'word');
    }
    return ayah.firstWordIndex + key.word - 1;
  }
}

Map<String, Object?> _object(Object? value, String name) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$name must be a JSON object.');
}
