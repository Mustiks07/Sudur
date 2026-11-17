import 'package:content_build/src/content_build_exception.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

/// One ayah of the Tanzil text, exactly as in the source file.
@immutable
final class TanzilAyah {
  /// Creates an ayah.
  const TanzilAyah({required this.index, required this.text, this.bismillah});

  /// Ayah number within the surah.
  final int index;

  /// Ayah text, verbatim.
  final String text;

  /// Basmala printed before the surah, given on the first ayah only.
  final String? bismillah;
}

/// One surah of the Tanzil text.
@immutable
final class TanzilSurah {
  /// Creates a surah.
  const TanzilSurah({
    required this.index,
    required this.name,
    required this.ayahs,
  });

  /// Surah number.
  final int index;

  /// Arabic name, verbatim.
  final String name;

  /// Ayahs in order.
  final List<TanzilAyah> ayahs;
}

/// The whole Tanzil Quran text with its copyright notice.
@immutable
final class TanzilQuran {
  /// Creates the parsed text.
  const TanzilQuran({required this.notice, required this.surahs});

  /// The copyright block of the source file, verbatim. Tanzil requires it to
  /// be reproduced in derived files.
  final String notice;

  /// Surahs in order.
  final List<TanzilSurah> surahs;

  /// Number of ayahs in the whole text.
  int get ayahCount => surahs.fold(0, (sum, s) => sum + s.ayahs.length);

  /// Surah [number], 1-based.
  TanzilSurah surah(int number) => surahs[number - 1];
}

/// Parses the Tanzil XML export (`outType=xml`).
///
/// Throws [ContentBuildException] if the structure is not as expected. Text
/// is taken as is: nothing is trimmed, normalized or re-encoded.
TanzilQuran parseTanzilXml(String source) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(source);
  } on XmlException catch (e) {
    throw ContentBuildException('Tanzil XML is malformed: ${e.message}');
  }

  final notice =
      document.children.whereType<XmlComment>().map((c) => c.value).join('\n');
  if (!notice.contains('Tanzil')) {
    throw const ContentBuildException(
      'Tanzil XML has no copyright notice; refusing to use it.',
    );
  }

  final surahs = <TanzilSurah>[];
  for (final sura in document.rootElement.findElements('sura')) {
    final index = _intAttribute(sura, 'index');
    if (index != surahs.length + 1) {
      throw ContentBuildException('Surah $index is out of order.');
    }
    final ayahs = <TanzilAyah>[];
    for (final aya in sura.findElements('aya')) {
      final ayahIndex = _intAttribute(aya, 'index');
      if (ayahIndex != ayahs.length + 1) {
        throw ContentBuildException('Ayah $index:$ayahIndex is out of order.');
      }
      ayahs.add(
        TanzilAyah(
          index: ayahIndex,
          text: _attribute(aya, 'text'),
          bismillah: aya.getAttribute('bismillah'),
        ),
      );
    }
    surahs.add(
      TanzilSurah(index: index, name: _attribute(sura, 'name'), ayahs: ayahs),
    );
  }
  return TanzilQuran(notice: notice, surahs: surahs);
}

String _attribute(XmlElement element, String name) {
  final value = element.getAttribute(name);
  if (value == null || value.isEmpty) {
    throw ContentBuildException(
      'Element <${element.name}> has no "$name" attribute.',
    );
  }
  return value;
}

int _intAttribute(XmlElement element, String name) {
  final value = int.tryParse(_attribute(element, name));
  if (value == null) {
    throw ContentBuildException(
      'Element <${element.name}> has a non-numeric "$name".',
    );
  }
  return value;
}
