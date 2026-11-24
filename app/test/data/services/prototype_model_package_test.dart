import 'dart:convert';
import 'dart:io';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_platform_service.dart';

// The package the app assembles next to downloaded model files must be one
// that `AsrModelPackage.load` accepts as it is (review of #27): the check of
// the package is not relaxed for the app.
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('sudur-model-package-test-');
  });

  tearDown(() => root.delete(recursive: true));

  test(
    'the package written by the app is accepted by AsrModelPackage.load',
    () async {
      final directory = Directory('${root.path}/model');
      await directory.create();
      final model = File('${directory.path}/model.int8.onnx');
      final tokens = File('${directory.path}/tokens.txt');
      await model.writeAsBytes(<int>[1, 2, 3]);
      await tokens.writeAsString('test');

      await writePrototypeModelMetadata(
        directory,
        PrototypeModelMetadata(
          modelId: 'test/model',
          version: 'test-revision',
          normalizerId: 'test-normalizer',
          minRamMb: 1,
          modelSize: model.lengthSync(),
          tokensSize: tokens.lengthSync(),
          modelSha256: '${sha256.convert(model.readAsBytesSync())}',
          tokensSha256: '${sha256.convert(tokens.readAsBytesSync())}',
        ),
      );

      final loaded = await AsrModelPackage.load(directory.path);
      expect(loaded, isA<Ok<AsrModelPackage>>(), reason: '$loaded');
    },
  );

  test('eval.json says honestly that the model is not evaluated', () async {
    final directory = Directory('${root.path}/model');
    await directory.create();
    await writePrototypeModelMetadata(directory, _anyModel);

    final evaluation = _json(File('${directory.path}/eval.json'));
    expect(evaluation['status'], 'notEvaluated');
    expect(evaluation['stage'], 'prototype');
    expect(evaluation['groups'], isEmpty);
  });

  test(
    'thresholds include the follow window parameters of spec 12.4',
    () async {
      final directory = Directory('${root.path}/model');
      await directory.create();
      await writePrototypeModelMetadata(directory, _anyModel);

      final thresholds = _json(File('${directory.path}/thresholds.json'));
      expect(thresholds['openDelayWords'], 2);
      expect(thresholds['lostWindowWords'], 4);
    },
  );

  test(
    'an already downloaded model gets eval.json and new thresholds',
    () async {
      // A package written by an earlier app version: no eval.json, thresholds
      // without openDelayWords and lostWindowWords.
      final directory = Directory('${root.path}/models/quran-asr-small');
      await directory.create(recursive: true);
      await File('${directory.path}/model.int8.onnx').writeAsBytes(<int>[1]);
      await File('${directory.path}/tokens.txt').writeAsString('tokens');
      await File('${directory.path}/LICENSE').writeAsString('MIT');
      await File('${directory.path}/spelling.json').writeAsString('{}');
      await File('${directory.path}/thresholds.json')
          .writeAsString(jsonEncode(<String, Object?>{'beamSize': 5}));

      await PrototypeAssetInstaller(_FakePlatform(root.path))
          .refreshInstalledModelMetadata();

      expect(File('${directory.path}/eval.json').existsSync(), isTrue);
      final thresholds = _json(File('${directory.path}/thresholds.json'));
      expect(thresholds, containsPair('openDelayWords', 2));
      expect(thresholds, containsPair('lostWindowWords', 4));
      expect(File('${directory.path}/model.int8.onnx').readAsBytesSync(), <int>[
        1,
      ], reason: 'the model itself is not downloaded or changed again');
    },
  );
}

const _anyModel = PrototypeModelMetadata(
  modelId: 'test/model',
  version: 'test-revision',
  normalizerId: 'test-normalizer',
  minRamMb: 1,
  modelSize: 1,
  tokensSize: 1,
  modelSha256:
      '0000000000000000000000000000000000000000000000000000000000000000',
  tokensSha256:
      '0000000000000000000000000000000000000000000000000000000000000000',
);

Map<String, Object?> _json(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

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
