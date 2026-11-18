import 'dart:async';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/repositories/prototype_repository.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_measurement_log.dart';
import 'package:sudur/data/services/prototype_session.dart';

/// Lifecycle shown by the prototype screen.
enum ReadingPrototypeState {
  /// Downloading and validating first-run resources.
  preparing,

  /// Resources and the session are ready.
  ready,

  /// Session events are being consumed.
  running,

  /// The session preserves its position but emits no events.
  paused,

  /// The scripted sequence or manual stop completed.
  finished,

  /// Resource, benchmark, or session preparation failed.
  error,
}

/// UI state and commands for the standalone reading prototype.
final class ReadingViewModel extends ChangeNotifier {
  /// Creates a view model with injected data and session boundaries.
  new(this._repository, this._sessionFactory);

  final PrototypeRepository _repository;
  final PrototypeReadingSessionFactory _sessionFactory;
  final Stopwatch _pageRenderClock = Stopwatch();
  final Set<int> _renderedPages = <int>{};
  PrototypeReadingSession? _session;
  StreamSubscription<SessionEvent>? _events;
  PrototypeBundle? _bundle;
  PrototypeMeasurementLog? _measurementLog;
  String? _wavPath;
  var _prepareGeneration = 0;
  var _disposed = false;

  /// Current screen lifecycle.
  ReadingPrototypeState get state => _state;
  ReadingPrototypeState _state = ReadingPrototypeState.preparing;

  /// Selected model, initially `small` per prototype scope.
  PrototypeModelChoice get selectedModel => _selectedModel;
  PrototypeModelChoice _selectedModel = PrototypeModelChoice.small;

  /// Last first-run download snapshot.
  PrototypeDownloadProgress? get progress => _progress;
  PrototypeDownloadProgress? _progress;

  /// Technical error for a localized generic error surface.
  Object? get error => _error;
  Object? _error;

  /// Prepared pages 582–583.
  List<MushafPageData> get pages => _bundle?.pages ?? const [];

  /// Runtime font family for [pageNumber].
  String? fontFamilyForPage(int pageNumber) =>
      _bundle?.fontFamilies[pageNumber];

  /// Immutable per-word visual state consumed by `MushafPage`.
  Map<WordKey, MushafWordState> get wordStates => Map.unmodifiable(_wordStates);
  final Map<WordKey, MushafWordState> _wordStates =
      <WordKey, MushafWordState>{};

  /// Selected WAV file name, without exposing its full path in the UI.
  String? get selectedWavName {
    return _wavPath?.split(RegExp(r'[/\\]')).last;
  }

  /// Result of the phone benchmark, when run.
  AsrDeviceBenchmark? get benchmarkResult => _benchmarkResult;
  AsrDeviceBenchmark? _benchmarkResult;

  /// Whether a phone test is currently running.
  bool get isBenchmarking => _isBenchmarking;
  var _isBenchmarking = false;

  /// JSON measurement document, exposed for tests and sharing.
  String get measurementJson => _measurementLog?.toJson() ?? '{}';

  /// Downloads verified resources and prepares the default model.
  Future<void> initialize() => _prepare(_selectedModel);

  /// Retries preparation after a visible error.
  Future<void> retry() => _prepare(_selectedModel);

  /// Changes the ASR model, downloading it on demand if necessary.
  Future<void> selectModel(PrototypeModelChoice model) async {
    if (model == _selectedModel) return;
    _selectedModel = model;
    await _prepare(model);
  }

  Future<void> _prepare(PrototypeModelChoice model) async {
    final generation = ++_prepareGeneration;
    _state = ReadingPrototypeState.preparing;
    _progress = null;
    _error = null;
    _benchmarkResult = null;
    notifyListeners();
    await _events?.cancel();
    await _session?.dispose();
    try {
      final bundle = await _repository.prepare(
        model,
        onProgress: (value) {
          if (generation != _prepareGeneration || _disposed) return;
          _progress = value;
          notifyListeners();
        },
      );
      if (generation != _prepareGeneration || _disposed) return;
      _bundle = bundle;
      _wordStates
        ..clear()
        ..addEntries(
          bundle.pages.expand(
            (page) => page.lines.expand(
              (line) => line.fragments
                  .where((fragment) => fragment.wordKey != null)
                  .map(
                    (fragment) => MapEntry(
                      // Checked by the where clause immediately above.
                      fragment.wordKey!,
                      MushafWordState.hidden,
                    ),
                  ),
            ),
          ),
        );
      await _replaceSession(bundle);
      _measurementLog = PrototypeMeasurementLog(modelId: model.name);
      _renderedPages.clear();
      _pageRenderClock
        ..reset()
        ..start();
      _state = ReadingPrototypeState.ready;
      notifyListeners();
    } on Object catch (caught) {
      if (generation != _prepareGeneration || _disposed) return;
      _error = caught;
      _state = ReadingPrototypeState.error;
      notifyListeners();
    }
  }

