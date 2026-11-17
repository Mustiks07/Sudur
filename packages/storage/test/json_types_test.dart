import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

import 'helpers.dart';

void main() {
  test('typed JSON values are immutable and compare by value', () {
    final source = <String, Object?>{
      'nested': <Object?>[1, true],
    };
    final first = JsonObjectData.fromJson(source);
    final second = JsonObjectData.decode(jsonEncode(source));

    expect(first, second);
    expect(
      () => first.value['new'] = 'value',
      throwsUnsupportedError,
    );
    final nested = first.value['nested'];
    if (nested is! List<Object?>) {
      fail('nested must be a list.');
    }
    expect(
      () => nested.add(2),
      throwsUnsupportedError,
    );
  });

  test('typed fields reject malformed JSON', () {
    expect(
      () => HintCounts.fromJson(
        const <String, Object?>{'firstWord': 'one'},
      ),
      throwsFormatException,
    );
    expect(
      () => ErrorEventIds.fromJson(const <Object?>[1]),
      throwsFormatException,
    );
    expect(
      () => WordIndexes.fromJson(const <Object?>['one']),
      throwsFormatException,
    );
    expect(
      () => SessionSummary.fromJson(const <Object?>[]),
      throwsFormatException,
    );
  });

  test('upload metadata validates the complete 12.5 structure', () {
    expect(uploadMetadata().data.value['schema'], 1);
    final invalid = Map<String, Object?>.from(uploadMetadata().toJson())
      ..['recordedAt'] = 'not-a-time';

    expect(
      () => UploadMetadata.fromJson(invalid),
      throwsFormatException,
    );
  });
}
