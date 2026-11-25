import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_content_parser.dart';
import 'package:sudur/data/services/prototype_session.dart';

// The class names keep the repository easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Data of the reading screen (docs/tz 13.3).
abstract interface class ReadingRepository {
  /// Prepares [from]–[to]: the text from the canon, the mushaf pages when
  /// the passage has layout, and the voice session when the model is
  /// downloaded. Downloads the text if needed, never the model.
  Future<Result<ReadingPassage>> prepare({
    required WordKey from,
    required WordKey to,
  });

  /// Downloads the model, the VAD model and the prototype pages.
  Future<Result<void>> downloadModel({
    required void Function(PrototypeDownloadProgress progress) onProgress,
  });
}

/// Rules version written with every event (docs/tz 12.4 values).
const String readingRulesVersion = 'tz-12.4-v1';

/// Pages with layout in the prototype (ADR 0002).
const List<int> _layoutPages = [582, 583];

/// File-backed repository over the verified installed resources.
final class LocalReadingRepository implements ReadingRepository {
  /// Creates the repository.
  const LocalReadingRepository(
    this._installer, [
    this._parser = const PrototypeContentParser(),
  ]);

  final PrototypeAssetInstaller _installer;
  final PrototypeContentParser _parser;

  @override
  Future<Result<ReadingPassage>> prepare({
    required WordKey from,
    required WordKey to,
  }) async {
    try {
      final canon = await _installer.installCanon(onProgress: (_) {});
      final textJson = await File(canon.textPath).readAsString();
      final text = await Isolate.run(() => readPassageText(textJson, from, to));
      final installed = await _installer.installedFiles();
      final pages = await _layout(installed, text.words);
      final model = installed.modelDirectory;
      final vad = installed.vadModelPath;
      final voice = model != null && vad != null;
      return Result.ok(
        ReadingPassage(
          from: from,
          to: to,
          ayahs: text.ayahs,
          pages: pages?.pages,
          fontFamilies: pages?.fontFamilies ?? const {},
          session: voice
              ? PrototypeSessionConfiguration(
                  words: text.words,
                  contentJson: textJson,
                  wholeQuranText: true,
                  normalizerJson: await File('$model/normalizer.json')
                      .readAsString(),
                  modelDirectory: model,
                  vadModelPath: vad,
                  textVersion: text.textVersion,
                  rulesVersion: readingRulesVersion,
                )
              : null,
          limits: voice ? await _limits(model) : null,
        ),
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<void>> downloadModel({
    required void Function(PrototypeDownloadProgress progress) onProgress,
  }) async {
    try {
      await _installer.install(
        PrototypeModelChoice.small,
        onProgress: onProgress,
      );
      return const Result.ok(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<({List<MushafPageData> pages, Map<int, String> fontFamilies})?>
  _layout(PrototypeInstalledFiles installed, List<WordKey> words) async {
    final contentPath = installed.contentPath;
    final fonts = installed.fontDirectory;
    if (contentPath == null || fonts == null) return null;
    final content = _parser.parse(await File(contentPath).readAsString());
    final onPages = {
      for (final page in content.pages)
        for (final line in page.lines)
          for (final fragment in line.fragments) ?fragment.wordKey,
    };
    if (!words.every(onPages.contains)) return null;
    final loader = PageFontLoader(
      fontDirectoryPath: fonts,
      pageFontWindow: 0,
      firstPage: _layoutPages.first,
      lastPage: _layoutPages.last,
    );
    for (final page in _layoutPages) {
      await loader.ensureWindow(page);
    }
    return (
      pages: content.pages,
      fontFamilies: {for (final p in _layoutPages) p: loader.familyForPage(p)},
    );
  }

  Future<ReadingLimits> _limits(String modelDirectory) async {
    final json = jsonDecode(
      await File('$modelDirectory/thresholds.json').readAsString(),
    );
    int value(String key) => switch (json) {
      final Map<String, Object?> map when map[key] is num =>
        (map[key]! as num).toInt(),
      // Checked by the guard just above.
      _ => throw FormatException('thresholds.json has no $key.'),
    };
    return ReadingLimits(
      stuckWordTries: value('stuckWordTries'),
      strictMaxFails: value('strictMaxFails'),
      strictMaxWaitMs: value('strictMaxWaitMs'),
    );
  }
}

/// The words of [from]–[to] from the whole-Quran text JSON (format 2),
/// unchanged. Throws [FormatException] for a range outside the text.
@visibleForTesting
({List<ReadingAyah> ayahs, List<WordKey> words, String textVersion})
readPassageText(String json, WordKey from, WordKey to) {
  final root = jsonDecode(json);
  if (root case {
    'format': 2,
    'kind': 'text',
    'contentVersion': {'canonSha256': final String sha},
    'ayahs': final List<Object?> ayahs,
  }) {
    final result = <ReadingAyah>[];
    for (final entry in ayahs) {
      if (entry case [final int surah, final int ayah, final List<Object?> w]) {
        final words = <ReadingWord>[
          for (final (i, text) in w.indexed)
            if (text is String)
              ReadingWord(key: WordKey(surah, ayah, i + 1), text: text),
        ];
        final inside = words
            .where(
              (word) =>
                  word.key.compareTo(from) >= 0 && word.key.compareTo(to) <= 0,
            )
            .toList();
        if (inside.isNotEmpty) {
          result.add(ReadingAyah(surah: surah, ayah: ayah, words: inside));
        }
      }
    }
    final keys = [
      for (final ayah in result)
        for (final word in ayah.words) word.key,
    ];
    if (keys.isEmpty || keys.first != from || keys.last != to) {
      throw FormatException('No passage $from–$to in the text.');
    }
    return (
      ayahs: result,
      words: keys,
      textVersion: 'tanzil-${sha.substring(0, 12)}',
    );
  }
  throw const FormatException('Expected the text JSON, format 2.');
}
