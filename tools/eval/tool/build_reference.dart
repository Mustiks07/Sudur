import 'dart:convert';
import 'dart:io';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:eval/eval.dart';
import 'package:follow/follow.dart';
import 'package:path/path.dart' as p;
import 'package:quran_text/quran_text.dart';
import 'package:testing/testing.dart';

// Builds the reference corpus for the quality gate in CI (docs/tz 5.5,
// C09): synthetic recordings only. The recognized text is what the
// Abdou/quran-asr model outputs — 29 bare letters (docs/tz 12.3,
// `modelLetters`) — and the corpus is evaluated with the model's
// normalizer.json from the spec, so a normalizer that keeps harakat fails
// the gate. Words are picked by their place in the canon. No audio, no
// recordings of people, no typed Arabic.
//
// From tools/eval: dart run tool/build_reference.dart

/// Model id of the synthetic recognition results.
const String referenceModel = 'synthetic';

/// Where the corpus lives, relative to tools/eval.
const String referenceCorpus = 'reference/corpus';

const String _textPath = '../../packages/testing/fixtures/quran_text.json';

/// normalizer.json of the Abdou/quran-asr models, exactly as docs/tz 12.3
/// gives it; the CI gate passes the same file to the evaluation.
const String modelNormalizerPath =
    '../../packages/testing/fixtures/models/normalizer.abdou.json';

/// The model normalizer of [modelNormalizerPath].
Normalizer loadModelNormalizer([String path = modelNormalizerPath]) =>
    switch (Normalizer.fromJson(File(path).readAsStringSync())) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };

void main() {
  final dir = Directory(referenceCorpus);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  for (final r in buildReferenceCorpus(loadText())) {
    File(p.join(dir.path, '${r.id}.ann.json')).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(r.annotationJson())}\n',
    );
    File(p.join(dir.path, '${r.id}.$referenceModel.asr.jsonl'))
        .writeAsStringSync(asrJsonl(r));
  }
  stdout.writeln('reference corpus written to ${dir.path}');
}

/// The recognition results of [r] as `.asr.jsonl` (docs/tz 12.6).
String asrJsonl(SyntheticRecording r) {
  final lines = [
    for (final x in r.script.results) jsonEncode(recognitionResultToJson(x)),
  ];
  return '${lines.join('\n')}\n';
}

/// The whole-Quran text with keys of the model normalizer.
InMemoryQuranText loadText() {
  final words = switch (QuranTextJsonSource(
    File(_textPath).readAsStringSync(),
  ).loadWords()) {
    Ok(:final value) => value,
    Error(:final error) => throw error,
  };
  return InMemoryQuranText(
    words: words,
    normalizers: [loadModelNormalizer()],
    params: SearchParams.defaults,
  );
}

