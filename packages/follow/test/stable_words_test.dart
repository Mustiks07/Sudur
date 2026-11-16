import 'package:contracts/contracts.dart';
import 'package:follow/follow.dart';
import 'package:quran_text/quran_text.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

List<String> texts(List<Token> tokens) => [for (final t in tokens) t.text];

void main() {
  late StableWords stable;
  setUp(
    () => stable = StableWords(
      normalizer: Normalizer.builtIn,
      confirmations: FollowParams.defaults.stableConfirmations,
    ),
  );

  List<List<String>> feed(RecognitionScript script) => [
        for (final r in script.results) texts(stable.accept(r)),
      ];

  test('a partial word is stable once two partials agree on it', () {
    final out = feed(RecognitionScript()..segment(['a', 'b', 'c']));
    expect(out, [
      <String>[],
      ['a'],
      ['b'],
      ['c'],
    ]);
  });

  test('a word that changes between partials waits for agreement', () {
    final out = feed(
      RecognitionScript()
        ..segmentWithPartials(
          [
            ['a', 'x'],
            ['a', 'b'],
            ['a', 'b', 'c'],
          ],
          ['a', 'b', 'c', 'd'],
        ),
    );
    expect(out.expand((w) => w), ['a', 'b', 'c', 'd']);
    expect(out.expand((w) => w), isNot(contains('x')));
  });

  test('the final result makes the rest stable; later results are ignored', () {
    final script = RecognitionScript()..segment(['a', 'b']);
    final results = script.results;
    final out = [for (final r in results) texts(stable.accept(r))];
    expect(out.expand((w) => w), ['a', 'b']);
    expect(stable.accept(results.last), isEmpty);
  });

  test('sliding windows are stitched by overlap', () {
    final out = feed(
      RecognitionScript()
        ..slidingSegment(['a', 'b', 'c', 'd', 'e', 'f'], windowWords: 3),
    );
    expect(out.expand((w) => w), ['a', 'b', 'c', 'd', 'e', 'f']);
  });

  test('keeps tokens as recognized next to their keys', () {
    final mark = String.fromCharCode(0x064E);
    final tokens = stable.tokenize('a$mark b');
    expect(tokens.map((t) => t.text), ['a$mark', 'b']);
    expect(tokens.map((t) => t.key), const [SearchKey('a'), SearchKey('b')]);
  });

  test('a new segment starts afresh', () {
    final script = RecognitionScript()
      ..segment(['a', 'b'])
      ..segment(['a', 'b']);
    expect(feed(script).expand((w) => w), ['a', 'b', 'a', 'b']);
  });

  test('FollowParams.fromJson keeps defaults for missing keys', () {
    final p =
        FollowParams.fromJson(const {'beamSize': 7, 'openThreshold': 0.8});
    expect(p.beamSize, 7);
    expect(p.openThreshold, 0.8);
    expect(p.maxSkip, FollowParams.defaults.maxSkip);
    expect(
      () => FollowParams.fromJson(const {'beamSize': 'x'}),
      throwsFormatException,
    );
  });

  test('scripted results carry the session and segment ids', () {
    final r = (RecognitionScript(sessionId: 's')..segment(['a'])).results;
    expect(r.map((x) => (x.sessionId, x.segmentId, x.isFinal)), [
      ('s', 1, false),
      ('s', 1, true),
    ]);
    expect(r.first, isA<RecognitionResult>());
  });
}
