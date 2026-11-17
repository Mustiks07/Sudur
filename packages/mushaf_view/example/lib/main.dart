import 'package:contracts/contracts.dart';
import 'package:flutter/widgets.dart';
import 'package:mushaf_view/mushaf_view.dart';

void main() => runApp(const MushafViewExample());

/// Demonstrates pages 582–583 with deliberately fake, non-Quran content.
class MushafViewExample extends StatelessWidget {
  /// Creates the example app.
  const MushafViewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFF7F2E8),
      home: const _ExamplePages(),
    );
  }
}

final class _ExamplePages extends StatefulWidget {
  const _ExamplePages();

  @override
  State<_ExamplePages> createState() => _ExamplePagesState();
}

final class _ExamplePagesState extends State<_ExamplePages> {
  final MushafLayoutSource _source = _FakeLayoutSource();
  late final Future<List<MushafPageData>> _pages = Future.wait(
    <Future<MushafPageData>>[_source.loadPage(582), _source.loadPage(583)],
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F2E8),
      child: FutureBuilder<List<MushafPageData>>(
        future: _pages,
        builder: (context, snapshot) {
          final pages = snapshot.data;
          if (pages == null) {
            return const SizedBox.shrink();
          }
          return PageView.builder(
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              final words = <WordKey>[
                for (final line in page.lines)
                  for (final fragment in line.fragments)
                    if (fragment.wordKey case final wordKey?) wordKey,
              ];
              return Padding(
                padding: const EdgeInsets.all(24),
                child: MushafPage(
                  data: page,
                  // The real app registers and passes the downloaded page
                  // font family. This fake example intentionally has no font.
                  fontFamily: 'sans-serif',
                  semanticsLabelBuilder: (ayah) =>
                      '${ayah.surah}:${ayah.ayah}. ${ayah.canonicalText}',
                  wordStates: <WordKey, MushafWordState>{
                    for (var word = 0; word < words.length; word += 2)
                      words[word]: MushafWordState.hidden,
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final class _FakeLayoutSource implements MushafLayoutSource {
  @override
  Future<MushafPageData> loadPage(int pageNumber) async {
    return MushafPageData(
      pageNumber: pageNumber,
      lines: <MushafLineData>[
        MushafLineData(<MushafFragment>[
          MushafFragment(
            glyph: 'FAKE SURAH TITLE — PAGE $pageNumber',
            kind: MushafFragmentKind.surahTitle,
          ),
        ]),
        const MushafLineData(<MushafFragment>[
          MushafFragment(
            glyph: 'TODO_CONTENT BASMALA PLACEHOLDER',
            kind: MushafFragmentKind.basmala,
          ),
        ]),
        for (var line = 3; line <= 15; line += 1)
          MushafLineData(<MushafFragment>[
            for (var word = 1; word <= 5; word += 1)
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
      ayahSemantics: <MushafAyahSemantics>[
        MushafAyahSemantics(
          surah: 2,
          ayah: pageNumber == 582 ? 1 : 2,
          canonicalText: 'TODO_CONTENT canonical placeholder for page '
              '$pageNumber',
        ),
      ],
    );
  }
}
