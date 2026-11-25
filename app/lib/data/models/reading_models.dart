import 'package:contracts/contracts.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/services/prototype_session.dart';

// The class names keep the immutable models easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

/// One word of the canonical text, as the content has it.
final class ReadingWord {
  /// Creates the word.
  const ReadingWord({required this.key, required this.text});

  /// Place in the Quran.
  final WordKey key;

  /// Canonical text, unchanged (never written in code).
  final String text;
}

/// One ayah of a passage for the plain text view.
final class ReadingAyah {
  /// Creates the ayah.
  ReadingAyah({
    required this.surah,
    required this.ayah,
    required List<ReadingWord> words,
  }) : words = List.unmodifiable(words);

  /// Surah number.
  final int surah;

  /// Ayah number.
  final int ayah;

  /// Words in reading order.
  final List<ReadingWord> words;
}

/// Limits of the reading screen that come with the model package
/// (docs/tz 12.4, «Проверка»).
final class ReadingLimits {
  /// Creates the limits.
  const ReadingLimits({
    required this.stuckWordTries,
    required this.strictMaxFails,
    required this.strictMaxWaitMs,
  });

  /// Tries over a hidden word before «Открыть без штрафа» (ЭЧ-12).
  final int stuckWordTries;

  /// Failed tries in strict mode before «Подсказать?» (ЭЧ-05).
  final int strictMaxFails;

  /// Wait in strict mode before «Подсказать?» (ЭЧ-05).
  final int strictMaxWaitMs;
}

/// Everything the reading screen needs for one passage.
final class ReadingPassage {
  /// Creates the passage.
  ReadingPassage({
    required this.from,
    required this.to,
    required List<ReadingAyah> ayahs,
    required this.session,
    required this.limits,
    this.pages,
    this.fontFamilies = const {},
  }) : ayahs = List.unmodifiable(ayahs);

  /// First word.
  final WordKey from;

  /// Last word, inclusive.
  final WordKey to;

  /// The passage as text, always available (temporary text view for pages
  /// without layout).
  final List<ReadingAyah> ayahs;

  /// Mushaf pages when the passage is on pages with layout (582–583 in the
  /// prototype, ADR 0002); `null` otherwise.
  final List<MushafPageData>? pages;

  /// Runtime font family per page of [pages].
  final Map<int, String> fontFamilies;

  /// Inputs of a voice session; `null` when the model is not downloaded.
  final PrototypeSessionConfiguration? session;

  /// Limits from the model package; `null` without a model.
  final ReadingLimits? limits;

  /// Words of the passage in reading order.
  List<WordKey> get words => [
    for (final ayah in ayahs)
      for (final word in ayah.words) word.key,
  ];
}

/// How a passage was read, as the screen saw it; written by
/// `AppUserRepository.recordReading` (docs/tz НФ-21, ПЛ-12).
final class ReadingResult {
  /// Creates the result.
  ReadingResult({
    required this.from,
    required this.to,
    required this.mode,
    required this.behavior,
    required this.startedAt,
    required this.duration,
    required List<SessionWordResult> words,
    required Map<HintKind, int> hints,
    required List<CheckEvent> checks,
    required Set<WordKey> unlocked,
    this.stepId,
  }) : words = List.unmodifiable(words),
       hints = Map.unmodifiable(hints),
       checks = List.unmodifiable(checks),
       unlocked = Set.unmodifiable(unlocked);

  /// Step of “Today” that was read, if any.
  final String? stepId;

  /// First word of the passage.
  final WordKey from;

  /// Last word of the passage.
  final WordKey to;

  /// Reading mode.
  final SessionMode mode;

  /// Mistake handling.
  final SessionBehavior behavior;

  /// When reading started.
  final DateTime startedAt;

  /// How long it took.
  final Duration duration;

  /// Outcome of every word (from `SessionFinished`).
  final List<SessionWordResult> words;

  /// Hints taken, by kind.
  final Map<HintKind, int> hints;

  /// Check events in their final state, with text as recognized (ПО-13).
  final List<CheckEvent> checks;

  /// Words opened with «Открыть без штрафа» (ЭЧ-12): not a hint, not an
  /// error; they count as “could not check”.
  final Set<WordKey> unlocked;
}
