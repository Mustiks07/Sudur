import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run packages/asr_sherpa/bin/asr_sherpa.dart '
      '<model-directory> <input.wav> <output.asr.jsonl>',
    );
    exitCode = 64;
    return;
  }

  final recognizer = SherpaCtcRecognizer(sessionId: 'wav-file');
  final loadResult = await recognizer.load(arguments[0]);
  if (loadResult case Error(:final error)) {
    stderr.writeln(error);
    await recognizer.dispose();
    exitCode = 1;
    return;
  }

  try {
    final audio = await readPcm16Wav(arguments[1]);
    final records = <RecognitionResult>[];
    final finalResult = Completer<void>();
    final subscription = recognizer.results.listen((result) {
      records.add(result);
      if (result.isFinal && !finalResult.isCompleted) {
        finalResult.complete();
      }
    });

    const chunkMs = 20;
    final chunkSamples = audio.sampleRate * chunkMs ~/ 1000;
    for (var offset = 0;
        offset < audio.samples.length;
        offset += chunkSamples) {
      final end = (offset + chunkSamples).clamp(0, audio.samples.length);
      recognizer.acceptAudio(
        audio.samples.sublist(offset, end),
        audio.sampleRate,
        offset * 1000 ~/ audio.sampleRate,
      );
      await Future<void>.delayed(const Duration(milliseconds: chunkMs));
    }
    recognizer.closeSegment(1);
    await finalResult.future.timeout(const Duration(minutes: 2));

    final lines = records
        .map((result) => jsonEncode(recognitionResultToJson(result)))
        .join('\n');
    await File(arguments[2]).writeAsString('$lines\n', flush: true);
    await subscription.cancel();
    stdout.writeln('Wrote ${records.length} recognition records.');
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    await recognizer.dispose();
  }
}
