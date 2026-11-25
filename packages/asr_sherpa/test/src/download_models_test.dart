import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_text/quran_text.dart';

void main() {
  test('built Abdou package normalizes every fixture word like letters()',
      () async {
    final temporary = await Directory.systemTemp.createTemp(
      'asr-download-models-test-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final source = Directory('${temporary.path}/source/quran-asr-small');
    final evaluations = Directory('${temporary.path}/evaluations');
    final cache = Directory('${temporary.path}/cache');
    await source.create(recursive: true);
    await evaluations.create(recursive: true);
    await File('${source.path}/model.int8.onnx').writeAsBytes(<int>[1, 2, 3]);
    await File('${source.path}/tokens.txt').writeAsString('test');
    await File('${source.path}/LICENSE').writeAsString('MIT');
    await File('${evaluations.path}/small.json').writeAsString(
      '{"dataset":"synthetic-test-fixture"}',
    );

    final result = await Process.run(
      'bash',
      <String>['tool/download_models.sh', 'small'],
      workingDirectory: Directory.current.path,
      environment: <String, String>{
        'SUDUR_ASR_CACHE_ROOT': cache.path,
        'SUDUR_ASR_EVAL_DIR': evaluations.path,
        'SUDUR_ASR_MODEL_SOURCE_ROOT': '${temporary.path}/source',
      },
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());

    final package = Directory('${cache.path}/quran-asr-small');
    expect(File('${package.path}/spelling.json').existsSync(), isFalse);
    final parsed = Normalizer.fromJson(
      await File('${package.path}/normalizer.json').readAsString(),
    );
    expect(parsed, isA<Ok<Normalizer>>());
    final normalizer = (parsed as Ok<Normalizer>).value;
    final fixture = jsonDecode(
      await File('../testing/fixtures/quran_text.json').readAsString(),
    ) as Map<String, Object?>;
    final ayahs = _required<List<Object?>>(fixture['ayahs'], 'ayahs');
    final mismatches = <String>[];
    var wordCount = 0;

    for (final rawAyah in ayahs) {
      final ayah = _required<List<Object?>>(rawAyah, 'ayah');
      final words = _required<List<Object?>>(ayah[2], 'words');
      for (var wordIndex = 0; wordIndex < words.length; wordIndex++) {
        final word = _required<String>(words[wordIndex], 'word');
        wordCount++;
        final actual = normalizer.keyOf(word).value;
        final expected = _letters(word);
        if (actual != expected && mismatches.length < 10) {
          mismatches.add(
            '${ayah[0]}:${ayah[1]}:$wordIndex '
            '${_codePoints(actual)} != ${_codePoints(expected)}',
          );
        }
      }
    }

    expect(wordCount, greaterThan(70000));
    expect(mismatches, isEmpty, reason: mismatches.join('\n'));
  });
}

T _required<T>(Object? value, String field) {
  if (value is! T) {
    throw FormatException('$field has an invalid fixture value.');
  }
  return value;
}

String _letters(String word) => String.fromCharCodes(
      word.runes
          .map((codePoint) => _fold[codePoint] ?? codePoint)
          .where(_lettersCodePoints.contains),
    );

String _codePoints(String value) =>
    value.runes.map((value) => value.toRadixString(16)).join(',');

const _fold = <int, int>{
  0x0623: 0x0627,
  0x0625: 0x0627,
  0x0622: 0x0627,
  0x0671: 0x0627,
  0x0672: 0x0627,
  0x0673: 0x0627,
  0x0649: 0x064A,
  0x0626: 0x064A,
  0x06D2: 0x064A,
  0x06CC: 0x064A,
  0x0624: 0x0648,
  0x0629: 0x0647,
  0x06A9: 0x0643,
};

const _lettersCodePoints = <int>{
  0x0621,
  0x0627,
  0x0628,
  0x062A,
  0x062B,
  0x062C,
  0x062D,
  0x062E,
  0x062F,
  0x0630,
  0x0631,
  0x0632,
  0x0633,
  0x0634,
  0x0635,
  0x0636,
  0x0637,
  0x0638,
  0x0639,
  0x063A,
  0x0641,
  0x0642,
  0x0643,
  0x0644,
  0x0645,
  0x0646,
  0x0647,
  0x0648,
  0x064A,
};
