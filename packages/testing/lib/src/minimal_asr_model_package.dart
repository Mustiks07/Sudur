import 'dart:convert';
import 'dart:io';

/// Creates the smallest package accepted by `AsrModelPackage.load`.
///
/// The three ONNX bytes are deliberately not a working model. This fixture is
/// only for package-installation and manifest-validation tests, and keeps real
/// model artifacts out of git.
Future<Directory> createMinimalAsrModelPackage({Directory? directory}) async {
  final root = directory ??
      await Directory.systemTemp.createTemp('minimal-asr-model-package-');
  await root.create(recursive: true);
  await File(_join(root, 'model.int8.onnx')).writeAsBytes(<int>[1, 2, 3]);
  await File(_join(root, 'tokens.txt')).writeAsString('test');
  await _writeJson(root, 'model.json', <String, Object?>{
    'modelId': 'test/minimal',
    'version': '1',
    'output': 'uthmaniLettersNoDiacritics',
    'isStreaming': false,
    'hasTokenTimes': true,
    'sampleRate': 16000,
    'minRamMb': 1,
    'license': 'MIT',
    'normalizerId': 'test-minimal',
    'modelSizeBytes': 3,
    'tokensSizeBytes': 4,
    'modelSha256':
        '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
    'tokensSha256':
        '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
  });
  await _writeJson(root, 'normalizer.json', <String, Object?>{
    'id': 'test-minimal',
    'removeRanges': <Object?>[],
    'replace': <Object?>[],
    'wordSeparator': ' ',
  });
  await _writeJson(root, 'thresholds.json', <String, Object?>{
    'beamSize': 5,
    'maxSkip': 4,
    'maxBack': 8,
    'costSkip': 1,
    'costBack': 0.3,
    'costInsert': 1,
    'simFloor': 0.4,
    'openThreshold': 0.7,
    'lostCostThreshold': 0.6,
    'ambiguityMargin': 0.15,
    'ngramSize': 3,
    'stableConfirmations': 2,
    'openDelayWords': 2,
    'lostWindowWords': 4,
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
  });
  await _writeJson(root, 'eval.json', <String, Object?>{
    'dataset': 'synthetic-test-fixture',
  });
  return root;
}

Future<void> _writeJson(
  Directory directory,
  String name,
  Map<String, Object?> value,
) =>
    File(_join(directory, name)).writeAsString(jsonEncode(value));

String _join(Directory directory, String name) =>
    '${directory.path}${Platform.pathSeparator}$name';
