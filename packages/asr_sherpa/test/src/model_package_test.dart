import 'dart:io';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

void main() {
  test('validates a complete model package and its hashes', () async {
    final directory = await createMinimalAsrModelPackage();
    addTearDown(() => directory.delete(recursive: true));

    final result = await AsrModelPackage.load(directory.path);

    expect(result, isA<Ok<AsrModelPackage>>());
    final package = (result as Ok<AsrModelPackage>).value;
    expect(package.info.modelId, 'test/minimal');
    expect(package.sampleRate, 16000);
  });

  test('rejects a package without model thresholds', () async {
    final directory = await createMinimalAsrModelPackage();
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}${Platform.pathSeparator}thresholds.json')
        .writeAsString('{}');

    final result = await AsrModelPackage.load(directory.path);

    expect(result, isA<Error<AsrModelPackage>>());
  });

  test('rejects a package without evaluation metadata', () async {
    final directory = await createMinimalAsrModelPackage();
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}${Platform.pathSeparator}eval.json').delete();

    final result = await AsrModelPackage.load(directory.path);

    expect(result, isA<Error<AsrModelPackage>>());
  });

  test('rejects an unordered normalizer replacement object', () async {
    final directory = await createMinimalAsrModelPackage();
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}${Platform.pathSeparator}normalizer.json')
        .writeAsString(
      '{"id":"test","removeRanges":[],"replace":{"a":"b"},'
      '"wordSeparator":" "}',
    );

    final result = await AsrModelPackage.load(directory.path);

    expect(result, isA<Error<AsrModelPackage>>());
  });
}
