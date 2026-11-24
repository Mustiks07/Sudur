import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:follow/follow.dart';
import 'package:quran_text/quran_text.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_platform_service.dart';
import 'package:testing/testing.dart';

void main() {
  late Directory root;
  late Normalizer normalizer;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('sudur-normalizer-test-');
    final modelDirectory = Directory('${root.path}/models/quran-asr-small');
    await modelDirectory.create(recursive: true);
    await File('${modelDirectory.path}/model.int8.onnx')
        .writeAsBytes(<int>[1, 2, 3]);
    await File('${modelDirectory.path}/tokens.txt').writeAsString('tokens');
    await File('${modelDirectory.path}/LICENSE').writeAsString('MIT');
    await File(
      '${modelDirectory.path}/spelling.json',
    ).writeAsString(jsonEncode(<String, String>{'\u0627': 'must-not-be-used'}));
    await File('${modelDirectory.path}/normalizer.json').writeAsString(
      '{"id":"obsolete","removeRanges":[],"replace":[],'
      '"wordSeparator":" "}',
    );
    await PrototypeAssetInstaller(_FakePlatform(root.path))
        .refreshInstalledModelMetadata();
    final source = await File('${modelDirectory.path}/normalizer.json')
        .readAsString();
    normalizer = switch (Normalizer.fromJson(source)) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
  });

  tearDown(() => root.delete(recursive: true));

  test('cached model gets exact v2 normalizer without model download', () {
    expect(normalizer.id.value, contains('letters-v2'));
    expect(normalizer.removeRanges, hasLength(9));
    expect(normalizer.replacements, hasLength(13));
    expect(normalizer.keyOf('\u0627').value, '\u0627');
    expect(
      File('${root.path}/models/quran-asr-small/model.int8.onnx')
          .readAsBytesSync(),
      <int>[1, 2, 3],
    );
  });

  test('every canonical word matches the Abdou letters reference', () {
    final words = _fixtureWords();

    for (final word in words) {
      expect(
        normalizer.keyOf(word.text).value,
        _letters(word.text),
        reason: word.key.toString(),
      );
    }
  });

  test('model-style bare letters reveal every word of surah 78', () async {
    final words = _fixtureWords();
    final text = InMemoryQuranText(
      words: words,
      normalizers: <Normalizer>[normalizer],
      params: SearchParams.defaults,
    );
    final surah = words.where((word) => word.key.surah == 78).toList();
    final follower = Follower(
      text: text,
      normalizer: normalizer,
      from: surah.first.key,
      to: surah.last.key,
      params: FollowParams.defaults,
    );
    final script = RecognitionScript();
    for (var ayah = 1; ayah <= 40; ayah++) {
      script.segment(<String>[
        for (final word in surah.where((word) => word.key.ayah == ayah))
          _letters(word.text),
      ]);
    }
    final recognizer = FakeSpeechRecognizer(
      script.results,
      info: scriptedRecognizerInfo,
    );
    addTearDown(recognizer.dispose);
    final updates = follower.bind(recognizer.results).toList();

    await recognizer.play();
    final events = <SessionEvent>[
      for (final update in await updates) ...update.events,
      ...follower
          .finish(
            sessionId: 'test-session',
            atMs: 40 * Duration.millisecondsPerSecond,
          )
          .events,
    ];

    expect(
      events.whereType<WordRevealed>().map((event) => event.word),
      <WordKey>[for (final word in surah) word.key],
    );
  });
}

List<Word> _fixtureWords() => switch (QuranTextJsonSource(
  File('../packages/testing/fixtures/quran_text.json').readAsStringSync(),
).loadWords()) {
  Ok(:final value) => value,
  Error(:final error) => throw error,
};

String _letters(String text) => String.fromCharCodes(<int>[
  for (final rune in text.runes)
    if (_replacement[rune] case final replacement?)
      replacement
    else if (_modelLetters.contains(rune))
      rune,
]);

const _modelLetters = <int>{
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

const _replacement = <int, int>{
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

final class _FakePlatform implements PrototypePlatformService {
  const new(this.root);

  final String root;

  @override
  Future<String> applicationDirectory() async => root;

  @override
  Future<String?> pickWavFile() async => null;

  @override
  Future<void> shareFile(String path) async {}
}
