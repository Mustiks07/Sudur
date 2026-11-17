import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('sudur_annotate_cli_');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  test('validate command accepts a valid directory', () async {
    File('${directory.path}/sample.ann.json').writeAsStringSync(
      jsonEncode(_validAnnotation),
    );

    final result = await _runValidator(directory.path);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Разметка верна'));
    expect(result.stderr, isEmpty);
  });

  test('validate command rejects a damaged file', () async {
    File('${directory.path}/broken.ann.json').writeAsStringSync('{broken');

    final result = await _runValidator(directory.path);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('broken.ann.json'));
    expect(result.stderr, contains('Найдены ошибки'));
  });
}

Future<ProcessResult> _runValidator(String path) => Process.run(
      Platform.resolvedExecutable,
      ['run', 'bin/validate.dart', path],
      workingDirectory: Directory.current.path,
    );

const Map<String, Object?> _validAnnotation = {
  'recordingId': 'sample',
  'speaker': {
    'id': 'p001',
    'nativeLanguage': 'kk',
    'gender': 'f',
  },
  'conditions': {'device': 'budget-android', 'noise': 'quiet'},
  'expected': {'from': '78:1:1', 'to': '78:1:1'},
  'words': [
    {
      'wordKey': '78:1:1',
      'status': 'correct',
      'startMs': 100,
      'endMs': 500,
    },
  ],
  'insertions': <Object?>[],
  'jumps': <Object?>[],
  'annotators': ['a1'],
};
