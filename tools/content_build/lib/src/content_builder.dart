import 'dart:convert';
import 'dart:io';

import 'package:content_build/src/build_config.dart';
import 'package:content_build/src/canon_checksum.dart';
import 'package:content_build/src/content_assembler.dart';
import 'package:content_build/src/content_build_exception.dart';
import 'package:content_build/src/content_checks.dart';
import 'package:content_build/src/content_model.dart';
import 'package:content_build/src/layout_parser.dart';
import 'package:content_build/src/source_fetcher.dart';
import 'package:content_build/src/sqlite_writer.dart';
import 'package:content_build/src/tanzil_parser.dart';
import 'package:contracts/contracts.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// First four bytes of a TrueType font file.
const List<int> trueTypeMagic = [0x00, 0x01, 0x00, 0x00];

/// Runs a content build: download, parse, check (ПР-04), assemble, write.
final class ContentBuilder {
  /// Creates a builder.
  ContentBuilder({
    required BuildConfig config,
    required SourceFetcher fetcher,
    required Logger logger,
  })  : _config = config,
        _fetcher = fetcher,
        _logger = logger;

  final BuildConfig _config;
  final SourceFetcher _fetcher;
  final Logger _logger;

  /// Downloads and checks the sources and assembles the tables.
  Future<Result<ContentData>> build() async {
    try {
      return Result.ok(await _build());
    } on ContentBuildException catch (e) {
      return Result.error(e);
    }
  }

  /// Downloads the page fonts into [directory] and returns their SHA-256 by
  /// file name.
  Future<Result<Map<String, String>>> fetchFonts(String directory) async {
    try {
      final sums = <String, String>{};
      Directory(directory).createSync(recursive: true);
      for (final page in _config.pages) {
        final name = 'p$page.ttf';
        final bytes = await _fetcher.fetch(
          Uri.parse(_config.fonts.urlFor(page: page)),
          p.join('fonts', _config.layoutId, name),
        );
        if (bytes.length < trueTypeMagic.length ||
            !_startsWith(bytes, trueTypeMagic)) {
          throw ContentBuildException('$name is not a TrueType font.');
        }
        File(p.join(directory, name)).writeAsBytesSync(bytes);
        sums[name] = bytesChecksum(bytes);
      }
      return Result.ok(sums);
    } on ContentBuildException catch (e) {
      return Result.error(e);
    } on FileSystemException catch (e) {
      return Result.error(e);
    }
  }

  Future<ContentData> _build() async {
    final textBytes = await _fetcher.fetch(
      Uri.parse(_config.text.url),
      'tanzil/quran-uthmani.xml',
    );
    final quran = parseTanzilXml(utf8.decode(textBytes));
    _failOn('canon', checkCanon(quran, _config));
    _logger.info(
      'canon ok: ${quran.surahs.length} surahs, ${quran.ayahCount} ayahs',
    );

    final pageVerses = <LayoutVerse>[];
    for (final page in _config.pages) {
      final bytes = await _fetcher.fetch(
        Uri.parse(_config.layout.urlFor(page: page)),
        p.join('layout', _config.layoutId, 'page$page.json'),
      );
      pageVerses.addAll(parseLayoutPage(utf8.decode(bytes)));
    }
    final verses = mergeLayoutVerses(pageVerses);

    final chapters = <int, LayoutChapter>{};
    for (final surah in verses.map((v) => v.surah).toSet()) {
      final bytes = await _fetcher.fetch(
        Uri.parse(_config.chapters.urlFor(surah: surah)),
        p.join('chapters', 'chapter$surah.json'),
      );
      chapters[surah] = parseLayoutChapter(utf8.decode(bytes));
    }
    _failOn(
      'layout',
      checkLayout(
        quran: quran,
        verses: verses,
        chapters: chapters,
        config: _config,
      ),
    );
    _logger.info('layout ok: ${verses.length} ayahs on pages ${_config.pages}');

    return assembleContent(
      config: _config,
      quran: quran,
      verses: verses,
      chapters: chapters,
      version: _version(quran, textBytes),
    );
  }

  Map<String, String> _version(TanzilQuran quran, List<int> textBytes) => {
        'version': _config.version,
        'buildId': _config.id,
        'layoutId': _config.layoutId,
        'pages': _config.pages.join(','),
        'textSource': _config.text.name,
        'textUrl': _config.text.url,
        'textLicense': _config.text.license,
        'textAttribution': _config.text.attribution,
        'textNotice': quran.notice,
        'textFileSha256': bytesChecksum(textBytes),
        'canonSha256': canonChecksum(quran),
        'layoutSource': _config.layout.name,
        'layoutUrl': _config.layout.url,
        'layoutLicense': _config.layout.license,
        'layoutAttribution': _config.layout.attribution,
        'fontSource': _config.fonts.name,
        'fontUrl': _config.fonts.url,
        'fontLicense': _config.fonts.license,
        'fontAttribution': _config.fonts.attribution,
      };

  void _failOn(String stage, List<String> failures) {
    if (failures.isEmpty) return;
    failures.forEach(_logger.severe);
    throw ContentBuildException(
      '$stage checks failed: ${failures.length} problem(s), first: '
      '${failures.first}',
    );
  }
}

bool _startsWith(List<int> bytes, List<int> prefix) {
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

/// Writes [data] as indented JSON to [path].
void writeContentJson(ContentData data, String path) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(data.toJson())}\n',
    );
}

/// Writes [data] as a SQLite database to [path].
void writeContentDatabase(ContentData data, String path) {
  File(path).parent.createSync(recursive: true);
  writeContentSqlite(data, path);
}
