import 'dart:async';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:session/session.dart';
import 'package:sudur/config/prototype_real_session.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';
import 'package:sudur/data/repositories/reading_repository.dart';
import 'package:sudur/data/services/device_service.dart';
import 'package:sudur/data/services/prototype_session.dart';

// The class names keep the view model easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor
// ignore_for_file: prefer_initializing_formals

/// States of the reading screen (docs/tz 13.3, 10.6).
enum ReadState {
  /// Preparing the passage and the session.
  preparing,

  /// Ready: choose a mode and start.
  ready,

  /// The session is starting.
  starting,

  /// Listening; words appear.
  listening,

  /// Paused.
  paused,

  /// «Закончить» pressed: waiting for the result and writing it.
  finishing,

  /// The result is written; the screen shows «Разбор» (13.4).
  finished,

  /// Something prevents reading (see [ReadViewModel.error]).
  error,
}

/// Why reading with voice is not possible (docs/tz 13.3).
enum ReadError {
  /// No microphone access.
  micDenied,

  /// The model is not downloaded.
  modelMissing,

  /// The phone cannot recognize in time.
  deviceTooSlow,

  /// No network for the text.
  network,

  /// Anything else.
  other,
}

/// Reading modes (docs/tz ЭЧ-01).
enum ReadMode {
  /// Text visible, the current word is highlighted.
  supported,

  /// Text hidden, words appear on their places.
  recall,

  /// Text hidden, nothing appears until «Закончить».
  test,
}

/// Filter of the event list in «Разбор» (РБ-01).
enum ReviewFilter {
  /// Every event.
  all,

  /// Confirmed mistakes.
  errors,

  /// Mistakes the reader corrected.
  corrections,

  /// Places that could not be checked.
  unverified,
}

/// Summary of a read passage (РБ-05).
final class ReviewSummary {
  /// Creates the summary.
  const ReviewSummary({
    required this.independent,
    required this.withHints,
    required this.errors,
    required this.unverified,
  });

  /// Words read without help.
  final int independent;

  /// Words opened by a hint.
  final int withHints;

  /// Words with a confirmed mistake.
  final int errors;

  /// Words that could not be checked.
  final int unverified;
}

/// Sound indicator dot (docs/tz 13.3).
enum SoundIndicator {
  /// Green: speech is heard.
  hearing,

  /// Grey: silence.
  silence,

  /// Yellow: too quiet, noisy or clipping.
  poor,
}

/// State and commands of the reading screen (docs/tz 13.3, 2.4).
final class ReadViewModel extends ChangeNotifier {
  /// Creates the view model.
  ReadViewModel({
    required ReadingRepository reading,
    required AppUserRepository user,
    required PrototypeReadingSessionFactory sessionFactory,
    required DeviceService device,
    DateTime Function()? now,
  }) : _reading = reading,
       _user = user,
       _sessionFactory = sessionFactory,
       _device = device,
       _now = now ?? DateTime.now;

  final ReadingRepository _reading;
  final AppUserRepository _user;
  final PrototypeReadingSessionFactory _sessionFactory;
  final DeviceService _device;
  final DateTime Function() _now;
  var _screenOn = false;

  PrototypeReadingSession? _session;
  StreamSubscription<SessionEvent>? _events;
  StreamSubscription<Exception>? _failures;
  Completer<SessionFinished>? _finished;
  Timer? _strictTimer;
  DateTime? _startedAt;
  String? _stepId;
  var _disposed = false;

  /// Current state.
  ReadState get state => _state;
  ReadState _state = ReadState.preparing;

  /// Why reading is not possible, in [ReadState.error].
  ReadError? get error => _error;
  ReadError? _error;

  /// The prepared passage.
  ReadingPassage? get passage => _passage;
  ReadingPassage? _passage;

  /// Chosen mode; changes only before the start.
  ReadMode get mode => _mode;
  ReadMode _mode = ReadMode.recall;

  /// Strict behavior (ЭЧ-05); changes only before the start.
  bool get strict => _strict;
  var _strict = false;

  /// Whether the first word of the passage stays visible (ЭЧ-13).
  bool get showFirstWord => _showFirstWord;
  var _showFirstWord = true;

