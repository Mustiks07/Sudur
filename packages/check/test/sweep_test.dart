import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';

import 'helpers.dart';

// Sweeps over surah 78, as in P06. Each case reads the whole surah once,
// ayah by ayah, with one change, then the session ends.

List<CheckEvent> runWith(List<(Word, String)> reading) =>
    runCheck(byAyah(reading)).events;

/// Positions with at least confirmContextWords + window words after them,
/// so a mistake can be confirmed before the session ends.
Iterable<int> confirmable() sync* {
  for (var i = 1; i < surah78.length - 4; i++) {
    yield i;
  }
}

String describe(List<CheckEvent> events) =>
    [for (final e in events) '${e.kind.name} ${e.words}'].join('; ');

void main() {
  test('skipping any word: omission confirmed there, nothing else', () {
    final failures = <String>[];
    for (final i in confirmable()) {
      final events = runWith([
        for (final (j, w) in surah78.indexed)
          if (j != i) (w, heard(w)),
      ]);
      final confirmed = confirmedMistakes(events);
      final ok = confirmed.length == 1 &&
          confirmed.single.kind == CheckKind.omission &&
          confirmed.single.words.single == surah78[i].key;
      if (!ok) {
        failures.add('${surah78[i].key}: ${describe(confirmed)}');
      }
    }
    expect(failures, isEmpty, reason: '${failures.length} places');
  });

  test('replacing any word by an unrelated one: substitution confirmed', () {
    final failures = <String>[];
    for (final i in confirmable()) {
      final events = runWith([
        for (final (j, w) in surah78.indexed)
          (w, j == i ? unrelatedTo(w) : heard(w)),
      ]);
      final confirmed = confirmedMistakes(events);
      final ok = confirmed.length == 1 &&
          confirmed.single.kind == CheckKind.substitution &&
          confirmed.single.words.single == surah78[i].key;
      if (!ok) {
        failures.add('${surah78[i].key}: ${describe(confirmed)}');
      }
    }
    expect(failures, isEmpty, reason: '${failures.length} places');
  });

  test('a misread word corrected at once, anywhere: corrected, no mistake', () {
    final failures = <String>[];
    for (final i in confirmable()) {
      final w = surah78[i];
      final events = runWith([
        for (final (j, x) in surah78.indexed) ...[
          if (j == i) (x, misread(w, low: 0.4, high: 0.85)),
          (x, heard(x)),
        ],
      ]);
      final corrected = [
        for (final e in finals(events).values)
          if (e.state == CheckState.corrected) e,
      ];
      final ok = confirmedMistakes(events).isEmpty &&
          corrected.any((e) => e.words.contains(w.key));
      if (!ok) {
        failures.add(
          '${w.key}: confirmed ${describe(confirmedMistakes(events))}, '
          'corrected ${describe(corrected)}',
        );
      }
    }
    expect(failures, isEmpty, reason: '${failures.length} places');
  });
}
