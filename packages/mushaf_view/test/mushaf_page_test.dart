import 'dart:typed_data';

import 'package:contracts/contracts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_view/mushaf_view.dart';

void main() {
  group('MushafPage', () {
    testWidgets('returns the WordKey for a tapped glyph', (tester) async {
      final controller = MushafPageController();
      WordKey? tappedWord;
      final data = _fakePage();
      const target = WordKey(2, 3, 2);

      await tester.pumpWidget(
        _testHost(
          MushafPage(
            data: data,
            fontFamily: 'sans-serif',
            semanticsLabelBuilder: _testSemanticsLabel,
            controller: controller,
            onWordTap: (wordKey) => tappedWord = wordKey,
          ),
        ),
      );

      final rect = controller.wordRect(target);
      expect(rect, isNotNull);
      final pageOrigin = tester.getTopLeft(find.byType(MushafPage));
      await tester.tapAt(pageOrigin + rect!.center);

      expect(tappedWord, target);
    });

    testWidgets('hiding half of the words preserves every rectangle', (
      tester,
    ) async {
      final controller = MushafPageController();
      final data = _fakePage();
      final words = _wordsIn(data);

      await tester.pumpWidget(
        _testHost(
          MushafPage(
            data: data,
            fontFamily: 'sans-serif',
            semanticsLabelBuilder: _testSemanticsLabel,
            controller: controller,
          ),
        ),
      );
      final visibleRects = <WordKey, Rect>{
        for (final word in words) word: controller.wordRect(word)!,
      };

      await tester.pumpWidget(
        _testHost(
          MushafPage(
            data: data,
            fontFamily: 'sans-serif',
            semanticsLabelBuilder: _testSemanticsLabel,
            controller: controller,
            wordStates: <WordKey, MushafWordState>{
              for (var index = 0; index < words.length; index += 2)
                words[index]: MushafWordState.hidden,
            },
          ),
        ),
      );

      for (final word in words) {
        expect(controller.wordRect(word), visibleRects[word]);
      }
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('uses the supplied builder for the semantics label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final data = _fakePage();
      MushafAyahSemantics? builderInput;

      await tester.pumpWidget(
        _testHost(
          MushafPage(
            data: data,
            fontFamily: 'sans-serif',
            semanticsLabelBuilder: (ayah) {
              builderInput = ayah;
              return 'TEST_LOCALIZED_LABEL';
            },
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          'TEST_LOCALIZED_LABEL',
        ),
        findsOneWidget,
      );
      expect(builderInput, same(data.ayahSemantics.single));
      semantics.dispose();
    });

    testWidgets('puts the page and each line in repaint boundaries', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testHost(
          MushafPage(
            data: _fakePage(),
            fontFamily: 'sans-serif',
            semanticsLabelBuilder: _testSemanticsLabel,
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsNWidgets(16));
    });
  });

  test('PageFontLoader loads the current page and a ±3 window', () async {
    final loaded = <int>[];
    final registered = <String>[];
    final loader = PageFontLoader.custom(
      bytesLoader: (pageNumber) async {
        loaded.add(pageNumber);
        return ByteData(1);
      },
      registrar: (family, bytes) async => registered.add(family),
      scheduler: (task) => task(),
    );

    await loader.ensureWindow(10);

    expect(loaded, <int>[10, 9, 11, 8, 12, 7, 13]);
    expect(
      registered,
      <String>[
        'MushafPage10',
        'MushafPage9',
        'MushafPage11',
        'MushafPage8',
        'MushafPage12',
        'MushafPage7',
        'MushafPage13',
      ],
    );
    expect(loader.loadedPages, <int>{7, 8, 9, 10, 11, 12, 13});
  });
}

Widget _testHost(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(width: 320, height: 600, child: child),
    ),
  );
}

MushafPageData _fakePage() {
  return MushafPageData(
    pageNumber: 582,
    lines: <MushafLineData>[
      for (var line = 1; line <= 15; line += 1)
        MushafLineData(<MushafFragment>[
          for (var word = 1; word <= 3; word += 1)
            MushafFragment(
              glyph: 'L${line}W$word',
              kind: MushafFragmentKind.word,
              wordKey: WordKey(2, line, word),
            ),
          const MushafFragment(
            glyph: 'END',
            kind: MushafFragmentKind.ayahEnd,
          ),
        ]),
    ],
    ayahSemantics: const <MushafAyahSemantics>[
      MushafAyahSemantics(
        surah: 2,
        ayah: 1,
        canonicalText: 'TODO_CONTENT canonical ayah placeholder',
      ),
    ],
  );
}

List<WordKey> _wordsIn(MushafPageData page) {
  return <WordKey>[
    for (final line in page.lines)
      for (final fragment in line.fragments)
        if (fragment.wordKey case final wordKey?) wordKey,
  ];
}

String _testSemanticsLabel(MushafAyahSemantics ayah) {
  return '${ayah.surah}:${ayah.ayah}. ${ayah.canonicalText}';
}
