import 'package:content_build/content_build.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('segmentAyah', () {
    test('splits on the separator', () {
      expect(segmentAyah('a b c'), ['a', 'b', 'c']);
    });

    test('keeps a sign token attached to the previous word', () {
      expect(segmentAyah('a $pauseMark b'), ['a $pauseMark', 'b']);
    });

    test('is lossless: joining words gives the text back', () {
      final text = 'a $pauseMark b c $pauseMark$pauseMark d';
      expect(segmentAyah(text).join(tanzilTokenSeparator), text);
    });

    test('rejects a leading sign token and empty tokens', () {
      expect(
        () => segmentAyah('$pauseMark a'),
        throwsA(isA<ContentBuildException>()),
      );
      expect(
        () => segmentAyah('a  b'),
        throwsA(isA<ContentBuildException>()),
      );
    });

    test('isSignToken covers only the annotation range', () {
      expect(isSignToken(String.fromCharCode(quranicSignLast)), isTrue);
      expect(isSignToken(String.fromCharCode(quranicSignLast + 1)), isFalse);
      expect(isSignToken('a$pauseMark'), isFalse);
      expect(isSignToken(''), isFalse);
    });
  });

  group('parseTanzilXml', () {
    test('reads surahs, ayahs, basmala and the notice verbatim', () {
      final quran = syntheticQuran();
      expect(quran.surahs, hasLength(2));
      expect(quran.ayahCount, 4);
      expect(quran.surah(1).ayahs[1].text, 'c1 $pauseMark d1');
      expect(quran.surah(1).ayahs.first.bismillah, isNull);
      expect(quran.surah(2).ayahs.first.bismillah, 'x y');
      expect(quran.notice, contains('Tanzil test notice'));
    });

    test('refuses a file without the Tanzil notice', () {
      expect(
        () => parseTanzilXml(syntheticTanzilXml(notice: 'nothing')),
        throwsA(isA<ContentBuildException>()),
      );
    });

    test('refuses out-of-order ayahs and malformed XML', () {
      final swapped = syntheticTanzilXml().replaceFirst(
        '<aya index="2" text="h2',
        '<aya index="3" text="h2',
      );
      expect(
        () => parseTanzilXml(swapped),
        throwsA(isA<ContentBuildException>()),
      );
      expect(
        () => parseTanzilXml('<quran>'),
        throwsA(isA<ContentBuildException>()),
      );
    });
  });

  group('canonChecksum', () {
    test('ignores the notice but sees every character of the text', () {
      final base = canonChecksum(syntheticQuran());
      final otherNotice = parseTanzilXml(
        syntheticTanzilXml(notice: 'Tanzil, another year'),
      );
      expect(canonChecksum(otherNotice), base);

      final changed = parseTanzilXml(
        syntheticTanzilXml().replaceFirst('a1 b1', 'a1 b2'),
      );
      expect(canonChecksum(changed), isNot(base));
    });
  });
}
