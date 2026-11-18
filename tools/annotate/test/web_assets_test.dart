import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String html;
  late String script;

  setUpAll(() {
    html = File('web/index.html').readAsStringSync();
    script = File('web/app.js').readAsStringSync();
  });

  test('page is a static offline entry point', () {
    expect(html, contains("connect-src 'none'"));
    expect(html, isNot(contains('http://')));
    expect(html, isNot(contains('https://')));
    expect(html, contains('src="app.js"'));
    expect(html, contains('src="validation.js"'));
    expect(html, contains('href="styles.css"'));
  });

  test('page offers folder fallback and download saving', () {
    expect(html, contains('webkitdirectory'));
    expect(script, contains('showDirectoryPicker'));
    expect(script, contains('createWritable'));
    expect(script, contains('link.download = name'));
  });

  test('ASR text is only rendered as a hint', () {
    expect(html, contains('НЕ РАЗМЕТКА'));
    expect(script, contains('loadAsrHint'));
    expect(script, isNot(contains('word.heard = entry.text')));
  });

  test('saved JSON does not extend the annotation schema with UI state', () {
    expect(script, isNot(contains('annotationStatus')));
    expect(script, contains('isStoredAnnotationReady'));
  });

  test('browser rejects negative timing in edits and loaded annotations',
      () async {
    final result = await Process.run(
      'node',
      <String>['test/web_validation_regression_test.js'],
    );
    final output = '${result.stdout}${result.stderr}';

    expect(result.exitCode, 0, reason: output);
  });

  test('all required keyboard actions are wired', () {
    for (final key in [
      'correct',
      'omitted',
      'substituted',
      'selfCorrected',
      'repeated',
      'unclear',
      'markWordEnd',
      'togglePlayback',
      'openInsertionDialog',
      'openJumpDialog',
    ]) {
      expect(script, contains(key), reason: 'Missing action $key');
    }
  });
}
