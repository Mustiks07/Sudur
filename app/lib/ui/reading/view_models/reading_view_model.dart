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

  /// The model/session worker is starting; duplicate starts are blocked.
  starting,

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
  new(
    this._repository,
    this._sessionFactory, {
    int Function()? monotonicMilliseconds,
  }) : _monotonicMilliseconds =
           monotonicMilliseconds ?? _createMonotonicMilliseconds();

  final PrototypeRepository _repository;
  final PrototypeReadingSessionFactory _sessionFactory;
  final int Function() _monotonicMilliseconds;
  final Set<int> _renderedPages = <int>{};
  final Map<int, int> _pageRenderStartedAt = <int, int>{};
  final Map<String, List<WordKey>> _checkWords = <String, List<WordKey>>{};
  PrototypeReadingSession? _session;
  StreamSubscription<SessionEvent>? _events;
  StreamSubscription<Exception>? _failures;
  PrototypeBundle? _bundle;
  PrototypeMeasurementLog? _measurementLog;
  String? _wavPath;
  var _activeInputUsesWav = false;
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
  Map<WordKey, MushafWordState> get wordStates {
    final states = Map<WordKey, MushafWordState>.of(_wordStates);
    final currentWord = _currentWord;
    if (currentWord != null && states[currentWord] == MushafWordState.hidden) {
      states[currentWord] = MushafWordState.current;
    }
    return Map.unmodifiable(states);
  }

  final Map<WordKey, MushafWordState> _wordStates =
      <WordKey, MushafWordState>{};
  WordKey? _currentWord;

  /// Selected WAV file name, without exposing its full path in the UI.
  String? get selectedWavName {
    return _wavPath?.split(RegExp(r'[/\\]')).last;
  }

  /// Whether pausing is valid for the currently running input.
  bool get canPause =>
      _state == ReadingPrototypeState.running && !_activeInputUsesWav;

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
      _pageRenderStartedAt.clear();
      _checkWords.clear();
      _currentWord = null;
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
    final isRestart = _state == ReadingPrototypeState.finished;
    _state = ReadingPrototypeState.starting;
    _error = null;
    notifyListeners();
    if (isRestart) {
      await _replaceSession(bundle);
      for (final word in _wordStates.keys) {
        _wordStates[word] = MushafWordState.hidden;
      }
      _currentWord = null;
      _checkWords.clear();
    }
    final session = _session;
    if (session == null) {
      _state = ReadingPrototypeState.error;
      notifyListeners();
      return;
    }
    final wavPath = _wavPath;
    _activeInputUsesWav = wavPath != null;
    _measurementLog?.start(usesWav: wavPath != null);
    try {
      await session.configureInput(
        wavPath == null
            ? const PrototypeMicrophoneInput()
            : PrototypeWavInput(wavPath),
      );
    } on Exception catch (error) {
      _handleSessionError(error);
      return;
    }
    final started = await _execute(
      StartSession(
        fromWordKey: bundle.sessionWords.first,
        toWordKey: bundle.sessionWords.last,
        mode: SessionMode.recall,
        behavior: SessionBehavior.gentle,
      ),
    );
    if (!started) return;
    _state = ReadingPrototypeState.running;
    notifyListeners();
  }

  Future<void> _replaceSession(PrototypeBundle bundle) async {
    await _events?.cancel();
    await _failures?.cancel();
    await _session?.dispose();
    final session = _sessionFactory.create(bundle.sessionConfiguration);
    _session = session;
    _events = session.events.listen(_onEvent);
    _failures = session.failures.listen(_handleSessionError);
  }

  /// Pauses the current session.
  Future<void> pause() async {
    if (!canPause) return;
    if (!await _execute(const Pause())) return;
    _state = ReadingPrototypeState.paused;
    notifyListeners();
  }

  /// Resumes a paused session.
  Future<void> resume() async {
    if (_state != ReadingPrototypeState.paused) return;
    if (!await _execute(const Resume())) return;
    _state = ReadingPrototypeState.running;
    notifyListeners();
  }

  /// Stops without treating unread words as errors.
  Future<void> stop() async {
    if (_state != ReadingPrototypeState.running &&
        _state != ReadingPrototypeState.paused) {
      return;
    }
    await _execute(const Stop());
  }

  /// Requests a whole-word hint from the session adapter.
  Future<void> requestHint() async {
    await _execute(const RequestHint(kind: HintKind.word));
  }

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

  /// Starts first-frame timing when the UI requests [pageNumber].
  void beginPageRender(int pageNumber) {
    if (_renderedPages.contains(pageNumber) ||
        _pageRenderStartedAt.containsKey(pageNumber)) {
      return;
    }
    _pageRenderStartedAt[pageNumber] = _monotonicMilliseconds();
  }

  /// Records the first frame containing [pageNumber].
  void markPageRendered(int pageNumber) {
    if (_renderedPages.contains(pageNumber)) return;
    final startedAt = _pageRenderStartedAt.remove(pageNumber);
    if (startedAt == null) return;
    _renderedPages.add(pageNumber);
    final elapsed = _monotonicMilliseconds() - startedAt;
    _measurementLog?.addPageRendered(pageNumber, elapsed < 0 ? 0 : elapsed);
  }

  Future<bool> _execute(SessionCommand command) async {
    final session = _session;
    if (session == null) return false;
    final result = await session.execute(command);
    return switch (result) {
      Ok<void>() => true,
      Error<void>(:final error) => _handleSessionError(error),
    };
  }

  bool _handleSessionError(Exception error) {
    _error = error;
    _state = ReadingPrototypeState.error;
    notifyListeners();
    return false;
  }

  void _onEvent(SessionEvent event) {
    _measurementLog?.addSessionEvent(event);
    switch (event) {
      case PositionUpdate():
        _currentWord = event.word;
      case WordRevealed():
        _wordStates[event.word] = event.reason == RevealReason.hint
            ? MushafWordState.revealedByHint
            : MushafWordState.correct;
      case CheckEvent():
        _checkWords[event.eventId] = List<WordKey>.unmodifiable(event.words);
        final state = _wordStateForCheck(event.state);
        for (final word in event.words) {
          _wordStates[word] = state;
        }
      case PositionLost():
        _currentWord = null;
      case SignalQuality() || SessionStarted():
        break;
      case HintGiven():
        _wordStates[event.wordKey] = MushafWordState.revealedByHint;
      case CheckStateChanged():
        final words = _checkWords[event.eventId] ?? const <WordKey>[];
        final state = _wordStateForCheck(event.to);
        for (final word in words) {
          _wordStates[word] = state;
        }
      case SessionFinished():
        _currentWord = null;
        for (final result in event.words) {
          _wordStates[result.wordKey] = _wordStateForOutcome(result.outcome);
        }
        _state = ReadingPrototypeState.finished;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_events?.cancel());
    unawaited(_failures?.cancel());
    unawaited(_session?.dispose());
    super.dispose();
  }
}

MushafWordState _wordStateForCheck(CheckState state) => switch (state) {
  CheckState.preliminary => MushafWordState.possibleError,
  CheckState.confirmed => MushafWordState.error,
  CheckState.corrected => MushafWordState.corrected,
  CheckState.unverified => MushafWordState.notHeard,
  CheckState.disputed => MushafWordState.possibleError,
};

MushafWordState _wordStateForOutcome(SessionWordOutcome outcome) =>
    switch (outcome) {
      SessionWordOutcome.read => MushafWordState.correct,
      SessionWordOutcome.readWithHint => MushafWordState.revealedByHint,
      SessionWordOutcome.error => MushafWordState.error,
      SessionWordOutcome.corrected => MushafWordState.corrected,
      SessionWordOutcome.unverified => MushafWordState.notHeard,
      SessionWordOutcome.notRead => MushafWordState.hidden,
    };

int Function() _createMonotonicMilliseconds() {
  final stopwatch = Stopwatch()..start();
  return () => stopwatch.elapsedMilliseconds;
}