  /// Model download progress, 0–1, while downloading.
  double? get downloadProgress => _downloadProgress;
  double? _downloadProgress;

  /// Sound indicator.
  SoundIndicator get sound => _sound;
  SoundIndicator _sound = SoundIndicator.silence;

  /// A hidden word read several times without opening (ЭЧ-12): the screen
  /// offers «Открыть без штрафа» over it.
  WordKey? get stuckWord => _stuckWord;
  WordKey? _stuckWord;

  /// Strict mode after a mistake: the word to read again.
  WordKey? get strictWord => _strictWord;
  WordKey? _strictWord;

  /// Strict mode: the reader is stuck, offer a hint (ЭЧ-05).
  bool get offerHint => _offerHint;
  var _offerHint = false;

  /// The result written for the passage, after [ReadState.finished].
  ReadingResult? get result => _result;
  ReadingResult? _result;
  RecordedReading? _recorded;

  /// Counts of the summary (РБ-05).
  ReviewSummary get summary {
    final words = _result?.words ?? const <SessionWordResult>[];
    var independent = 0;
    var hinted = 0;
    var errors = 0;
    var unverified = 0;
    for (final word in words) {
      if (_unlocked.contains(word.wordKey)) {
        unverified++;
        continue;
      }
      switch (word.outcome) {
        case SessionWordOutcome.read || SessionWordOutcome.corrected:
          independent++;
        case SessionWordOutcome.readWithHint:
          hinted++;
        case SessionWordOutcome.error:
          errors++;
        case SessionWordOutcome.unverified || SessionWordOutcome.notRead:
          unverified++;
      }
    }
    return ReviewSummary(
      independent: independent,
      withHints: hinted,
      errors: errors,
      unverified: unverified,
    );
  }

  /// No confirmed mistakes: «Прочитано чисто» (13.4).
  bool get clean => !_checks.values.any(
    (c) => _isMistake(c.kind) && c.state == CheckState.confirmed,
  );

  /// Filter of the event list.
  ReviewFilter get reviewFilter => _reviewFilter;
  ReviewFilter _reviewFilter = ReviewFilter.all;

  /// Changes the filter.
  void setReviewFilter(ReviewFilter value) {
    _reviewFilter = value;
    notifyListeners();
  }

  /// Events of the passage for the list, in order, filtered.
  List<CheckEvent> get reviewChecks => [
    for (final check in _checks.values)
      if (switch (_reviewFilter) {
        ReviewFilter.all => true,
        ReviewFilter.errors => check.state == CheckState.confirmed,
        ReviewFilter.corrections => check.state == CheckState.corrected,
        ReviewFilter.unverified => check.state == CheckState.unverified,
      })
        check,
  ];

  /// «Не согласен» (РБ-03): the event becomes disputed, its plan unit needs a
  /// new check.
  Future<void> dispute(String eventId) async {
    final stored = _recorded?.eventIds[eventId];
    final check = _checks[eventId];
    if (stored == null || check == null) return;
    final done = await _user.disputeCheck(stored, unitId: _recorded?.unitId);
    if (done case Error()) return;
    _checks[eventId] = _withState(check, CheckState.disputed);
    _markCheck(check.words, CheckState.disputed);
    notifyListeners();
  }

  /// Visual state of every word of the passage.
  Map<WordKey, MushafWordState> get wordStates {
    final states = Map<WordKey, MushafWordState>.of(_wordStates);
    final current = _current;
    if (current != null &&
        (states[current] == MushafWordState.hidden ||
            states[current] == MushafWordState.normal)) {
      states[current] = MushafWordState.current;
    }
    return Map.unmodifiable(states);
  }

  final Map<WordKey, MushafWordState> _wordStates = {};
  WordKey? _current;
  final Map<String, CheckEvent> _checks = {};
  final Map<HintKind, int> _hints = {};
  final Set<WordKey> _unlocked = {};
  var _hintStep = 0;
  WordKey? _stuckCandidate;
  var _stuckTries = 0;
  var _strictFails = 0;

