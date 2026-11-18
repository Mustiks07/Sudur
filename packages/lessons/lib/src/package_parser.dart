import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:lessons/src/lesson_package.dart';
import 'package:lessons/src/localized_text.dart';
import 'package:lessons/src/steps.dart';

/// A lesson package that cannot be read: where and why.
final class LessonFormatException implements Exception {
  /// Creates the error for the JSON place [path].
  const LessonFormatException(this.path, this.message);

  /// JSON path of the bad value, like `lessons[0].steps[2].answer`.
  final String path;

  /// What is wrong.
  final String message;

  @override
  String toString() => 'Lesson package: $path: $message';
}

/// Reads a lesson package JSON (format [LessonPackage.currentFormat]).
///
/// The reading is strict: unknown fields, missing fields, wrong types, bad
/// references and paths leaving the package are errors with their JSON path.
/// It never throws.
Result<LessonPackage> parseLessonPackage(String source) {
  final Object? json;
  try {
    json = jsonDecode(source);
  } on FormatException catch (e) {
    return Result.error(LessonFormatException(r'$', 'not JSON: ${e.message}'));
  }
  try {
    return Result.ok(_PackageParser().package(json));
  } on LessonFormatException catch (e) {
    return Result.error(e);
  }
}

final class _PackageParser {
  final List<String> _todo = [];

  LessonPackage package(Object? json) {
    final r = _Obj.of(json, r'$', this)
      ..only(const {
        'format',
        'kind',
        'packageId',
        'version',
        'stage',
        'title',
        'lessons',
      });
    final format = r.integer('format');
    if (format != LessonPackage.currentFormat) {
      r.fail(
        'format',
        'format $format is not supported, this app reads format '
            '${LessonPackage.currentFormat}',
      );
    }
    if (r.string('kind') != 'lessons') {
      r.fail('kind', 'must be "lessons"');
    }
    final stage = r.integer('stage');
    if (stage < 1) r.fail('stage', 'must be positive');
    final lessonList = r.list('lessons');
    if (lessonList.isEmpty) r.fail('lessons', 'must not be empty');
    final lessons = <Lesson>[];
    final ids = <String>{};
    for (final (i, l) in lessonList.indexed) {
      final lesson = _lesson(_Obj.of(l, '${r.path}.lessons[$i]', this));
      if (!ids.add(lesson.id)) {
        r.fail('lessons[$i].lessonId', 'duplicate lesson id "${lesson.id}"');
      }
      lessons.add(lesson);
    }
    return LessonPackage(
      format: format,
      packageId: r.id('packageId'),
      version: r.string('version'),
      stage: stage,
      title: r.text('title'),
      lessons: List.unmodifiable(lessons),
      todoPaths: List.unmodifiable(_todo),
    );
  }

  Lesson _lesson(_Obj r) {
    r.only(const {'lessonId', 'title', 'skills', 'steps'});
    final skills = r.skills('skills');
    if (skills.isEmpty) r.fail('skills', 'a lesson teaches at least one skill');
    final stepList = r.list('steps');
    if (stepList.isEmpty) r.fail('steps', 'must not be empty');
    final steps = <LessonStep>[];
    final ids = <String>{};
    for (final (i, s) in stepList.indexed) {
      final step = _step(_Obj.of(s, '${r.path}.steps[$i]', this));
      if (!ids.add(step.id)) {
        r.fail('steps[$i].id', 'duplicate step id "${step.id}"');
      }
      if (step is QuizStep && i != stepList.length - 1) {
        r.fail('steps[$i]', 'the quiz must be the last step');
      }
      steps.add(step);
    }
    final lesson = Lesson(
      id: r.id('lessonId'),
      title: r.text('title'),
      skills: skills,
      steps: List.unmodifiable(steps),
    );
    if (lesson.quiz case final quiz?) {
      final at = 'steps[${steps.length - 1}].stepIds';
      for (final (i, id) in quiz.stepIds.indexed) {
        final target = lesson.step(id);
        if (target == null) {
          r.fail('$at[$i]', 'no step "$id" in this lesson');
        } else if (!target.type.isQuestion) {
          r.fail(
            '$at[$i]',
            'step "$id" (${target.type.jsonName}) has no right answer',
          );
        }
      }
    }
    return lesson;
  }