  /// Starts microphone mode, or measurement mode when a WAV was selected.
  Future<void> start() async {
    if (_state != ReadingPrototypeState.ready &&
        _state != ReadingPrototypeState.finished) {
      return;
    }
    final bundle = _bundle;
    if (bundle == null) return;
    if (_state == ReadingPrototypeState.finished) {
      await _replaceSession(bundle);
      for (final word in _wordStates.keys) {
        _wordStates[word] = MushafWordState.hidden;
      }
    }
    final session = _session;
    if (session == null) return;
    final wavPath = _wavPath;
    _measurementLog?.start(usesWav: wavPath != null);
    await session.start(
      wavPath == null
          ? const PrototypeMicrophoneInput()
          : PrototypeWavInput(wavPath),
    );
    _state = ReadingPrototypeState.running;
    notifyListeners();
  }

  Future<void> _replaceSession(PrototypeBundle bundle) async {
    await _events?.cancel();
    await _session?.dispose();
    final session = _sessionFactory.create(bundle.sessionWords);
    _session = session;
    _events = session.events.listen(_onEvent);
  }

  /// Pauses the current session.
  Future<void> pause() async {
    if (_state != ReadingPrototypeState.running) return;
    await _session?.pause();
    _state = ReadingPrototypeState.paused;
    notifyListeners();
  }

  /// Resumes a paused session.
  Future<void> resume() async {
    if (_state != ReadingPrototypeState.paused) return;
    await _session?.resume();
    _state = ReadingPrototypeState.running;
    notifyListeners();
  }

  /// Stops without treating unread words as errors.
  Future<void> stop() async {
    if (_state != ReadingPrototypeState.running &&
        _state != ReadingPrototypeState.paused) {
      return;
    }
    await _session?.stop();
    _state = ReadingPrototypeState.finished;
    notifyListeners();
  }

  /// Requests a whole-word hint from the session adapter.
  Future<void> requestHint() => _session?.requestHint() ?? Future<void>.value();

  /// Chooses a WAV for the next run through the same session input boundary.
  Future<void> chooseWav() async {
    final path = await _repository.pickWavFile();
    if (path == null || path.isEmpty) return;
    _wavPath = path;
    notifyListeners();
  }

  /// Returns the next run to microphone input.
  void useMicrophone() {
    if (_wavPath == null) return;
    _wavPath = null;
    notifyListeners();
  }

  /// Runs the existing synthetic-noise device benchmark in the ASR isolate.
  Future<void> runDeviceTest() async {
    final bundle = _bundle;
    if (bundle == null || _isBenchmarking) return;
    _isBenchmarking = true;
    _error = null;
    notifyListeners();
    try {
      _benchmarkResult = await _repository.benchmark(bundle);
    } on Object catch (caught) {
      _error = caught;
    } finally {
      _isBenchmarking = false;
      notifyListeners();
    }
  }

  /// Shares the text-free event timing journal.
  Future<void> shareLog() => _repository.shareLog(measurementJson);

  /// Records the first frame containing [pageNumber].
  void markPageRendered(int pageNumber) {
    if (!_renderedPages.add(pageNumber)) return;
    _measurementLog?.addPageRendered(
      pageNumber,
      _pageRenderClock.elapsedMilliseconds,
    );
  }

  void _onEvent(SessionEvent event) {
    _measurementLog?.addSessionEvent(event);
    switch (event) {
      case PositionUpdate():
        for (final entry in _wordStates.entries.toList()) {
          if (entry.value == MushafWordState.current) {
            _wordStates[entry.key] = MushafWordState.hidden;
          }
        }
        _wordStates[event.word] = MushafWordState.current;
      case WordRevealed():
        _wordStates[event.word] = event.reason == RevealReason.hint
            ? MushafWordState.revealedByHint
            : MushafWordState.correct;
        final bundle = _bundle;
        if (bundle != null &&
            bundle.sessionWords.every(
              (word) =>
                  _wordStates[word] != MushafWordState.hidden &&
                  _wordStates[word] != MushafWordState.current,
            )) {
          _state = ReadingPrototypeState.finished;
        }
      case CheckEvent():
        final state = switch (event.state) {
          CheckState.preliminary => MushafWordState.possibleError,
          CheckState.confirmed => MushafWordState.error,
          CheckState.corrected => MushafWordState.corrected,
          CheckState.unverified => MushafWordState.notHeard,
          CheckState.disputed => MushafWordState.possibleError,
        };
        for (final word in event.words) {
          _wordStates[word] = state;
        }
      case PositionLost() || SignalQuality():
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_events?.cancel());
    unawaited(_session?.dispose());
    super.dispose();
  }
}