  /// Prepares [from]–[to]; [stepId] is the step of “Today” being read.
  Future<void> open({
    required WordKey from,
    required WordKey to,
    String? stepId,
  }) async {
    _stepId = stepId;
    _state = ReadState.preparing;
    _error = null;
    notifyListeners();
    // Defaults from the settings (13.14): strict behavior, first word.
    if (await _user.loadProfile() case Ok(value: final profile?)) {
      _strict = profile.strictBehavior;
      _showFirstWord = profile.showFirstWord;
    }
    final prepared = await _reading.prepare(from: from, to: to);
    if (_disposed) return;
    switch (prepared) {
      case Ok(:final value):
        _passage = value;
        if (value.session == null) {
          _fail(ReadError.modelMissing);
          return;
        }
        _resetWords();
        _state = ReadState.ready;
      case Error(:final error):
        _fail(_errorOf(error));
        return;
    }
    notifyListeners();
  }

  /// Downloads the model after `modelMissing`, then prepares again.
  Future<void> downloadModel() async {
    final passage = _passage;
    if (passage == null || _error != ReadError.modelMissing) return;
    _downloadProgress = 0;
    notifyListeners();
    final loaded = await _reading.downloadModel(
      onProgress: (progress) {
        _downloadProgress = progress.fraction;
        notifyListeners();
      },
    );
    _downloadProgress = null;
    if (loaded case Error(:final error)) {
      _fail(_errorOf(error));
      return;
    }
    await open(from: passage.from, to: passage.to, stepId: _stepId);
  }

  /// Chooses the mode before the start.
  void setMode(ReadMode value) {
    if (_state != ReadState.ready || value == _mode) return;
    _mode = value;
    _resetWords();
    notifyListeners();
  }

  /// Chooses strict behavior before the start.
  void setStrict({required bool value}) {
    if (_state != ReadState.ready) return;
    _strict = value;
    notifyListeners();
  }

  /// Shows or hides the first word before the start (ЭЧ-13).
  void setShowFirstWord({required bool value}) {
    if (_state != ReadState.ready) return;
    _showFirstWord = value;
    _resetWords();
    notifyListeners();
  }

  /// Starts listening.
  Future<void> start() async {
    final passage = _passage;
    final configuration = passage?.session;
    if (_state != ReadState.ready || passage == null || configuration == null) {
      return;
    }
    _state = ReadState.starting;
    notifyListeners();
    final session = _sessionFactory.create(configuration);
    _session = session;
    _events = session.events.listen(_onEvent);
    _failures = session.failures.listen((e) => _fail(_errorOf(e)));
    try {
      await session.configureInput(const PrototypeMicrophoneInput());
    } on Exception catch (e) {
      _fail(_errorOf(e));
      return;
    }
    _startedAt = _now();
    final started = await session.execute(
      StartSession(
        fromWordKey: passage.from,
        toWordKey: passage.to,
        mode: switch (_mode) {
          ReadMode.supported => SessionMode.supported,
          ReadMode.recall => SessionMode.recall,
          ReadMode.test => SessionMode.test,
        },
        behavior: _strict ? SessionBehavior.strict : SessionBehavior.gentle,
      ),
    );
    if (started case Error(:final error)) {
      _fail(_errorOf(error));
      return;
    }
    if (_state == ReadState.starting) _state = ReadState.listening;
    _keepScreenOn(on: true);
    notifyListeners();
  }

  /// «Открыть настройки» after micDenied (13.3).
  Future<void> openSettings() => _device.openAppSettings();

  /// ЭЧ-09: the screen stays on only while reading.
  void _keepScreenOn({required bool on}) {
    if (on == _screenOn) return;
    _screenOn = on;
    unawaited(_device.keepScreenOn(on: on));
  }

  /// Pauses listening.
  Future<void> pause() async {
    if (_state != ReadState.listening) return;
    if (await _session?.execute(const Pause()) case Ok()) {
      _state = ReadState.paused;
      notifyListeners();
    }
  }

  /// Resumes listening.
  Future<void> resume() async {
    if (_state != ReadState.paused) return;
    if (await _session?.execute(const Resume()) case Ok()) {
      _state = ReadState.listening;
      notifyListeners();
    }
  }

