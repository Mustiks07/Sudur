import 'dart:convert';
import 'dart:io';

import 'package:asr_sherpa/src/recognizer_exception.dart';
import 'package:contracts/contracts.dart';
import 'package:crypto/crypto.dart';

/// Validated description and paths of an installed ASR model package.
final class AsrModelPackage {
  AsrModelPackage._({
    required this.directory,
    required this.info,
    required this.sampleRate,
    required this.modelPath,
    required this.tokensPath,
  });

  /// Installed package directory.
  final String directory;

  /// Public model metadata.
  final RecognizerInfo info;

  /// Expected input sample rate.
  final int sampleRate;

  /// Absolute ONNX model path.
  final String modelPath;

  /// Absolute tokens path.
  final String tokensPath;

  /// Loads and validates the complete package and its recorded checksums.
  static Future<Result<AsrModelPackage>> load(String directory) async {
    try {
      final root = Directory(directory);
      if (!root.existsSync()) {
        return const Result.error(
          SherpaRecognizerException(
            'modelDirectoryMissing',
            'Model directory does not exist.',
          ),
        );
      }

      final modelJson = File(_join(directory, 'model.json'));
      final normalizerJson = File(_join(directory, 'normalizer.json'));
      final thresholdsJson = File(_join(directory, 'thresholds.json'));
      final model = File(_join(directory, 'model.int8.onnx'));
      final tokens = File(_join(directory, 'tokens.txt'));
      final requiredFiles = <File>[
        modelJson,
        normalizerJson,
        thresholdsJson,
        model,
        tokens,
      ];
      for (final file in requiredFiles) {
        if (!file.existsSync()) {
          return Result.error(
            SherpaRecognizerException(
              'modelPackageIncomplete',
              'Required model package file is missing: '
                  '${_basename(file.path)}.',
            ),
          );
        }
      }

      final metadata = await _readJsonObject(modelJson);
      final normalizer = await _readJsonObject(normalizerJson);
      final thresholds = await _readJsonObject(thresholdsJson);
      _validateNormalizer(normalizer);
      _validateThresholds(thresholds);

      final modelId = _requiredString(metadata, 'modelId');
      final version = _requiredString(metadata, 'version');
      final outputName = _requiredString(metadata, 'output');
      final output = switch (outputName) {
        'uthmaniLettersNoDiacritics' =>
          AsrOutputKind.uthmaniLettersNoDiacritics,
        'phonemes' => AsrOutputKind.phonemes,
        _ => throw const FormatException('Unsupported model output kind.'),
      };
      final isStreaming = _requiredBool(metadata, 'isStreaming');
      if (isStreaming) {
        throw const FormatException(
          'This recognizer requires an offline CTC model.',
        );
      }
      final hasTokenTimes = _requiredBool(metadata, 'hasTokenTimes');
      final sampleRate = _requiredInt(metadata, 'sampleRate');
      if (sampleRate <= 0) {
        throw const FormatException('sampleRate must be positive.');
      }
      if (_requiredString(metadata, 'license') != 'MIT') {
        throw const FormatException('The model package license must be MIT.');
      }
      _requiredInt(metadata, 'minRamMb');
      _requiredString(metadata, 'normalizerId');
      final modelSize = _requiredInt(metadata, 'modelSizeBytes');
      final tokensSize = _requiredInt(metadata, 'tokensSizeBytes');
      if (modelSize != model.lengthSync() ||
          tokensSize != tokens.lengthSync()) {
        throw const FormatException(
          'A model package file size does not match.',
        );
      }

      await _verifyDigest(model, _requiredString(metadata, 'modelSha256'));
      await _verifyDigest(tokens, _requiredString(metadata, 'tokensSha256'));

      return Result.ok(
        AsrModelPackage._(
          directory: directory,
          info: RecognizerInfo(
            modelId: modelId,
            modelVersion: version,
            output: output,
            isStreaming: false,
            hasTokenTimes: hasTokenTimes,
          ),
          sampleRate: sampleRate,
          modelPath: model.path,
          tokensPath: tokens.path,
        ),
      );
    } on FormatException catch (error) {
      return Result.error(
        SherpaRecognizerException('invalidModelPackage', error.message),
      );
    } on FileSystemException {
      return const Result.error(
        SherpaRecognizerException(
          'modelPackageIo',
          'Could not read the model package.',
        ),
      );
    }
  }
}

Future<Map<String, Object?>> _readJsonObject(File file) async {
  final Object? decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<String, Object?>) {
    throw FormatException(
      '${_basename(file.path)} must contain a JSON object.',
    );
  }
  return decoded;
}

void _validateNormalizer(Map<String, Object?> value) {
  _requiredString(value, 'id');
  _requiredString(value, 'wordSeparator');
  if (value['removeRanges'] is! List<Object?>) {
    throw const FormatException('normalizer.json has an invalid schema.');
  }
  final replacements = value['replace'];
  if (replacements is! List<Object?>) {
    throw const FormatException(
      'normalizer.json replace must be an ordered list.',
    );
  }
  for (final replacement in replacements) {
    if (replacement is! Map<String, Object?>) {
      throw const FormatException(
        'Every normalizer replacement must be an object.',
      );
    }
    final from = replacement['from'];
    final to = replacement['to'];
    if (from is! String || from.isEmpty || to is! String) {
      throw const FormatException(
        'Every normalizer replacement needs non-empty from and string to.',
      );
    }
  }
}

const _thresholdKeys = <String>{
  'beamSize',
  'maxSkip',
  'maxBack',
  'costSkip',
  'costBack',
  'costInsert',
  'simFloor',
  'openThreshold',
  'lostCostThreshold',
  'ambiguityMargin',
  'ngramSize',
  'stableConfirmations',
  'strongMatch',
  'substitutionMax',
  'confirmContextWords',
  'jumpMinWords',
  'selfCorrectionMs',
  'selfCorrectionWords',
  'hesitationPauseMs',
  'hesitationTempoFactor',
  'strictMaxFails',
  'strictMaxWaitMs',
  'stuckWordTries',
};

void _validateThresholds(Map<String, Object?> value) {
  for (final key in _thresholdKeys) {
    if (value[key] is! num) {
      throw FormatException('thresholds.json is missing numeric $key.');
    }
  }
}

String _requiredString(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! String || field.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return field;
}

bool _requiredBool(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! bool) {
    throw FormatException('$key must be a boolean.');
  }
  return field;
}

int _requiredInt(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! int) {
    throw FormatException('$key must be an integer.');
  }
  return field;
}

Future<void> _verifyDigest(File file, String expected) async {
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(expected)) {
    throw const FormatException('A SHA-256 value is malformed.');
  }
  final actual = (await sha256.bind(file.openRead()).first).toString();
  if (actual != expected) {
    throw FormatException(
      '${_basename(file.path)} failed SHA-256 verification.',
    );
  }
}

String _join(String directory, String name) =>
    '$directory${Platform.pathSeparator}$name';

String _basename(String path) => path.split(Platform.pathSeparator).last;
