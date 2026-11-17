import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/services/prototype_content.dart';
import 'package:sudur/data/services/prototype_trace.dart';

void main() {
  test(
    'P03 layout keeps glyph order and every canonical word exactly once',
    () {
      final raw = File('../packages/testing/fixtures/content_p582_583.json')
          .readAsStringSync();
      final content = PrototypeContent(raw);
      final source = jsonDecode(raw) as Map<String, Object?>;
      final rows = (source['words']! as List<Object?>)
          .cast<Map<String, Object?>>(); // Fixture schema.
      final fragments = content.pages
          .expand((p) => p.lines)
          .expand((l) => l.fragments)
          .where((f) => f.kind == MushafFragmentKind.word)
          .toList();
      expect(content.pages.map((p) => p.pageNumber), [582, 583]);
      expect(content.pages.every((p) => p.lines.length == 15), isTrue);
      expect(fragments.map((f) => f.wordKey).toSet().length, rows.length);
      expect(fragments.map((f) => f.glyph), rows.map((r) => r['glyphCode']));
      expect(content.words.where((w) => w.key.surah == 78).last.key.ayah, 40);
    },
  );

  test('trace bounds memory and explicitly marks lost measurement events', () {
    final trace = PrototypeTrace(capacity: 2)
      ..start()
      ..add('audio', audioMs: 0, samples: 640)
      ..add('WordRevealed', wordIndex: 78001001)
      ..add('frame');
    final output = jsonDecode(trace.encode('tiny')) as Map<String, Object?>;
    expect(output['droppedEvents'], 1);
    expect(output['events'], hasLength(2));
    expect(trace.encode('tiny'), isNot(contains('heardText')));
    trace.start();
    expect(
      (jsonDecode(trace.encode('small')) as Map<String, Object?>)['events'],
      isEmpty,
    );
  });
}
