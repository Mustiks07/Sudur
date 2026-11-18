import 'dart:convert';
import 'dart:io';

import 'package:annotate/annotate.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('sudur_annotate_test_');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  test('accepts a valid annotation through the eval parser', () {
    _writeAnnotation(directory, 'sample.ann.json', _validAnnotation());

    final report = validateAnnotationDirectory(directory);

    expect(report.filesChecked, 1);
    expect(report.issues, isEmpty);
    expect(report.isValid, isTrue);
  });

  test('reports malformed JSON without stopping the directory scan', () {
    _writeAnnotation(directory, 'good.ann.json', _validAnnotation('good'));
    File('${directory.path}/broken.ann.json').writeAsStringSync('{broken');

    final report = validateAnnotationDirectory(directory);

    expect(report.filesChecked, 2);
    expect(report.isValid, isFalse);
    expect(report.issues.single.file, 'broken.ann.json');
  });

  test('reports filename, timing, heard, correction and span errors', () {
    final annotation = _validAnnotation('different')
      ..['speaker'] = {
        'id': 'p001',
        'nativeLanguage': 'kk',
        'gender': 'x',
      }
      ..['words'] = [
        {
          'wordKey': '78:1:1',
          'status': 'substituted',
          'startMs': 900,
          'endMs': 800,
        },
        {
          'wordKey': '78:1:2',
          'status': 'selfCorrected',
          'startMs': 1000,
          'endMs': 1400,
        },
      ]
      ..['insertions'] = [
        {'startMs': -1, 'endMs': 10},
      ]
      ..['jumps'] = [
        {'startMs': 20, 'endMs': 10},
      ];
    _writeAnnotation(directory, 'sample.ann.json', annotation);

    final messages = validateAnnotationDirectory(directory)
        .issues
        .map((issue) => issue.message)
        .join('\n');

    expect(messages, contains('recordingId'));
    expect(messages, contains('speaker.gender'));
    expect(messages, contains('поле heard'));
    expect(messages, contains('correction.afterMs'));
    expect(messages, contains('afterWordKey'));
    expect(messages, contains('поле to'));
    expect(messages, contains('endMs должен быть не раньше'));
  });

  test('reports a missing directory clearly', () {
    final missing = Directory('${directory.path}/missing');

    final report = validateAnnotationDirectory(missing);

    expect(report.filesChecked, 0);
    expect(report.issues.single.message, contains('не существует'));
  });
}

Map<String, Object?> _validAnnotation([String id = 'sample']) => {
      'recordingId': id,
      'speaker': {
        'id': 'p001',
        'nativeLanguage': 'kk',
        'gender': 'f',
        'ageGroup': '25-34',
      },
      'conditions': {'device': 'budget-android', 'noise': 'quiet'},
      'expected': {'from': '78:1:1', 'to': '78:1:2'},
      'words': [
        {
          'wordKey': '78:1:1',
          'status': 'correct',
          'startMs': 100,
          'endMs': 500,
        },
        {
          'wordKey': '78:1:2',
          'status': 'selfCorrected',
          'startMs': 550,
          'endMs': 1200,
          'correction': {'afterWords': 1, 'afterMs': 300},
        },
      ],
      'insertions': [
        {
          'afterWordKey': '78:1:1',
          'heard': 'heard token',
          'startMs': 510,
          'endMs': 540,
        },
      ],
      'jumps': [
        {
          'afterWordKey': '78:1:2',
          'to': '78:2:1',
          'startMs': 1250,
          'endMs': 1500,
        },
      ],
      'annotators': ['a1'],
    };

void _writeAnnotation(
  Directory directory,
  String name,
  Map<String, Object?> annotation,
) {
  File('${directory.path}/$name').writeAsStringSync(jsonEncode(annotation));
}