/// The reference recordings, always the same.
List<SyntheticRecording> buildReferenceCorpus(InMemoryQuranText quran) {
  final normalizer = loadModelNormalizer();
  final words = quran.words;
  List<Word> ayah(int s, int a) => [
        for (final w in words)
          if (w.key.surah == s && w.key.ayah == a) w,
      ];
  List<Word> ayahs(int s, int first, int last) => [
        for (var a = first; a <= last; a++) ...ayah(s, a),
      ];

  /// What the model outputs for [w].
  String heard(Word w) => modelLetters(w.text);
  String nearMiss(Word w) {
    final k = heard(w);
    return dropLetter(k, k.runes.length ~/ 2);
  }

  /// A key of surah 78 not similar to [w] and its neighbours.
  String unrelatedTo(Word w) {
    final surah = ayahs(78, 1, 40);
    final i = words.indexOf(w);
    final around = words.sublist(i - 8 < 0 ? 0 : i - 8, i + 6);
    return surah.map(heard).firstWhere(
          (k) => around.every(
            (a) => similarity(k, heard(a)) < FollowParams.defaults.simFloor,
          ),
        );
  }

  /// A canonical key that is like [w] but clearly another word: similarity
  /// above follow's simFloor and below check's substitutionMax, so it is a
  /// confirmed substitution and not «could not verify».
  String lookAlikeWordFor(Word w) {
    final target = heard(w);
    return words.map(heard).firstWhere((k) {
      final sim = similarity(k, target);
      return sim > FollowParams.defaults.simFloor &&
          sim < CheckParams.defaults.substitutionMax;
    });
  }

  SyntheticRecording rec(
    String id,
    String person,
    List<Word> expected, {
    String language = 'kk',
    String gender = 'f',
    String device = 'budget-android',
    String noise = 'quiet',
  }) =>
      SyntheticRecording(
        modelOutput: true,
        id: id,
        speakerId: person,
        from: '${expected.first.key}',
        to: '${expected.last.key}',
        nativeLanguage: language,
        gender: gender,
        device: device,
        noise: noise,
      );

  /// Reads [list] ayah by ayah; [mark] decides what happens to each word.
  void read(
    SyntheticRecording r,
    List<Word> list, [
    void Function(SyntheticRecording r, Word w)? mark,
  ]) {
    int? current;
    for (final w in list) {
      if (current != null && w.key.ayah != current) r.endSegment();
      current = w.key.ayah;
      if (mark != null) {
        mark(r, w);
      } else {
        r.correct('${w.key}', heard(w));
      }
    }
    r.endSegment();
  }

  final out = <SyntheticRecording>[];
  void add(SyntheticRecording r) => out.add(r);

  // 1–2. Clean reading of surah 78.
  add(
    rec('r01-clean-78a', 'p1', ayahs(78, 1, 20))
      ..also((r) => read(r, ayahs(78, 1, 20))),
  );
  add(
    rec(
      'r02-clean-78b',
      'p2',
      ayahs(78, 21, 40),
      language: 'ru',
      gender: 'm',
      device: 'mid-android',
    )..also((r) => read(r, ayahs(78, 21, 40))),
  );

  // 3. Omissions.
  final o = ayahs(78, 1, 15);
  final omit = {o[4].key, o[17].key, o[33].key};
  add(
    rec('r03-omissions', 'p3', o, language: 'uz', device: 'iphone')
      ..also(
        (r) => read(r, o, (r, w) {
          omit.contains(w.key)
              ? r.omitted('${w.key}')
              : r.correct('${w.key}', heard(w));
        }),
      ),
  );

  // 4. Substitutions with unrelated words.
  final s = ayahs(78, 16, 30);
  final sub = {
    s[6].key: unrelatedTo(s[6]),
    s[25].key: unrelatedTo(s[25]),
    s[40].key: lookAlikeWordFor(s[40]),
  };
  add(
    rec('r04-substitutions', 'p4', s, gender: 'm', noise: 'noisy')
      ..also(
        (r) => read(r, s, (r, w) {
          final wrong = sub[w.key];
          wrong != null
              ? r.substituted('${w.key}', wrong)
              : r.correct('${w.key}', heard(w));
        }),
      ),
  );

  // 5. Self-corrections: two in the window, one after it (a new attempt).
  final c = ayahs(78, 31, 40);
  add(
    rec('r05-self-corrections', 'p5', c, language: 'ru', device: 'iphone')
      ..also(
        (r) => read(r, c, (r, w) {
          if (w == c[3] || w == c[20]) {
            r.selfCorrected('${w.key}', nearMiss(w), heard(w));
          } else if (w == c[40]) {
            r.selfCorrected(
              '${w.key}',
              nearMiss(w),
              heard(w),
              between: [heard(c[41]), heard(c[42]), heard(c[43])],
            );
          } else {
            r.correct('${w.key}', heard(w));
          }
        }),
      ),
  );

  // 6. Repeated words and an extra word.
  final rp = ayahs(79, 1, 10);
  add(
    rec('r06-repeats-insertion', 'p6', rp, gender: 'm', noise: 'noisy')
      ..also(
        (r) => read(r, rp, (r, w) {
          if (w == rp[5]) {
            r.repeated('${w.key}', heard(w), times: 3);
          } else {
            r.correct('${w.key}', heard(w));
          }
          if (w == rp[12]) r.inserted('${w.key}', unrelatedTo(rp[12]));
        }),
      ),
  );

  // 7. Hesitation: a long pause inside an ayah, and an unclear word.
  final h = ayah(78, 38);
  add(
    rec('r07-hesitation-unclear', 'p1', h, device: 'mid-android')
      ..also((r) {
        for (final (i, w) in h.indexed) {
          if (i == 6) r.endSegment(pauseMs: 4000);
          i == 9
              ? r.unclear('${w.key}', heard(w))
              : r.correct('${w.key}', heard(w));
        }
        r.endSegment();
      }),
  );

  // 8. Jump to a far surah, then back to the passage.
  final j1 = ayahs(78, 1, 3);
  final j1back = ayahs(78, 4, 10);
  final far = ayah(2, 255).take(8).toList();
  add(
    rec('r08-jump-far', 'p2', [...j1, ...j1back], language: 'uz')
      ..also((r) {
        read(r, j1);
        r
          ..jumped(
            '${j1.last.key}',
            '${far.first.key}',
            far.map(heard).toList(),
          )
          ..endSegment();
        read(r, j1back);
      }),
  );

  // 9. Jump to a look-alike ayah elsewhere, then back.
  final keys = quran.keysFor(normalizer.id);
  final surah78 = ayahs(78, 1, 40);
  final start78 = words.indexOf(surah78.first);
  List<Word>? lookAlike;
  for (var i = surah78.indexWhere((w) => w.key == const WordKey(78, 20, 1));
      i + 4 <= surah78.length && lookAlike == null;
      i++) {
    for (final m in quran.findSimilar(
      keys.sublist(start78 + i, start78 + i + 4),
      normalizer: normalizer.id,
      minSimilarity: FollowParams.defaults.simFloor,
      maxMeanCost: FollowParams.defaults.lostCostThreshold,
    )) {
      if (m.start.surah != 78 &&
          m.meanCost >= FollowParams.defaults.ambiguityMargin) {
        final at = words.indexWhere((w) => w.key == m.start);
        lookAlike = words.sublist(at, at + 4);
        break;
      }
    }
  }
  final like = lookAlike ?? (throw StateError('no look-alike for surah 78'));
  add(
    rec('r09-jump-look-alike', 'p3', [...j1, ...j1back], gender: 'm')
      ..also((r) {
        read(r, j1);
        r
          ..jumped(
            '${j1.last.key}',
            '${like.first.key}',
            like.map(heard).toList(),
          )
          ..endSegment();
        read(r, j1back);
      }),
  );

  // 11. Read correctly, recognized with a letter lost in every third long
  // word (ASR noise): still revealed in place.
  final mh = ayahs(78, 6, 16);
  add(
    rec('r11-misheard-letters', 'p5', mh, gender: 'm', device: 'mid-android')
      ..also(
        (r) => read(r, mh, (r, w) {
          final k = heard(w);
          final i = mh.indexOf(w);
          r.correct(
            '${w.key}',
            i % 3 == 1 && k.runes.length >= 5 ? nearMiss(w) : k,
          );
        }),
      ),
  );

  // 10. Ambiguity: repeated refrain of surah 55, read cleanly.
  final amb = ayahs(55, 1, 30);
  add(
    rec('r10-ambiguity-55', 'p4', amb, language: 'ru', noise: 'noisy')
      ..also((r) => read(r, amb)),
  );

  return out;
}

extension on SyntheticRecording {
  /// Runs [build] on this recording (keeps the corpus list readable).
  void also(void Function(SyntheticRecording r) build) => build(this);
}
