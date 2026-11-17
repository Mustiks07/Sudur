import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Loads the bytes for a 1-based page number.
typedef PageFontBytesLoader = Future<ByteData> Function(int pageNumber);

/// Registers font bytes under a runtime font family.
typedef PageFontRegistrar = Future<void> Function(
  String family,
  ByteData bytes,
);

/// Runs asynchronous work at an idle scheduler priority.
typedef PageFontTaskScheduler = Future<void> Function(
  Future<void> Function() task,
);

/// Resolves a file or family name from a 1-based page number.
typedef PageFontNameResolver = String Function(int pageNumber);

/// Loads page fonts around the current page during runtime.
///
/// Flutter cannot unload registered fonts. The window controls which fonts
/// are requested for each current page; already registered pages are reused.
final class PageFontLoader {
  /// Creates a loader for fonts stored in [fontDirectoryPath].
  ///
  /// The default file convention is `p<page>.ttf`, and the default runtime
  /// family is `MushafPage<page>`. Both conventions can be overridden.
  PageFontLoader({
    required String fontDirectoryPath,
    this.pageFontWindow = 3,
    this.firstPage = 1,
    this.lastPage = 604,
    PageFontNameResolver? fileNameForPage,
    PageFontNameResolver? familyForPage,
  })  : assert(pageFontWindow >= 0, 'pageFontWindow must not be negative'),
        assert(firstPage >= 1, 'firstPage must be positive'),
        assert(lastPage >= firstPage, 'lastPage must follow firstPage'),
        _familyForPage = familyForPage ?? _defaultFamily,
        _bytesLoader = _fileLoader(
          fontDirectoryPath,
          fileNameForPage ?? _defaultFileName,
        ),
        _registrar = _registerWithFlutter,
        _scheduler = _scheduleAtIdle;

  /// Creates an injectable loader for tests and non-file font stores.
  PageFontLoader.custom({
    required PageFontBytesLoader bytesLoader,
    required PageFontRegistrar registrar,
    required PageFontTaskScheduler scheduler,
    PageFontNameResolver? familyForPage,
    this.pageFontWindow = 3,
    this.firstPage = 1,
    this.lastPage = 604,
  })  : assert(pageFontWindow >= 0, 'pageFontWindow must not be negative'),
        assert(firstPage >= 1, 'firstPage must be positive'),
        assert(lastPage >= firstPage, 'lastPage must follow firstPage'),
        _bytesLoader = bytesLoader,
        _registrar = registrar,
        _scheduler = scheduler,
        _familyForPage = familyForPage ?? _defaultFamily;

  /// Number of neighboring pages requested on each side.
  final int pageFontWindow;

  /// First page available in this Mushaf edition.
  final int firstPage;

  /// Last page available in this Mushaf edition.
  final int lastPage;

  final PageFontBytesLoader _bytesLoader;
  final PageFontRegistrar _registrar;
  final PageFontTaskScheduler _scheduler;
  final PageFontNameResolver _familyForPage;
  final Set<int> _loadedPages = <int>{};
  final Map<int, Future<void>> _inFlight = <int, Future<void>>{};

  /// Pages that have been registered successfully.
  Set<int> get loadedPages => Set<int>.unmodifiable(_loadedPages);

  /// Returns the runtime family assigned to [pageNumber].
  String familyForPage(int pageNumber) => _familyForPage(pageNumber);

  /// Ensures the current page and its configured neighbor window are loaded.
  ///
  /// The current page is loaded first. Neighbor fonts are scheduled at idle
  /// priority, nearest pages first, to keep page interaction responsive.
  Future<void> ensureWindow(int pageNumber) async {
    _checkPage(pageNumber);
    await _ensurePage(pageNumber, scheduleAtIdle: false);
    for (var distance = 1; distance <= pageFontWindow; distance += 1) {
      final before = pageNumber - distance;
      final after = pageNumber + distance;
      if (before >= firstPage) {
        await _ensurePage(before, scheduleAtIdle: true);
      }
      if (after <= lastPage) {
        await _ensurePage(after, scheduleAtIdle: true);
      }
    }
  }

  Future<void> _ensurePage(
    int pageNumber, {
    required bool scheduleAtIdle,
  }) {
    if (_loadedPages.contains(pageNumber)) return Future<void>.value();
    final pending = _inFlight[pageNumber];
    if (pending != null) return pending;

    Future<void> load() async {
      final bytes = await _bytesLoader(pageNumber);
      await _registrar(familyForPage(pageNumber), bytes);
      _loadedPages.add(pageNumber);
    }

    final started = scheduleAtIdle ? _scheduler(load) : load();
    late final Future<void> operation;
    operation = started.whenComplete(() {
      final removed = _inFlight.remove(pageNumber);
      if (!identical(removed, operation)) {
        throw StateError('Page font loading state changed unexpectedly');
      }
    });
    _inFlight[pageNumber] = operation;
    return operation;
  }

  void _checkPage(int pageNumber) {
    if (pageNumber < firstPage || pageNumber > lastPage) {
      throw RangeError.range(
        pageNumber,
        firstPage,
        lastPage,
        'pageNumber',
      );
    }
  }

  static PageFontBytesLoader _fileLoader(
    String directory,
    PageFontNameResolver fileNameForPage,
  ) {
    return (int pageNumber) async {
      final separator = directory.endsWith(Platform.pathSeparator) ? '' : '/';
      final file = File('$directory$separator${fileNameForPage(pageNumber)}');
      final bytes = await file.readAsBytes();
      return ByteData.sublistView(bytes);
    };
  }

  static Future<void> _registerWithFlutter(
    String family,
    ByteData bytes,
  ) async {
    final loader = FontLoader(family)..addFont(Future<ByteData>.value(bytes));
    await loader.load();
  }

  static Future<void> _scheduleAtIdle(
    Future<void> Function() task,
  ) {
    return SchedulerBinding.instance.scheduleTask<void>(
      task,
      Priority.idle,
      debugLabel: 'load Mushaf page font',
    );
  }

  static String _defaultFileName(int pageNumber) => 'p$pageNumber.ttf';

  static String _defaultFamily(int pageNumber) => 'MushafPage$pageNumber';
}
