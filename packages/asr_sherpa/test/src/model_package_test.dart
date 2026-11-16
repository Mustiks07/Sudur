import 'dart:convert';
import 'dart:io';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates a complete model package and its hashes', () async {
    final directory = await _createPackage();
    addTearDown(() => directory.delete(recursive: true));

    final result = await AsrModelPackage.load(directory.path);

    expect(result, isA<Ok<AsrModelPackage>>());
    final package = (result as Ok<AsrModelPackage>).value;
    expect(package.info.modelId, 'test/model');
    expect(package.sampleRate, 16000);
  });

  test('rejects a package without model thresholds', () async {
    final directory = await _createPackage();
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}${Platform.pathSeparator}thresholds.json')
        .writeAsString('{}');

    final result = await AsrModelPackage.load(directory.path);

    expect(result, isA<Error<AsrModelPackage>>());
  });

  test('rejects an unordered normalizer replacement object', () async {
    final directory = await _createPackage();
    addTearDown(() => directory.delete(recursive: true));
    await _writeJson(
      directory,
      'normalizer.json',
      <String, Object?>{
        'id': 'test',
        'removeRanges': <Object?>[],
        'replace': <String, Object?>{'a': 'b'},
        'wordSeparator': ' ',
      },
    );

    final result = await AsrModelPackage.load(directory.path);

    expect(result, isA<Error<AsrModelPackage>>());
  });
}

Future<Directory> _createPackage() async {
  final directory = await Directory.systemTemp.createTemp('asr-model-test-');
  final model =
      File('${directory.path}${Platform.pathSeparator}model.int8.onnx');
  final tokens = File('${directory.path}${Platform.pathSeparator}tokens.txt');
  await model.writeAsBytes(<int>[1, 2, 3]);
  await tokens.writeAsString('test');
  final modelHash = sha256.convert(await model.readAsBytes()).toString();
  final tokensHash = sha256.convert(await tokens.readAsBytes()).toString();
  await _writeJson(
    directory,
    'model.json',
    <String, Object?>{
      'modelId': 'test/model',
      'version': '1',
      'output': 'uthmaniLettersNoDiacritics',
      'isStreaming': false,
      'hasTokenTimes': true,
      'sampleRate': 16000,
      'minRamMb': 1,
      'license': 'MIT',
      'normalizerId': 'test',
      'modelSizeBytes': 3,
      'tokensSizeBytes': 4,
      'modelSha256': modelHash,
      'tokensSha256': tokensHash,
    },
  );
  await _writeJson(
    directory,
    'normalizer.json',
    <String, Object?>{
      'id': 'test',
      'nfc': true,
      'removeRanges': <Object?>[],
      'replace': <Object?>[
        <String, Object?>{'from': 'a', 'to': 'b'},
        <String, Object?>{'from': 'b', 'to': 'c'},
      ],
      'wordSeparator': ' ',
    },
  );
  await _writeJson(
    directory,
    'thresholds.json',
    <String, Object?>{
      'beamSize': 5,
      'maxSkip': 4,
      'maxBack': 8,
      'costSkip': 1.0,
      'costBack': 0.3,
      'costInsert': 1.0,
      'simFloor': 0.4,
      'openThreshold': 0.7,
      'lostCostThreshold': 0.6,
      'ambiguityMargin': 0.15,
      'ngramSize': 3,
      'stableConfirmations': 2,
      'strongMatch': 0.85,
      'substitutionMax': 0.6,
      'confirmContextWords': 2,
      'jumpMinWords': 3,
      'selfCorrectionMs': 2500,
      'selfCorrectionWords': 2,
      'hesitationPauseMs': 2500,
      'hesitationTempoFactor': 3,
      'strictMaxFails': 3,
      'strictMaxWaitMs': 15000,
      'stuckWordTries': 3,
    },
  );
  return directory;
}

Future<void> _writeJson(
  Directory directory,
  String name,
  Map<String, Object?> value,
) =>
    File('${directory.path}${Platform.pathSeparator}$name')
        .writeAsString(jsonEncode(value));
