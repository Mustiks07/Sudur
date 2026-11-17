import 'dart:async';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/repositories/prototype_repository.dart';
import 'package:sudur/data/services/prototype_content.dart';

/// Screen state; serialized operations prevent background/load races.
final class PrototypeViewModel extends ChangeNotifier {
  /// Binds the screen to the injected session repository.
  new(this.repository) {
    _events = repository.events.listen(_onEvent);
    _statuses = repository.status.listen((status) {
      state = status;
      if (status == 'stopped' ||
          status == 'failed' ||
          status == 'interrupted') {
        running = false;
      }
      _notify();
    });
  }

  /// Data source for this dev-only screen.
  final PrototypeRepository repository;
  late final StreamSubscription<SessionEvent> _events;
  late final StreamSubscription<String> _statuses;
  Future<void> _queue = Future<void>.value();
  bool _disposed = false;

  /// Current lifecycle code, localized by the view.
  String state = 'idle';

  /// Whether a serialized operation is in flight.
  bool busy = false;

  /// Whether capture is running.
  bool running = false;

  /// User-selected installed model.
  String model = 'quran-asr-small';

  /// True uses the explicitly sideloaded input.wav.
  bool fromFile = false;

  /// Current fifteen-line pages.
  PrototypeContent? content;

  /// Loads only available prototype fonts.
  PageFontLoader? fonts;

  /// Revelation state, independent of correctness.
  final Map<WordKey, MushafWordState> words = {};

  /// Benchmark recommendation, not a speech-quality claim.
  AsrDeviceDecision? recommendation;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Runs one operation after previous operations and reports errors locally.
  Future<void> _run(Future<void> Function() work) {
    return _queue = _queue.then((_) async {
      if (_disposed) return;
      busy = true;
      _notify();
      try {
        await work();
      } on Object {
        state = 'failed';
      } finally {
        busy = false;
        _notify();
      }
    });
  }

  /// Loads canonical data and verified page fonts from the owner directory.
  Future<void> prepare() => _run(() async {
    repository.trace.start();
    repository.trace.add('pageLoadStarted');
    state = 'loading';
    final root = await repository.root();
    content = await PrototypeContent.load(root);
    await PrototypeContent.verifyFonts(root);
    final loader = PageFontLoader(
      fontDirectoryPath: '$root/fonts',
      firstPage: 582,
      lastPage: 583,
    );
    await loader.ensureWindow(582);
    await loader.ensureWindow(583);
    fonts = loader;
    repository.trace.add('fontsLoaded');
    for (final word in content!.words) {
      // Content was assigned above.
      words[word.key] = word.key.surah == 78
          ? MushafWordState.hidden
          : MushafWordState.normal;
    }
    state = 'ready';
  });

  /// Selects a model only between sessions.
  void selectModel(String value) {
    if (!busy && !running) {
      model = value;
      _notify();
    }
  }

  /// Selects microphone or the owner's prerecorded WAV.
  void selectFile(bool value) {
    if (!busy && !running) {
      fromFile = value;
      _notify();
    }
  }

  /// Starts recall after the view has shown the permission rationale.
  Future<void> start() => _run(() async {
    if (content == null || fonts == null || running) return;
    final loaded = content;
    if (loaded == null) return;
    for (final word in loaded.words) {
      words[word.key] = word.key.surah == 78
          ? MushafWordState.hidden
          : MushafWordState.normal;
    }
    state = 'loading';
    final result = await repository.start(model, fromFile: fromFile);
    running = result is Ok<void>;
    state = running ? 'running' : 'failed';
  });

  /// Ends capture, including when the application leaves the foreground.
  Future<void> stop() => _run(() async {
    if (!running) return;
    state = 'stopping';
    final result = await repository.stop();
    running = false;
    state = result is Ok<void> ? 'stopped' : 'failed';
  });

  /// Measures both models without overlapping active capture.
  Future<void> benchmark() => _run(() async {
    if (running) return;
    final result = await repository.benchmark();
    if (result case Ok<AsrDeviceDecision>(:final value)) {
      recommendation = value;
      model = value == AsrDeviceDecision.tiny
          ? 'quran-asr-tiny'
          : 'quran-asr-small';
      state = 'ready';
    } else {
      state = 'failed';
    }
  });

  /// Shares the explicitly requested timing report.
  Future<void> share() => _run(() => repository.share(model));

  /// Opens the text for self-check without correctness marks.
  void showForSelfCheck() {
    if (busy || running) return;
    words.updateAll((key, value) => MushafWordState.normal);
    _notify();
  }

  void _onEvent(SessionEvent event) {
    switch (event) {
      case WordRevealed():
        words[event.word] = MushafWordState.normal;
      case PositionLost():
        state = 'lost';
      case PositionUpdate():
        if (running) state = 'running';
      default:
        break;
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_events.cancel());
    unawaited(_statuses.cancel());
    unawaited(_queue.whenComplete(repository.dispose));
    super.dispose();
  }
}