  LessonStep _step(_Obj r) {
    final typeName = r.string('type');
    final type =
        StepType.values.where((t) => t.jsonName == typeName).firstOrNull;
    if (type == null) r.fail('type', 'unknown step type "$typeName"');
    const common = {'id', 'type', 'skills'};
    r.only({...common, ...?_fields[type]});
    final id = r.id('id');
    final skills = r.has('skills') ? r.skills('skills') : const <String>[];
    switch (type) {
      case StepType.explain:
        return ExplainStep(
          id: id,
          skills: skills,
          text: r.text('text'),
          image: r.has('image') ? r.media('image') : null,
          audio: r.has('audio') ? r.media('audio') : null,
        );
      case StepType.listen:
        return ListenStep(
          id: id,
          skills: skills,
          audio: r.media('audio'),
          highlight: r.string('highlight'),
        );
      case StepType.repeatAndCompare:
        return RepeatAndCompareStep(
          id: id,
          skills: skills,
          audio: r.media('audio'),
        );
      case StepType.hearAndChoose:
        final options = r.options('options');
        return HearAndChooseStep(
          id: id,
          skills: skills,
          audio: r.media('audio'),
          options: options,
          answer: r.oneOf('answer', options),
        );
      case StepType.seeAndChoose:
        final options = r.options('optionsAudio', media: true);
        return SeeAndChooseStep(
          id: id,
          skills: skills,
          prompt: r.string('prompt'),
          optionsAudio: options,
          answer: r.oneOf('answer', options),
        );
      case StepType.pairDiscriminate:
        final pair = r.options('pair');
        if (pair.length != 2) r.fail('pair', 'must have exactly 2 letters');
        return PairDiscriminateStep(
          id: id,
          skills: skills,
          audio: r.media('audio'),
          pair: (pair[0], pair[1]),
          answer: r.oneOf('answer', pair),
        );
      case StepType.findForm:
        final options = r.options('options');
        final positionName = r.string('position');
        final position = LetterPosition.values
            .where((p) => p.jsonName == positionName)
            .firstOrNull;
        if (position == null) {
          r.fail(
            'position',
            'must be one of '
                '${LetterPosition.values.map((p) => p.jsonName).join(', ')}',
          );
        }
        return FindFormStep(
          id: id,
          skills: skills,
          letter: r.string('letter'),
          position: position,
          options: options,
          answer: r.oneOf('answer', options),
        );
      case StepType.buildSyllable:
        final target = r.string('target');
        final pieces = r.strings('pieces');
        if (pieces.isEmpty) r.fail('pieces', 'must not be empty');
        if (!canBuild(target, pieces)) {
          r.fail('pieces', 'the target cannot be built from these pieces');
        }
        return BuildSyllableStep(
          id: id,
          skills: skills,
          target: target,
          pieces: pieces,
        );
      case StepType.readSupported:
        final (from, to) = r.range();
        return ReadSupportedStep(
          id: id,
          skills: skills,
          from: from,
          to: to,
          offerMemorize: r.has('offerMemorize') && r.boolean('offerMemorize'),
        );
      case StepType.findRule:
        final (from, to) = r.range();
        final words = r.list('answerWords');
        if (words.isEmpty) r.fail('answerWords', 'must not be empty');
        final answer = <WordKey>[];
        for (final (i, w) in words.indexed) {
          final key = r.wordKeyValue(w, 'answerWords[$i]');
          if (key.compareTo(from) < 0 || key.compareTo(to) > 0) {
            r.fail('answerWords[$i]', 'word $key is outside $from–$to');
          }
          if (answer.contains(key)) {
            r.fail('answerWords[$i]', 'duplicate word $key');
          }
          answer.add(key);
        }
        answer.sort();
        return FindRuleStep(
          id: id,
          skills: skills,
          from: from,
          to: to,
          rule: r.skill('rule'),
          answerWords: List.unmodifiable(answer),
        );
      case StepType.quiz:
        final ids = r.strings('stepIds');
        if (ids.isEmpty) r.fail('stepIds', 'a quiz asks at least one step');
        if (ids.toSet().length != ids.length) {
          r.fail('stepIds', 'a step is listed twice');
        }
        return QuizStep(
          id: id,
          skills: skills,
          stepIds: ids,
          passPercent: r.has('passPercent') ? r.percent('passPercent') : null,
        );
      case StepType.speakAndCheck:
        return SpeakAndCheckStep(
          id: id,
          skills: skills,
          audio: r.media('audio'),
          target: r.string('target'),
        );
    }
  }