  /// Next step of the hint ladder (ЭЧ-04): first letter → word → start of
  /// the next ayah → whole ayah; the ladder starts again after a word opens.
  Future<void> hint() async {
    if (_state != ReadState.listening) return;
    final kind =
        HintKind.values[_hintStep.clamp(0, HintKind.values.length - 1)];
    if (await _session?.execute(RequestHint(kind: kind)) case Ok()) {
      _hints.update(kind, (n) => n + 1, ifAbsent: () => 1);
      _hintStep++;
      _offerHint = false;
      notifyListeners();
    }
  }

  /// «Открыть без штрафа» (ЭЧ-12): opens [stuckWord] here; it counts as
  /// “could not check”, not as a hint or an error.
  void unlockStuckWord() {
    final word = _stuckWord;
    if (word == null) return;
    _unlocked.add(word);
    _wordStates[word] = MushafWordState.notHeard;
    _stuckWord = null;
    _stuckCandidate = null;
    _stuckTries = 0;
    notifyListeners();
  }

  /// «Закончить»: stops, waits for the result and writes it into the plan.
  Future<void> finish() async {
    if (_state != ReadState.listening && _state != ReadState.paused) return;
    _state = ReadState.finishing;
    notifyListeners();
    final finished = _finished ??= Completer<SessionFinished>();
    await _session?.execute(const Stop());
    final event = await finished.future;
    final passage = _passage;
    if (passage == null || _disposed) return;
    final result = ReadingResult(
      stepId: _stepId,
      from: passage.from,
      to: passage.to,
      mode: switch (_mode) {
        ReadMode.supported => SessionMode.supported,
        ReadMode.recall => SessionMode.recall,
        ReadMode.test => SessionMode.test,
      },
      behavior: _strict ? SessionBehavior.strict : SessionBehavior.gentle,
      startedAt: _startedAt ?? _now(),
      duration: _now().difference(_startedAt ?? _now()),
      words: event.words,
      hints: _hints,
      checks: _checks.values.toList(),
      unlocked: _unlocked,
    );
    _keepScreenOn(on: false);
    final written = await _user.recordReading(result);
    switch (written) {
      case Ok(:final value):
        _recorded = value;
      case Error(:final error):
        _fail(_errorOf(error));
        return;
    }
    // «Проверяю себя» showed nothing while reading: the marks appear now.
    for (final check in _checks.values) {
      if (_isMistake(check.kind)) _markCheck(check.words, check.state);
    }
    _result = result;
    _state = ReadState.finished;
    notifyListeners();
  }

  void _onEvent(SessionEvent event) {
    switch (event) {
      case SessionStarted():
        break;
      case PositionUpdate(:final word):
        _current = word;
        _trackStuck(word);
      case WordRevealed(:final word, :final reason):
        if (_mode != ReadMode.test) {
          _wordStates[word] = reason == RevealReason.hint
              ? MushafWordState.revealedByHint
              : MushafWordState.correct;
        }
        _hintStep = 0;
        if (word == _stuckCandidate) {
          _stuckCandidate = null;
          _stuckTries = 0;
          _stuckWord = null;
        }
        if (word == _strictWord) _clearStrict();
      case HintGiven(:final wordKey):
        _wordStates[wordKey] = MushafWordState.revealedByHint;
        if (wordKey == _strictWord) _clearStrict();
      case CheckEvent():
        _checks[event.eventId] = event;
        if (_mode != ReadMode.test) _markCheck(event.words, event.state);
        if (_strict && _isMistake(event.kind)) _onStrictMistake(event);
      case CheckStateChanged(:final eventId, :final to):
        final check = _checks[eventId];
        if (check != null) {
          _checks[eventId] = _withState(check, to);
          if (_mode != ReadMode.test) _markCheck(check.words, to);
        }
      case PositionLost():
        _current = null;
      case SignalQuality(:final level):
        _sound = level == SignalQualityLevel.ok
            ? SoundIndicator.hearing
            : SoundIndicator.poor;
      case SessionFinished():
        _current = null;
        for (final word in event.words) {
          _wordStates[word.wordKey] = _unlocked.contains(word.wordKey)
              ? MushafWordState.notHeard
              : _stateOfOutcome(word.outcome);
        }
        (_finished ??= Completer<SessionFinished>()).complete(event);
    }
    notifyListeners();
  }

