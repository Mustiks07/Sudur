import 'dart:io';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_content_parser.dart';
import 'package:sudur/data/services/prototype_platform_service.dart';
import 'package:sudur/data/services/prototype_session.dart';

/// Data needed by the prototype reading screen.
final class PrototypeBundle {
  /// Creates a prepared bundle.
  const new({
    required this.pages,
    required this.fontFamilies,
    required this.sessionWords,
    required this.modelDirectory,
    required this.sessionConfiguration,
  });

  /// Pages 582–583.
  final List<MushafPageData> pages;

  /// Runtime font family per page number.
  final Map<int, String> fontFamilies;

  /// Surah 78 words passed to the reading session.
  final List<WordKey> sessionWords;

  /// Verified ASR package path for the selected model.
  final String modelDirectory;

  /// Verified resources used to build the real session in its worker.
  final PrototypeSessionConfiguration sessionConfiguration;
}

/// Repository boundary used by `ReadingViewModel`.
abstract interface class PrototypeRepository {
  /// Installs verified resources and builds screen data.
  Future<PrototypeBundle> prepare(
    PrototypeModelChoice model, {
    required void Function(PrototypeDownloadProgress progress) onProgress,
  });

  /// Runs the existing `asr_sherpa` phone benchmark.
  Future<AsrDeviceBenchmark> benchmark(PrototypeBundle bundle);

  /// Selects a local WAV for measurement mode.
  Future<String?> pickWavFile();

  /// Writes and shares a JSON measurement log.
  Future<void> shareLog(String json);
}

/// File-backed production-development repository.
final class LocalPrototypeRepository implements PrototypeRepository {
  /// Creates the repository.
  const new(
    this._installer,
    this._platform, [
    this._parser = const PrototypeContentParser(),
  ]);

  final PrototypeAssetInstaller _installer;
  final PrototypePlatformService _platform;
  final PrototypeContentParser _parser;

  @override
  Future<PrototypeBundle> prepare(
    PrototypeModelChoice model, {
    required void Function(PrototypeDownloadProgress progress) onProgress,
  }) async {
    final resources = await _installer.install(model, onProgress: onProgress);
    final json = await File(resources.contentPath).readAsString();
    final normalizerJson = await File(
      '${resources.modelDirectory}/normalizer.json',
    ).readAsString();
    final content = _parser.parse(json);
    final fontLoader = PageFontLoader(
      fontDirectoryPath: resources.fontDirectory,
      pageFontWindow: 0,
      firstPage: 582,
      lastPage: 583,
    );
    await fontLoader.ensureWindow(582);
    await fontLoader.ensureWindow(583);
    return PrototypeBundle(
      pages: content.pages,
      fontFamilies: <int, String>{
        582: fontLoader.familyForPage(582),
        583: fontLoader.familyForPage(583),
      },
      sessionWords: content.sessionWords,
      modelDirectory: resources.modelDirectory,
      sessionConfiguration: PrototypeSessionConfiguration(
        words: content.sessionWords,
        contentJson: json,
        normalizerJson: normalizerJson,
        modelDirectory: resources.modelDirectory,
        vadModelPath: resources.vadModelPath,
        textVersion: 'content-p582-583-928326595eea',
        rulesVersion: 'tz-12.4-v1',
      ),
    );
  }

  @override
  Future<AsrDeviceBenchmark> benchmark(PrototypeBundle bundle) async {
    final recognizer = SherpaCtcRecognizer(sessionId: 'prototype-benchmark');
    try {
      final loaded = await recognizer.load(bundle.modelDirectory);
      if (loaded case Error<void>(:final error)) throw error;
      return switch (await recognizer.benchmarkDevice()) {
        Ok<AsrDeviceBenchmark>(:final value) => value,
        Error<AsrDeviceBenchmark>(:final error) => throw error,
      };
    } finally {
      await recognizer.dispose();
    }
  }

  @override
  Future<String?> pickWavFile() => _platform.pickWavFile();

  @override
  Future<void> shareLog(String json) async {
    final directory = Directory(
      '${await _platform.applicationDirectory()}/measurement-logs',
    );
    await directory.create(recursive: true);
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp('[:.]'),
      '-',
    );
    final file = File('${directory.path}/sudur-prototype-$timestamp.json');
    await file.writeAsString(json, flush: true);
    await _platform.shareFile(file.path);
  }
}