  static const Map<StepType, Set<String>> _fields = {
    StepType.explain: {'text', 'image', 'audio'},
    StepType.listen: {'audio', 'highlight'},
    StepType.repeatAndCompare: {'audio'},
    StepType.hearAndChoose: {'audio', 'options', 'answer'},
    StepType.seeAndChoose: {'prompt', 'optionsAudio', 'answer'},
    StepType.pairDiscriminate: {'audio', 'pair', 'answer'},
    StepType.findForm: {'letter', 'position', 'options', 'answer'},
    StepType.buildSyllable: {'target', 'pieces'},
    StepType.readSupported: {'from', 'to', 'offerMemorize'},
    StepType.findRule: {'from', 'to', 'rule', 'answerWords'},
    StepType.quiz: {'stepIds', 'passPercent'},
    StepType.speakAndCheck: {'audio', 'target'},
  };
}

/// Whether [target] is a concatenation of distinct [pieces] in some order.
bool canBuild(String target, List<String> pieces) {
  final used = List.filled(pieces.length, false);
  bool from(int at) {
    if (at == target.length) return true;
    for (var i = 0; i < pieces.length; i++) {
      if (used[i] || !target.startsWith(pieces[i], at)) continue;
      used[i] = true;
      if (from(at + pieces[i].length)) return true;
      used[i] = false;
    }
    return false;
  }

  return target.isNotEmpty && from(0);
}

/// Surahs in the Quran; a word key outside is malformed.
const int _surahCount = 114;

final RegExp _idPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final RegExp _skillPattern = RegExp(r'^[a-z]+:[a-z0-9][a-z0-9_-]*$');

/// A JSON object being read, with its path for error messages.
final class _Obj {
  _Obj(this._map, this.path, this._parser);

  factory _Obj.of(Object? json, String path, _PackageParser parser) {
    if (json is! Map<String, Object?>) {
      throw LessonFormatException(path, 'must be an object');
    }
    return _Obj(json, path, parser);
  }

  final Map<String, Object?> _map;
  final String path;
  final _PackageParser _parser;

  Never fail(String key, String message) =>
      throw LessonFormatException('$path.$key', message);

  void only(Set<String> allowed) {
    for (final key in _map.keys) {
      if (!allowed.contains(key)) fail(key, 'unknown field');
    }
  }

  bool has(String key) => _map.containsKey(key);

  Object _value(String key) => switch (_map[key]) {
        null => fail(key, 'missing'),
        final Object v => v,
      };

  String string(String key) => _stringValue(_value(key), key);

  String _stringValue(Object v, String at) {
    if (v is! String || v.trim().isEmpty) {
      fail(at, 'must be a non-empty string');
    }
    if (v.contains(todoContent)) _parser._todo.add('$path.$at');
    return v;
  }

