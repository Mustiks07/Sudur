import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudur/data/services/prototype_content_parser.dart';

void main() {
  test('canonical fixture becomes two complete Mushaf pages', () async {
    final source = await File(
      '../packages/testing/fixtures/content_p582_583.json',
    ).readAsString();

    final content = const PrototypeContentParser().parse(source);
    final renderedWords = content.pages
        .expand((page) => page.lines)
        .expand((line) => line.fragments)
        .map((fragment) => fragment.wordKey)
        .whereType<WordKey>()
        .toSet();

    expect(
      content.pages.map((page) => page.pageNumber),
      orderedEquals(<int>[582, 583]),
    );
    expect(content.pages.every((page) => page.lines.length == 15), isTrue);
    expect(content.sessionWords, isNotEmpty);
    expect(content.sessionWords.every((word) => word.surah == 78), isTrue);
    expect(renderedWords.containsAll(content.sessionWords), isTrue);
  });
}
