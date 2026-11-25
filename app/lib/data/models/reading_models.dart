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

/// Where a written reading is stored: ids for later actions in «Разбор».
final class RecordedReading {
  /// Creates the record.
  RecordedReading({
    required this.sessionId,
    required Map<String, String> eventIds,
    this.unitId,
  }) : eventIds = Map.unmodifiable(eventIds);

  /// Stored session id.
  final String sessionId;

  /// Stored check event id by the event id of the session.
  final Map<String, String> eventIds;

  /// Plan unit the reading was for, if any.
  final String? unitId;
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

/// Answer of a self-check (docs/tz 13.7, СП-01).
enum SelfCheckAnswer {
  /// «Вспомнил».
  remembered,

  /// «С трудом».
  withDifficulty,

  /// «Не вспомнил».
  forgotten,
}

/// A passage checked without voice (СП-01…03).
final class SelfCheckResult {
  /// Creates the result.
  const SelfCheckResult({
    required this.from,
    required this.to,
    required this.answer,
    required this.startedAt,
    required this.duration,
    this.stepId,
  });

  /// Step of “Today”, if any.
  final String? stepId;

  /// First word.
  final WordKey from;

  /// Last word.
  final WordKey to;

  /// How it went.
  final SelfCheckAnswer answer;

  /// When the check started.
  final DateTime startedAt;

  /// How long it took.
  final Duration duration;
}

/// Kinds of steps in learning a new passage (docs/tz ЗН-01, ЗН-03).
enum LearnStepKind {
  /// «Послушайте чтеца» — unavailable until reciter audio is licensed.
  listen,

  /// «Прочитайте по тексту».
  supported,

  /// «Попробуйте вспомнить»: repeats until clean without hints.
  recall,

  /// «Проверьте себя»: one clean reading learns the passage (ЗН-02).
  test,

  /// The junction with the previous passage (ЗН-03).
  junction,

  /// Both passages in a row (ЗН-03).
  combined,
}

/// One step of learning, with its words.
final class LearnStep {
  /// Creates the step.
  const LearnStep({required this.kind, required this.from, required this.to});

  /// What to do.
  final LearnStepKind kind;

  /// First word.
  final WordKey from;

  /// Last word.
  final WordKey to;
}

/// How a new passage is learned (13.6).
final class LearnPlan {
  /// Creates the plan.
  LearnPlan({
    required this.unitId,
    required this.from,
    required this.to,
    required List<LearnStep> steps,
    required this.startIndex,
  }) : steps = List.unmodifiable(steps);

  /// The plan unit of the passage.
  final String unitId;

  /// First word of the passage.
  final WordKey from;

  /// Last word of the passage.
  final WordKey to;

  /// Steps in order.
  final List<LearnStep> steps;

  /// Where an unfinished learning continues (ЗН-04).
  final int startIndex;
}

/// Memory state of a passage (docs/tz 11.1, КП-01).
enum MemoryStatus {
  /// Not read yet.
  notStarted,

  /// «Ознакомился»: only listened or read with support.
  introduced,

  /// «С помощью»: the last attempt needed hints (or had a mistake).
  withHelp,

  /// «Самостоятельно»: the last attempt was clean.
  independent,

  /// «Подтвердил позже»: two clean attempts at least a day apart.
  confirmed,

  /// «Давно не проверял»: overdue or likely forgotten.
  stale,

  /// «Есть трудное место».
  hardSpot,
}

/// How the last check was done (КП-02).
enum LastCheckMethod {
  /// By voice.
  voice,

  /// Self-check.
  self,

  /// By a listener.
  listener,
}

/// One passage on the progress screen (КП-04).
final class PassageProgress {
  /// Creates the passage.
  const PassageProgress({
    required this.unitId,
    required this.from,
    required this.to,
    required this.status,
    required this.hints,
    required this.hardSpots,
    this.lastCheckAt,
    this.lastMethod,
  });

  /// Plan unit.
  final String unitId;

  /// First word.
  final WordKey from;

  /// Last word.
  final WordKey to;

  /// Memory state.
  final MemoryStatus status;

  /// Hints taken over all attempts.
  final int hints;

  /// Open hard spots in the passage.
  final int hardSpots;

  /// When it was last checked.
  final DateTime? lastCheckAt;

  /// How it was last checked.
  final LastCheckMethod? lastMethod;
}

/// One surah on the progress grid (13.12): no overall percent (КП-03).
final class SurahProgress {
  /// Creates the surah.
  SurahProgress({required this.surah, required List<PassageProgress> passages})
    : passages = List.unmodifiable(passages);

  /// Surah number.
  final int surah;

  /// Its passages in the plan, in order.
  final List<PassageProgress> passages;

  /// The state the grid shows: what needs attention first.
  MemoryStatus get status {
    if (passages.isEmpty) return MemoryStatus.notStarted;
    const order = [
      MemoryStatus.hardSpot,
      MemoryStatus.stale,
      MemoryStatus.withHelp,
      MemoryStatus.introduced,
      MemoryStatus.notStarted,
      MemoryStatus.independent,
      MemoryStatus.confirmed,
    ];
    return order.firstWhere((s) => passages.any((p) => p.status == s));
  }
}
