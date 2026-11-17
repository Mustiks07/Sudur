import 'dart:convert';

import 'package:content_build/src/content_build_exception.dart';
import 'package:meta/meta.dart';

/// One downloadable source with its license (docs/tz requirement ПР-02).
@immutable
final class SourceConfig {
  /// Creates a source description.
  const SourceConfig({
    required this.name,
    required this.url,
    required this.license,
    required this.attribution,
  });

  /// Human-readable source name.
  final String name;

  /// Download URL; may contain `{page}` or `{surah}` placeholders.
  final String url;

  /// SPDX identifier or `LicenseRef-…`. Must not be empty.
  final String license;

  /// Link or text that must be shown to users.
  final String attribution;

  /// [url] with placeholders replaced.
  String urlFor({int? page, int? surah}) => url
      .replaceAll('{page}', '${page ?? ''}')
      .replaceAll('{surah}', '${surah ?? ''}');
}

/// Description of one content build, read from a JSON file in `config/`.
@immutable
final class BuildConfig {
  /// Creates a build config.
  const BuildConfig({
    required this.id,
    required this.version,
    required this.pages,
    required this.layoutId,
    required this.linesPerPage,
    required this.expectedSurahCount,
    required this.expectedAyahCount,
    required this.expectedCanonSha256,
    required this.expectedFirstAyah,
    required this.expectedLastAyah,
    required this.text,
    required this.layout,
    required this.chapters,
    required this.fonts,
  });

  /// Parses a config file. Throws [ContentBuildException] if a field is
  /// missing or a license identifier is empty (ПР-02).
  factory BuildConfig.fromJson(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw ContentBuildException('Config is not JSON: ${e.message}');
    }
    final root = _object(decoded, 'config');
    final pages = _list(root['pages'], 'pages').map((p) {
      if (p is int) return p;
      throw const ContentBuildException('pages must hold integers.');
    }).toList();
    if (pages.isEmpty) {
      throw const ContentBuildException('pages must not be empty.');
    }
    final expected = _object(root['expected'], 'expected');
    return BuildConfig(
      id: _string(root['id'], 'id'),
      version: _string(root['version'], 'version'),
      pages: List.unmodifiable(pages),
      layoutId: _string(root['layoutId'], 'layoutId'),
      linesPerPage: _int(root['linesPerPage'], 'linesPerPage'),
      expectedSurahCount: _int(expected['surahs'], 'expected.surahs'),
      expectedAyahCount: _int(expected['ayahs'], 'expected.ayahs'),
      expectedFirstAyah: _ayah(expected['firstAyah'], 'expected.firstAyah'),
      expectedLastAyah: _ayah(expected['lastAyah'], 'expected.lastAyah'),
      expectedCanonSha256: _string(
        expected['canonSha256'],
        'expected.canonSha256',
      ),
      text: _source(root['text'], 'text'),
      layout: _source(root['layout'], 'layout'),
      chapters: _source(root['chapters'], 'chapters'),
      fonts: _source(root['fonts'], 'fonts'),
    );
  }

  /// Build identifier, also the output folder name.
  final String id;

  /// Content version written to `content_version`.
  final String version;

  /// Mushaf pages in the build scope.
  final List<int> pages;

  /// Identifier of the page layout.
  final String layoutId;

  /// Lines on every page of the layout.
  final int linesPerPage;

  /// Number of surahs the text source must have (ПР-04).
  final int expectedSurahCount;

  /// Number of ayahs the text source must have (ПР-04).
  final int expectedAyahCount;

  /// Pinned checksum of the canonical text (ПР-04).
  final String expectedCanonSha256;

  /// First ayah of the scope, `(surah, ayah)`: the top of the first page in
  /// the printed mushaf. Pinned so a layout source that drops it fails.
  final (int, int) expectedFirstAyah;

  /// Last ayah of the scope, `(surah, ayah)`: the end of the last page.
  final (int, int) expectedLastAyah;

  /// Canonical text source.
  final SourceConfig text;

  /// Page layout and glyph codes source.
  final SourceConfig layout;

  /// Surah metadata source.
  final SourceConfig chapters;

  /// Page fonts source.
  final SourceConfig fonts;
}

(int, int) _ayah(Object? value, String what) {
  final parts = value is String ? value.split(':') : const <String>[];
  final surah = parts.length == 2 ? int.tryParse(parts[0]) : null;
  final ayah = parts.length == 2 ? int.tryParse(parts[1]) : null;
  if (surah == null || ayah == null) {
    throw ContentBuildException('Config: $what must look like "78:1".');
  }
  return (surah, ayah);
}

SourceConfig _source(Object? value, String what) {
  final map = _object(value, what);
  final license = map['license'];
  if (license is! String || license.trim().isEmpty) {
    throw ContentBuildException(
      'Source "$what" has no license identifier; refusing to build (ПР-02).',
    );
  }
  return SourceConfig(
    name: _string(map['name'], '$what.name'),
    url: _string(map['url'], '$what.url'),
    license: license,
    attribution: _string(map['attribution'], '$what.attribution'),
  );
}

Map<String, Object?> _object(Object? value, String what) {
  if (value is Map<String, Object?>) return value;
  throw ContentBuildException('Config: expected an object for $what.');
}

List<Object?> _list(Object? value, String what) {
  if (value is List<Object?>) return value;
  throw ContentBuildException('Config: expected a list for $what.');
}

String _string(Object? value, String what) {
  if (value is String && value.isNotEmpty) return value;
  throw ContentBuildException('Config: expected a non-empty string for $what.');
}

int _int(Object? value, String what) {
  if (value is int) return value;
  throw ContentBuildException('Config: expected an integer for $what.');
}
