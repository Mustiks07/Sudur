import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:lessons/lessons.dart';
import 'package:test/test.dart';

import 'helpers.dart';

// The fixture JSON has a known shape: `!` on its fields cannot fail.

/// Parses the fixture after [change] and returns the error.
LessonFormatException brokenBy(
  void Function(Map<String, Object?> json) change,
) {
  final json = fixtureJson();
  change(json);
  return switch (parseLessonPackage(jsonEncode(json))) {
    Ok() => fail('the broken package was accepted'),
    Error(:final error) => error as LessonFormatException,
  };
}

Map<String, Object?> lesson(Map<String, Object?> json, int i) =>
    (json['lessons']! as List<Object?>)[i]! as Map<String, Object?>;

Map<String, Object?> step(Map<String, Object?> json, int l, String id) =>
    (lesson(json, l)['steps']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .firstWhere((s) => s['id'] == id);

void main() {
  group('test package', () {
    test('has an example of every step type (УЧ-03)', () {
      final types = {
        for (final l in fixture().lessons)
          for (final s in l.steps) s.type,
      };
      expect(types, StepType.values.toSet());
    });

    test('reads lessons, skills and the quiz', () {
      final p = fixture();
      expect(p.packageId, 'test-stage1');
      expect(p.stage, 1);
      expect(p.lessons.map((l) => l.id), ['test-stage1-01', 'test-stage1-02']);
      final first = p.lessons.first;
      expect(first.skills, ['letter:alif', 'letter:ba']);
      expect(first.quiz?.stepIds, hasLength(5));
      expect(first.quiz?.passPercent, isNull);
      expect(p.lessons.last.quiz?.passPercent, 100);
      final rule = p.lessons.last.step('rule-78')! as FindRuleStep; // Fixture.
      expect(rule.answerWords, [const WordKey(78, 2, 2)]);
    });

    test('placeholders are listed and block a release', () {
      final p = fixture();
      expect(p.isReleaseReady, isFalse);
      expect(p.todoPaths, contains(r'$.title.ru'));
      expect(p.todoPaths, contains(r'$.lessons[0].steps[0].text.en'));
    });

    test('lists package files for the installer', () {
      expect(
        fixture().media,
        containsAll(['img/ba.png', 'aud/ba.ogg', 'aud/ta.ogg', 'aud/alif.ogg']),
      );
    });

    test('a package without placeholders is release ready', () {
      final json = {
        'format': 1,
        'kind': 'lessons',
        'packageId': 'p',
        'version': '1',
        'stage': 2,
        'title': {'ru': 'a', 'kk': 'b', 'uz': 'c', 'en': 'd'},
        'lessons': [
          {
            'lessonId': 'l1',
            'title': {'ru': 'a', 'kk': 'b', 'uz': 'c', 'en': 'd'},
            'skills': ['haraka:fatha'],
            'steps': [
              {'id': 's1', 'type': 'repeatAndCompare', 'audio': 'a.ogg'},
            ],
          },
        ],
      };
      final p = ok(parseLessonPackage(jsonEncode(json)));
      expect(p.isReleaseReady, isTrue);
      expect(p.lessons.single.quiz, isNull);
    });
  });

  group('a broken package gives a clear error, not a crash', () {
    test('not JSON', () {
      final r = parseLessonPackage('{not json');
      expect(r, isA<Error<LessonPackage>>());
      expect((r as Error).error.toString(), contains('not JSON'));
    });

    test('not an object', () {
      final r = parseLessonPackage('[1, 2]');
      expect((r as Error).error, isA<LessonFormatException>());
    });

    final cases =
        <String, (void Function(Map<String, Object?>), String, String)>{
      'unsupported format': (
        (j) => j['format'] = 2,
        r'$.format',
        'format 2 is not supported',
      ),
      'wrong kind': ((j) => j['kind'] = 'text', r'$.kind', 'lessons'),
      'unknown field': ((j) => j['extra'] = 1, r'$.extra', 'unknown field'),
      'missing field': ((j) => j.remove('version'), r'$.version', 'missing'),
      'wrong type': ((j) => j['stage'] = '1', r'$.stage', 'integer'),
      'no lessons': ((j) => j['lessons'] = <Object?>[], r'$.lessons', 'empty'),
      'missing language': (
        (j) => (j['title']! as Map<String, Object?>).remove('en'),
        r'$.title.en',
        'missing',
      ),
      'duplicate lesson id': (
        (j) => lesson(j, 1)['lessonId'] = 'test-stage1-01',
        r'$.lessons[1].lessonId',
        'duplicate',
      ),
      'bad skill id': (
        (j) => lesson(j, 0)['skills'] = ['Letter BA'],
        r'$.lessons[0].skills[0]',
        'kind:name',
      ),
      'unknown step type': (
        (j) => step(j, 0, 'listen-ba')['type'] = 'dance',
        r'$.lessons[0].steps[1].type',
        'unknown step type "dance"',
      ),
      'field of another step type': (
        (j) => step(j, 0, 'listen-ba')['options'] = ['a', 'b'],
        r'$.lessons[0].steps[1].options',
        'unknown field',
      ),
      'duplicate step id': (
        (j) => step(j, 0, 'listen-ba')['id'] = 'explain-ba',
        r'$.lessons[0].steps[1].id',
        'duplicate step id',
      ),
      'answer not among options': (
        (j) => step(j, 0, 'hear-ba')['answer'] = 'x',
        r'$.lessons[0].steps[3].answer',
        'not one of the choices',
      ),
      'one option only': (
        (j) => step(j, 0, 'hear-ba')['options'] = ['x'],
        r'$.lessons[0].steps[3].options',
        'at least 2',
      ),
      'same option twice': (
        (j) => step(j, 0, 'hear-ba')['options'] = ['x', 'x'],
        r'$.lessons[0].steps[3].options',
        'different',
      ),
      'pair of three': (
        (j) => step(j, 0, 'pair-alif-ba')['pair'] = ['a', 'b', 'c'],
        r'$.lessons[0].steps[5].pair',
        'exactly 2',
      ),
      'unknown letter position': (
        (j) => step(j, 0, 'form-ba')['position'] = 'top',
        r'$.lessons[0].steps[6].position',
        'initial, medial, final, isolated',
      ),
      'target cannot be built': (
        (j) => step(j, 0, 'build-ba-fatha')['pieces'] = ['x', 'y'],
        r'$.lessons[0].steps[7].pieces',
        'cannot be built',
      ),
      'media path leaves the package': (
        (j) => step(j, 0, 'explain-ba')['audio'] = '../secret.ogg',
        r'$.lessons[0].steps[0].audio',
        'inside the package',
      ),
      'absolute media path': (
        (j) => step(j, 0, 'explain-ba')['image'] = '/etc/x.png',
        r'$.lessons[0].steps[0].image',
        'inside the package',
      ),
      'media URL': (
        (j) => step(j, 0, 'see-ba')['optionsAudio'] = ['https://x/a.ogg', 'b'],
        r'$.lessons[0].steps[4].optionsAudio[0]',
        'inside the package',
      ),
      'quiz not last': (
        (j) {
          final steps = lesson(j, 1)['steps']! as List<Object?>;
          steps.insert(0, steps.removeLast());
        },
        r'$.lessons[1].steps[0]',
        'last step',
      ),
      'quiz asks a missing step': (
        (j) => step(j, 1, 'quiz')['stepIds'] = ['nope'],
        r'$.lessons[1].steps[4].stepIds[0]',
        'no step "nope"',
      ),
      'quiz asks a step without a right answer': (
        (j) => step(j, 1, 'quiz')['stepIds'] = ['explain-rule'],
        r'$.lessons[1].steps[4].stepIds[0]',
        'no right answer',
      ),
      'quiz pass mark out of range': (
        (j) => step(j, 1, 'quiz')['passPercent'] = 120,
        r'$.lessons[1].steps[4].passPercent',
        '0..100',
      ),
      'malformed word key': (
        (j) => step(j, 1, 'read-78')['from'] = '78-1-1',
        r'$.lessons[1].steps[1].from',
        'surah:ayah:word',
      ),
      'word key out of range': (
        (j) => step(j, 1, 'read-78')['from'] = '115:1:1',
        r'$.lessons[1].steps[1].from',
        'out of range',
      ),
      'range backwards': (
        (j) => step(j, 1, 'read-78')['to'] = '77:1:1',
        r'$.lessons[1].steps[1].to',
        'before',
      ),
      'rule word outside the range': (
        (j) => step(j, 1, 'rule-78')['answerWords'] = ['78:5:1'],
        r'$.lessons[1].steps[2].answerWords[0]',
        'outside',
      ),
      'empty text': (
        (j) => step(j, 1, 'explain-rule')['text'] = {
              'ru': '',
              'kk': 'b',
              'uz': 'c',
              'en': 'd',
            },
        r'$.lessons[1].steps[0].text.ru',
        'non-empty',
      ),
    };
    for (final MapEntry(key: name, value: (change, path, message))
        in cases.entries) {
      test(name, () {
        final e = brokenBy(change);
        expect(e.path, path);
        expect(e.message, contains(message));
      });
    }
  });
}