  int integer(String key) => switch (_value(key)) {
        final int v => v,
        _ => fail(key, 'must be an integer'),
      };

  bool boolean(String key) => switch (_value(key)) {
        final bool v => v,
        _ => fail(key, 'must be true or false'),
      };

  double percent(String key) => switch (_value(key)) {
        final num v when v >= 0 && v <= 100 => v.toDouble(),
        _ => fail(key, 'must be a number in 0..100'),
      };

  List<Object?> list(String key) => switch (_value(key)) {
        final List<Object?> v => v,
        _ => fail(key, 'must be a list'),
      };

  List<String> strings(String key) => List.unmodifiable([
        for (final (i, v) in list(key).indexed)
          _stringValue(v ?? fail('$key[$i]', 'missing'), '$key[$i]'),
      ]);

  /// Choices: at least two, all different.
  List<String> options(String key, {bool media = false}) {
    final values = media
        ? [
            for (final (i, v) in list(key).indexed)
              _mediaValue(v ?? fail('$key[$i]', 'missing'), '$key[$i]'),
          ]
        : strings(key);
    if (values.length < 2) fail(key, 'needs at least 2 choices');
    if (values.toSet().length != values.length) {
      fail(key, 'choices must be different');
    }
    return List.unmodifiable(values);
  }

  String oneOf(String key, List<String> options) {
    final v = string(key);
    if (!options.contains(v)) fail(key, '"$v" is not one of the choices');
    return v;
  }

  String id(String key) {
    final v = string(key);
    if (!_idPattern.hasMatch(v)) {
      fail(key, '"$v" must be letters, digits, ".", "_" or "-"');
    }
    return v;
  }

  String skill(String key) => _skillValue(_value(key), key);

  String _skillValue(Object v, String at) {
    if (v is! String || !_skillPattern.hasMatch(v)) {
      fail(at, 'a skill id is "kind:name" in lower case, like letter:ba');
    }
    return v;
  }

  List<String> skills(String key) {
    final values = [
      for (final (i, v) in list(key).indexed)
        _skillValue(v ?? fail('$key[$i]', 'missing'), '$key[$i]'),
    ];
    if (values.toSet().length != values.length) {
      fail(key, 'a skill is listed twice');
    }
    return List.unmodifiable(values);
  }

  String media(String key) => _mediaValue(_value(key), key);

  /// A relative path that stays inside the package.
  String _mediaValue(Object v, String at) {
    final p = _stringValue(v, at);
    final segments = p.split('/');
    final bad = p.startsWith('/') ||
        p.contains(r'\') ||
        p.contains(':') ||
        segments.any((s) => s.isEmpty || s == '.' || s == '..');
    if (bad) fail(at, '"$p" must be a relative path inside the package');
    return p;
  }

  LocalizedText text(String key) {
    final r = _Obj.of(_value(key), '$path.$key', _parser)
      ..only({for (final l in LessonLanguage.values) l.name});
    return LocalizedText(
      ru: r.string(LessonLanguage.ru.name),
      kk: r.string(LessonLanguage.kk.name),
      uz: r.string(LessonLanguage.uz.name),
      en: r.string(LessonLanguage.en.name),
    );
  }

  WordKey wordKeyValue(Object? v, String at) {
    if (v is! String) fail(at, 'a word is "surah:ayah:word"');
    final parts = v.split(':').map(int.tryParse).toList();
    if (parts case [final int s, final int a, final int w]) {
      if (s < 1 || s > _surahCount || a < 1 || w < 1) {
        fail(at, '"$v" is out of range');
      }
      return WordKey(s, a, w);
    }
    fail(at, '"$v" is not "surah:ayah:word"');
  }

  (WordKey, WordKey) range() {
    final from = wordKeyValue(_value('from'), 'from');
    final to = wordKeyValue(_value('to'), 'to');
    if (to.compareTo(from) < 0) fail('to', '$to is before $from');
    return (from, to);
  }
}