  /// ЭЧ-12: position stays on the same hidden word while it does not open.
  void _trackStuck(WordKey word) {
    final limits = _passage?.limits;
    final hidden = _wordStates[word] == MushafWordState.hidden;
    if (limits == null || !hidden || _sound == SoundIndicator.poor) return;
    if (word != _stuckCandidate) {
      _stuckCandidate = word;
      _stuckTries = 0;
    }
    _stuckTries++;
    if (_stuckTries >= limits.stuckWordTries) _stuckWord = word;
  }

  void _onStrictMistake(CheckEvent event) {
    final limits = _passage?.limits;
    if (limits == null || event.words.isEmpty) return;
    final word = event.words.first;
    if (word != _strictWord) {
      _strictWord = word;
      _strictFails = 0;
      _strictTimer?.cancel();
      _strictTimer = Timer(Duration(milliseconds: limits.strictMaxWaitMs), () {
        _offerHint = true;
        if (!_disposed) notifyListeners();
      });
    }
    _strictFails++;
    if (_strictFails >= limits.strictMaxFails) _offerHint = true;
  }

  void _clearStrict() {
    _strictTimer?.cancel();
    _strictWord = null;
    _strictFails = 0;
    _offerHint = false;
  }

  void _markCheck(List<WordKey> words, CheckState state) {
    final visual = switch (state) {
      CheckState.preliminary ||
      CheckState.disputed => MushafWordState.possibleError,
      CheckState.confirmed => MushafWordState.error,
      CheckState.corrected => MushafWordState.corrected,
      CheckState.unverified => MushafWordState.notHeard,
    };
    for (final word in words) {
      _wordStates[word] = visual;
    }
  }

  void _resetWords() {
    final passage = _passage;
    if (passage == null) return;
    _wordStates.clear();
    final words = passage.words;
    for (final (i, word) in words.indexed) {
      final visible = _mode == ReadMode.supported || (i == 0 && _showFirstWord);
      _wordStates[word] = visible
          ? MushafWordState.normal
          : MushafWordState.hidden;
    }
  }

  void _fail(ReadError reason) {
    _keepScreenOn(on: false);
    _error = reason;
    _state = ReadState.error;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _keepScreenOn(on: false);
    _disposed = true;
    _strictTimer?.cancel();
    unawaited(_events?.cancel());
    unawaited(_failures?.cancel());
    unawaited(_session?.dispose());
    super.dispose();
  }
}

bool _isMistake(CheckKind kind) =>
    kind != CheckKind.repetition && kind != CheckKind.hesitation;

CheckEvent _withState(CheckEvent check, CheckState state) => CheckEvent(
  sessionId: check.sessionId,
  atMs: check.atMs,
  eventId: check.eventId,
  kind: check.kind,
  state: state,
  words: check.words,
  expectedText: check.expectedText,
  heardText: check.heardText,
  jumpTo: check.jumpTo,
  audioStartMs: check.audioStartMs,
  audioEndMs: check.audioEndMs,
  versions: check.versions,
);

MushafWordState _stateOfOutcome(SessionWordOutcome outcome) =>
    switch (outcome) {
      SessionWordOutcome.read => MushafWordState.correct,
      SessionWordOutcome.readWithHint => MushafWordState.revealedByHint,
      SessionWordOutcome.error => MushafWordState.error,
      SessionWordOutcome.corrected => MushafWordState.corrected,
      SessionWordOutcome.unverified => MushafWordState.notHeard,
      SessionWordOutcome.notRead => MushafWordState.hidden,
    };

ReadError _errorOf(Object error) {
  final code = switch (error) {
    PrototypeRealSessionException(:final code) => code,
    SessionIsolateFailure(:final code) => code,
    ReadingSessionException(:final code) => code,
    SherpaRecognizerException(:final code) => code,
    _ => '',
  };
  if (code.contains('micDenied')) return ReadError.micDenied;
  if (code.contains('deviceTooSlow')) return ReadError.deviceTooSlow;
  if (code.startsWith('model') || code.contains('ModelPackage')) {
    return ReadError.modelMissing;
  }
  if (error.toString().contains('SocketException') ||
      error.toString().contains('HttpException')) {
    return ReadError.network;
  }
  return ReadError.other;
}
