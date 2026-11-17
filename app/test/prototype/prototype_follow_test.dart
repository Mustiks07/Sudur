import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/data/services/prototype_content.dart';
import 'package:sudur/data/services/prototype_follow.dart';

void main() {
  test(
    'worker follows canonical fixture and flushes without raw-text export',
    () async {
      final dir = Directory.systemTemp.createTempSync('prototype-follow-');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('../packages/testing/fixtures/content_p582_583.json')
          .copySync('${dir.path}/content.json');
      Directory('${dir.path}/model').createSync();
      File('${dir.path}/model/normalizer.json').writeAsStringSync(
        jsonEncode({
          'id': 'test',
          'nfc': true,
          'removeRanges': <Object?>[],
          'replace': <Object?>[],
          'wordSeparator': ' ',
        }),
      );
      File('${dir.path}/model/thresholds.json').writeAsStringSync('{}');
      final content = await PrototypeContent.load(dir.path);
      final passage = content.words
          .where((w) => w.key.surah == 78)
          .take(25)
          .toList();
      final worker = await PrototypeFollow.start(dir.path, 'model');
      addTearDown(worker.dispose);
      final result = RecognitionResult(
        sessionId: 'test',
        segmentId: 1,
        isFinal: true,
        text: passage.map((w) => w.text).join(' '),
        tokens: [for (final w in passage) AsrToken(text: w.text)],
        audioStartMs: 0,
        audioEndMs: 10000,
        decodeMs: 10,
        info: const RecognizerInfo(
          modelId: 'test',
          modelVersion: '1',
          output: AsrOutputKind.uthmaniLettersNoDiacritics,
          isStreaming: false,
          hasTokenTimes: false,
        ),
      );
      final events = [
        ...await worker.accept(result),
        ...await worker.finish('test', 10000),
      ];
      final revealed = events
          .whereType<WordRevealed>()
          .map((e) => e.word)
          .toSet();
      expect(revealed, contains(passage.first.key));
      expect(revealed, contains(passage.last.key));
      expect(events.whereType<CheckEvent>(), isEmpty);
    },
  );

  test('altered canonical package is rejected before rendering', () async {
    final dir = Directory.systemTemp.createTempSync('prototype-invalid-');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/content.json').writeAsStringSync('{}');
    await expectLater(PrototypeContent.load(dir.path), throwsFormatException);
  });
}
