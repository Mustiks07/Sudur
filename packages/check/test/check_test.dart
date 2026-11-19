import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:follow/follow.dart';
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

import 'helpers.dart';

void main() {
  test('clean reading of surah 78: no mistake confirmed', () {
    final r = runCheck(byAyah(clean(surah78)));
    expect(confirmedMistakes(r.events), isEmpty);
    expect(
      finals(r.events).values.where((e) => e.state == CheckState.preliminary),
      isEmpty,
    );
  });

  group('docs/tz 14.2, check', () {
    test('omission, then 2 correct words → confirmed', () {
      final words = ayahs(78, 12, 14);
      final skipped = words[4];
      final r = runCheck(
        byAyah(clean([...words.take(4), ...words.skip(5)])),
        to: words.last.key,
      );
      final omission = finalOf(
        r.events,
        CheckKind.omission,
        CheckState.confirmed,
      );
      expect(omission.single.words, [skipped.key]);
      expect(omission.single.expectedText, skipped.text);
      expect(confirmedMistakes(r.events), hasLength(1));
    });

    test('omission, then the session ends → unverified', () {
      // An ayah whose second-to-last word can be skipped unambiguously.
      final words = [
        for (var a = 1; a <= 40; a++)
          if (ayah(78, a).length >= 3 &&
              cleanSkip(ayah(78, a), ayah(78, a).length - 2))
            ayah(78, a),
      ].first;
      final read = [...words.take(words.length - 2), words.last];
      final r = runCheck(
        byAyah(clean(read)),
        from: words.first.key,
        to: words.last.key,
      );
      final omission = finals(
        r.events,
      ).values.singleWhere((e) => e.kind == CheckKind.omission);
      expect(omission.words, [words[words.length - 2].key]);
      expect(omission.state, CheckState.unverified);
    });

    test('a different word (similarity < 0.6), then 2 correct → confirmed', () {
      final words = ayahs(78, 12, 14);
      for (final wrong in [
        unrelatedTo(words[4]), // below simFloor: extra word + skip
        misread(words[4], low: 0.4, high: 0.6), // weak match
      ]) {
        final reading = [
          for (final (i, w) in words.indexed) (w, i == 4 ? wrong : heard(w)),
        ];
        final r = runCheck(byAyah(reading), to: words.last.key);
        final sub = finalOf(
          r.events,
          CheckKind.substitution,
          CheckState.confirmed,
        );
        expect(sub.single.words, [words[4].key], reason: wrong);
        expect(sub.single.heardText, wrong, reason: 'ПО-13: as heard');
        expect(confirmedMistakes(r.events), hasLength(1), reason: wrong);
      }
    });

    test('a similar word (0.6–0.85) → unverified, never confirmed', () {
      final words = ayahs(78, 12, 14);
      final wrong = misread(words[4], low: 0.6, high: 0.85);
      final reading = [
        for (final (i, w) in words.indexed) (w, i == 4 ? wrong : heard(w)),
      ];
      final r = runCheck(byAyah(reading), to: words.last.key);
      expect(confirmedMistakes(r.events), isEmpty);
      final event = finals(r.events).values.singleWhere(
            (e) =>
                e.words.contains(words[4].key) &&
                e.kind != CheckKind.repetition,
          );
      expect(event.state, CheckState.unverified);
      expect(event.heardText, wrong);
    });

    test('a mistake corrected within 2.5 s → corrected', () {
      final words = ayahs(78, 12, 14);
      final wrong = misread(words[4], low: 0.4, high: 0.6);
      final reading = [
        for (final (i, w) in words.indexed) ...[
          if (i == 4) (w, wrong),
          (w, heard(w)),
        ],
      ];
      final r = runCheck(byAyah(reading), to: words.last.key);
      expect(confirmedMistakes(r.events), isEmpty);
      final corrected = finalOf(
        r.events,
        CheckKind.substitution,
        CheckState.corrected,
      );
      expect(corrected.single.words, [words[4].key]);
    });

    test('an omission corrected by going back → corrected', () {
      final i = [
        for (var i = 1; i < surah78.length - 3; i++)
          if (cleanSkip(surah78, i)) i,
      ].first;
      final words = surah78.sublist(0, i + 4);
      // Skip word i, read i + 1, go back: i, i + 1, then on.
      final reading = [
        ...clean(words.sublist(0, i)),
        (words[i + 1], heard(words[i + 1])),
        ...clean(words.sublist(i)),
      ];
      final r = runCheck(byAyah(reading), to: words.last.key);
      expect(confirmedMistakes(r.events), isEmpty);
      expect(
        finalOf(r.events, CheckKind.omission, CheckState.corrected)
            .single
            .words,
        [words[i].key],
      );
    });

    test('bad sound on the word → unverified', () {
      final words = ayahs(78, 12, 14);
      final reading = [
        for (final (i, w) in words.indexed)
          (w, i == 4 ? unrelatedTo(w) : heard(w)),
      ];
      final script = byAyah(reading);
      final r = runCheck(
        script,
        to: words.last.key,
        afterEach: (checker, result) {
          if (identical(result, script.results.first)) {
            checker.markUnreliable(
              const UnreliableSpan(
                startMs: 0,
                endMs: 1 << 30,
                reason: UnreliableReason.poorSignal,
              ),
            );
          }
        },
      );
      expect(confirmedMistakes(r.events), isEmpty);
      expect(
        finalOf(r.events, CheckKind.substitution, CheckState.unverified),
        hasLength(1),
      );
    });

    test('SignalQuality not ok over the word → unverified (contract event)',
        () {
      final words = ayahs(78, 12, 14);
      final reading = [
        for (final (i, w) in words.indexed)
          (w, i == 4 ? unrelatedTo(w) : heard(w)),
      ];
      final script = byAyah(reading);
      final r = runCheck(
        script,
        to: words.last.key,
        afterEach: (checker, result) {
          if (identical(result, script.results.first)) {
            checker.onSignalQuality(
              const SignalQuality(
                sessionId: 's',
                atMs: 3000,
                sinceMs: 0,
                level: SignalQualityLevel.noisy,
              ),
            );
          }
        },
      );
      expect(confirmedMistakes(r.events), isEmpty);
      expect(
        finalOf(r.events, CheckKind.substitution, CheckState.unverified),
        hasLength(1),
      );
    });

    test('SignalQuality back to ok: later mistakes are confirmed again', () {
      final words = ayahs(78, 12, 14);
      final reading = [
        for (final (i, w) in words.indexed)
          (w, i == 4 ? unrelatedTo(w) : heard(w)),
      ];
      final script = byAyah(reading);
      final r = runCheck(
        script,
        to: words.last.key,
        afterEach: (checker, result) {
          if (identical(result, script.results.first)) {
            checker
              ..onSignalQuality(
                const SignalQuality(
                  sessionId: 's',
                  atMs: 100,
                  level: SignalQualityLevel.tooQuiet,
                ),
              )
              ..onSignalQuality(
                const SignalQuality(
                  sessionId: 's',
                  atMs: 300,
                  level: SignalQualityLevel.ok,
                ),
              );
          }
        },
      );
      expect(
        finalOf(r.events, CheckKind.substitution, CheckState.confirmed)
            .single
            .words,
        [words[4].key],
      );
    });

    test('3 words of another surah in a row → jump confirmed', () {
      final r = runCheck(
        RecognitionScript()
          ..segment([for (final w in ayahs(78, 1, 3)) heard(w)])
          ..segment([for (final w in ayahs(79, 1, 3)) heard(w)]),
      );
      final jump = finalOf(r.events, CheckKind.jump, CheckState.confirmed);
      expect(jump, hasLength(1));
      expect(jump.single.jumpTo?.surah, 79);
      expect(jump.single.words, [ayah(78, 3).last.key]);
    });

    test(
        'words heard just before a jump are part of it, not extra words '
        '(model output)', () {
      // follow sees an extra word, then a few unaligned words, then the
      // jump: an extra-word candidate there would report the place twice.
      final checker = Checker(
        text: quran,
        normalizer: normalizer.id,
        from: surah78.first.key,
        to: surah78.last.key,
        params: CheckParams.defaults,
        sessionId: 's',
        versions: versions,
      );
      var index = 0;
      HeardWord word(String text) {
        final i = index++;
        return HeardWord(
          index: i,
          text: text,
          key: SearchKey(text),
          segmentId: 1,
          atMs: i * 400,
        );
      }

      AlignmentStep match(Word w) => AlignmentStep(
            kind: AlignmentStepKind.match,
            heard: word(heard(w)),
            expected: w.key,
            similarity: 1,
            cost: 0,
          );
      final read = ayahs(78, 1, 2);
      final elsewhere = ayahs(79, 1, 3);
      final events = <CheckEvent>[
        ...checker.accept(path: [for (final w in read) match(w)]).events,
        ...checker.accept(
          path: [
            AlignmentStep(
              kind: AlignmentStepKind.insert,
              heard: word(heard(elsewhere[0])),
              cost: 1,
            ),
            AlignmentStep(
              kind: AlignmentStepKind.unaligned,
              heard: word(heard(elsewhere[1])),
              cost: 1,
            ),
          ],
        ).events,
      ];
      final jumpWords = [for (final w in elsewhere.skip(2)) word(heard(w))];
      events
        ..addAll(
          checker.accept(
            path: const [],
            jumps: [
              JumpCandidate(
                from: read.last.key,
                to: elsewhere[2].key,
                heard: jumpWords,
                matchedNgrams: 1,
              ),
            ],
          ).events,
        )
        // The reader comes back to the passage: on the old rule this
        // context confirmed the extra-word candidate.
        ..addAll(
          checker
              .accept(path: [for (final w in ayahs(78, 3, 4)) match(w)]).events,
        )
        ..addAll(checker.finish(index * 400 + 10000).events);
      final last = <String, CheckEvent>{for (final e in events) e.eventId: e};
      expect(
        last.values.where((e) => e.kind == CheckKind.jump).single.state,
        CheckState.confirmed,
      );
      expect(
        last.values.where(
          (e) =>
              e.kind == CheckKind.insertion && e.state == CheckState.confirmed,
        ),
        isEmpty,
      );
    });

    test('a jump on bad audio → unverified, not confirmed', () {
      for (final reason in UnreliableReason.values) {
        final script = RecognitionScript()
          ..segment([for (final w in ayahs(78, 1, 3)) heard(w)])
          ..segment([for (final w in ayahs(79, 1, 3)) heard(w)]);
        final r = runCheck(
          script,
          afterEach: (checker, result) {
            if (identical(result, script.results.first)) {
              checker.markUnreliable(
                UnreliableSpan(startMs: 0, endMs: 1 << 30, reason: reason),
              );
            }
          },
        );
        final jumps = [
          for (final e in finals(r.events).values)
            if (e.kind == CheckKind.jump) e,
        ];
        expect(jumps.single.state, CheckState.unverified, reason: '$reason');
        expect(confirmedMistakes(r.events), isEmpty, reason: '$reason');
      }
    });

    test('a jump while SignalQuality is not ok → unverified', () {
      final script = RecognitionScript()
        ..segment([for (final w in ayahs(78, 1, 3)) heard(w)])
        ..segment([for (final w in ayahs(79, 1, 3)) heard(w)]);
      final r = runCheck(
        script,
        afterEach: (checker, result) {
          if (identical(result, script.results.first)) {
            checker.onSignalQuality(
              const SignalQuality(
                sessionId: 's',
                atMs: 500,
                sinceMs: 0,
                level: SignalQualityLevel.clipping,
              ),
            );
          }
        },
      );
      final jump = finals(r.events).values.singleWhere(
            (e) => e.kind == CheckKind.jump,
          );
      expect(jump.state, CheckState.unverified);
    });

    test('going back 2 words is a repetition, not a mistake', () {
      final words = ayahs(78, 6, 8);
      final reading = clean(words)..insertAll(5, clean(words.sublist(3, 5)));
      final r = runCheck(byAyah(reading), to: words.last.key);
      expect(confirmedMistakes(r.events), isEmpty);
      expect(
        finals(r.events).values.where((e) => e.kind == CheckKind.repetition),
        isNotEmpty,
      );
    });

    test('strict: wait for the word, offer a hint, stop when read', () {
      final words = ayahs(78, 12, 16);
      final skipped = words[4];
      // Skip word 5. The omission is confirmed once its self-correction
      // window closes (4 words later); 3 more words are failed tries, so a
      // hint is offered; then the reader goes back and reads it.
      final reading = [
        ...clean(words.sublist(0, 4)),
        ...clean(words.sublist(5, 12)),
        (skipped, heard(skipped)),
      ];
      final r = runCheck(
        RecognitionScript()..segment([for (final (_, k) in reading) k]),
        to: words.last.key,
        strict: true,
      );
      expect(r.strict.map((s) => s.runtimeType), [
        WaitForWord,
        OfferHint,
        StopWaiting,
      ]);
      expect(r.strict.every((s) => s.word == skipped.key), isTrue);
      expect((r.strict.last as StopWaiting).how, WaitEnd.read);
    });

    test('strict: a hint ends the wait; the wait times out into a hint', () {
      // Skip word 5 and read only 5 more words: the omission is confirmed,
      // one failed try follows, so the hint comes from the time limit.
      final words = ayahs(78, 12, 14).sublist(0, 10);
      final r = runCheck(
        RecognitionScript()
          ..segment([
            for (final w in [...words.take(4), ...words.skip(5)]) heard(w),
          ]),
        to: words.last.key,
        strict: true,
        finish: false,
      );
      expect(r.strict.first, isA<WaitForWord>());
      final wait = r.strict.first;
      final late = r.checker.tick(
        wait.atMs + CheckParams.defaults.strictMaxWaitMs,
      );
      expect(late.strict.whereType<OfferHint>(), hasLength(1));
      final hint = r.checker.onHint(words[4].key, wait.atMs + 20000);
      expect((hint.strict.single as StopWaiting).how, WaitEnd.hint);
    });

    test('«не согласен» → disputed; only from confirmed', () {
      final words = ayahs(78, 12, 14);
      final r = runCheck(
        byAyah(clean([...words.take(4), ...words.skip(5)])),
        to: words.last.key,
      );
      final omission = finalOf(
        r.events,
        CheckKind.omission,
        CheckState.confirmed,
      ).single;
      final disputed = switch (r.checker.dispute(omission.eventId, 99)) {
        Ok(:final value) => value.events.single,
        Error(:final error) => throw error,
      };
      expect(disputed.state, CheckState.disputed);
      expect(disputed.eventId, omission.eventId);
      expect(r.checker.dispute(omission.eventId, 100), isA<Error<Object>>());
      expect(r.checker.dispute('nope', 100), isA<Error<Object>>());
    });

    test('heard text in every event is raw, never the canon (ПО-13)', () {
      final words = ayahs(78, 12, 14);
      final wrong = unrelatedTo(words[4]);
      final reading = [
        for (final (i, w) in words.indexed) (w, i == 4 ? wrong : heard(w)),
      ];
      final r = runCheck(byAyah(reading), to: words.last.key);
      final canon = {for (final w in words) w.text};
      for (final e in r.events) {
        expect(canon.contains(e.heardText), isFalse, reason: e.eventId);
      }
    });
  });

  group('state machine (docs/tz 10.5)', () {
    test('allowed transitions', () {
      const p = CheckState.preliminary;
      for (final to in [
        CheckState.confirmed,
        CheckState.corrected,
        CheckState.unverified,
      ]) {
        expect(canMove(p, to), isTrue, reason: to.name);
      }
      expect(canMove(CheckState.confirmed, CheckState.disputed), isTrue);
    });

    test('forbidden transitions, including confirmed → corrected', () {
      final allowed = {
        (CheckState.preliminary, CheckState.confirmed),
        (CheckState.preliminary, CheckState.corrected),
        (CheckState.preliminary, CheckState.unverified),
        (CheckState.confirmed, CheckState.disputed),
      };
      for (final from in CheckState.values) {
        for (final to in CheckState.values) {
          expect(
            canMove(from, to),
            allowed.contains((from, to)),
            reason: '${from.name} → ${to.name}',
          );
        }
      }
      expect(canMove(CheckState.confirmed, CheckState.corrected), isFalse);
    });

    test('every emitted change of an event follows the allowed path', () {
      final words = ayahs(78, 12, 20);
      final reading = [
        for (final (i, w) in words.indexed)
          if (i != 3) (w, i == 9 ? unrelatedTo(w) : heard(w)),
      ];
      final r = runCheck(byAyah(reading), to: words.last.key);
      final last = <String, CheckState>{};
      for (final e in r.events) {
        final before = last[e.eventId];
        if (before != null) {
          expect(canMove(before, e.state), isTrue, reason: e.eventId);
        }
        last[e.eventId] = e.state;
      }
    });
  });

  group('hesitation (docs/tz 10.5)', () {
    test('a long pause inside an ayah is a signal, not a mistake', () {
      final words = ayah(78, 38);
      final r = runCheck(
        RecognitionScript()..segment([for (final w in words.take(4)) heard(w)]),
        to: words.last.key,
        from: words.first.key,
        finish: false,
      );
      final checker = r.checker;
      // Short pauses build the personal median, then a long one.
      for (var i = 0; i < 3; i++) {
        expect(
          checker
              .onPause(SpeechPause(startMs: i * 1000, endMs: i * 1000 + 300))
              .events,
          isEmpty,
        );
      }
      final long = checker.onPause(
        const SpeechPause(startMs: 10000, endMs: 13000),
      );
      final e = long.events.single;
      expect(e.kind, CheckKind.hesitation);
      expect(e.words, [words[4].key]);
      expect(e.versions.rulesVersion, 'test'); // ПО-11
    });
  });

  test('CheckParams.fromJson keeps defaults for missing keys', () {
    final p = CheckParams.fromJson(const {'strongMatch': 0.9});
    expect(p.strongMatch, 0.9);
    expect(p.confirmContextWords, CheckParams.defaults.confirmContextWords);
    expect(
      () => CheckParams.fromJson(const {'jumpMinWords': 'x'}),
      throwsFormatException,
    );
    expect(FollowParams.defaults.simFloor, lessThan(p.strongMatch));
  });
}
