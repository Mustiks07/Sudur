import 'dart:async';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:follow/follow.dart';
import 'package:quran_text/quran_text.dart';
import 'package:session/src/session_checkpoint.dart';
import 'package:session/src/session_state.dart';

/// Creates a unique id for a new reading session.
typedef SessionIdFactory = String Function();

/// Coordinates audio, recognition, following and checking (docs/tz 10.6).
final class ReadingSession {
  /// Creates an idle session.
  ReadingSession({
    required SpeechRecognizer recognizer,
    required SessionAudioSource audioSource,
    required QuranText text,
    required Normalizer normalizer,
    required ReadingVersions versions,
    required String modelDirectory,
    required SessionIdFactory createSessionId,
    FollowParams followParams = FollowParams.defaults,
    CheckParams checkParams = CheckParams.defaults,
    SessionCheckpointStore? checkpointStore,
    Duration checkpointInterval = const Duration(seconds: 30),
    Duration finishingTimeout = const Duration(seconds: 3),
    double maximumDecodeRatio = 3,
  })  : _recognizer = recognizer,
        _audioSource = audioSource,
        _text = text,
        _normalizer = normalizer,
        _configuredVersions = versions,
        _modelDirectory = modelDirectory,
        _createSessionId = createSessionId,
        _followParams = followParams,
        _checkParams = checkParams,
        _checkpointStore = checkpointStore,
        _checkpointInterval = checkpointInterval,
        _finishingTimeout = finishingTimeout,
        _maximumDecodeRatio = maximumDecodeRatio;

  final SpeechRecognizer _recognizer;
  final SessionAudioSource _audioSource;
  final QuranText _text;
  final Normalizer _normalizer;
  final ReadingVersions _configuredVersions;
  final String _modelDirectory;
  final SessionIdFactory _createSessionId;
  final FollowParams _followParams;
  final CheckParams _checkParams;
  final SessionCheckpointStore? _checkpointStore;
  final Duration _checkpointInterval;
  final Duration _finishingTimeout;
  final double _maximumDecodeRatio;

  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast(sync: true);
  final StreamController<ReadingSessionState> _states =
      StreamController<ReadingSessionState>.broadcast(sync: true);

  ReadingSessionState _state = ReadingSessionState.idle;
  StreamSubscription<Result<SessionAudioEvent>>? _audioSubscription;
  StreamSubscription<RecognitionResult>? _recognitionSubscription;
  Timer? _checkpointTimer;
  Follower? _follower;
  Checker? _checker;
  StartSession? _start;
  String? _sessionId;
  List<Word> _passage = const [];
  final Set<WordKey> _revealed = <WordKey>{};
  final Set<WordKey> _hinted = <WordKey>{};
  final Map<String, CheckEvent> _checks = <String, CheckEvent>{};
  final Set<int> _closedSegments = <int>{};
  final Map<int, Completer<void>> _finalWaiters = <int, Completer<void>>{};
  int? _openSegmentId;
  WordKey? _lastPosition;
  var _atMs = 0;
  var _audioWasSuitable = true;
  var _disposed = false;

  /// Events consumed by the reading screen and persistence layer.
  Stream<SessionEvent> get events => _events.stream;

  /// Lifecycle state changes, excluding the initial [state] value.
  Stream<ReadingSessionState> get states => _states.stream;

  /// Current lifecycle state.
  ReadingSessionState get state => _state;

  /// Executes one screen command.
  Future<Result<void>> execute(SessionCommand command) {
    if (_disposed) {
      return Future<Result<void>>.value(
        _failure('disposed', 'The reading session is disposed.'),
      );
    }
    return switch (command) {
      StartSession() => _startSession(command),
      Pause() => _pause(),
      Resume() => _resume(),
      Stop() => _stop(),
      RequestHint() => _hint(command.kind),
      DisputeEvent() => _dispute(command.eventId),
    };
  }

  Future<Result<void>> _startSession(StartSession command) async {
    if (_state.phase != ReadingSessionPhase.idle) {
      return _invalidState('start');
    }
    List<Word> passage;
    try {
      passage = _text.range(command.fromWordKey, command.toWordKey);
    } on Object {
      return _failure('invalidRange', 'The requested word range is invalid.');
    }
    _setState(const ReadingSessionState(ReadingSessionPhase.preparing));
    final loaded = await _recognizer.load(_modelDirectory);
    if (loaded case Error<void>(:final error)) {
      _setError(ReadingSessionError.modelMissing);
      return Result<void>.error(error);
    }

    final sessionId = _createSessionId();
    final info = _recognizer.info;
    final versions = ReadingVersions(
      modelId: info.modelId,
      modelVersion: info.modelVersion,
      rulesVersion: _configuredVersions.rulesVersion,
      textVersion: _configuredVersions.textVersion,
    );
    final follower = Follower(
      text: _text,
      normalizer: _normalizer,
      from: command.fromWordKey,
      to: command.toWordKey,
      params: _followParams,
    );
    final checker = Checker(
      text: _text,
      normalizer: _normalizer.id,
      from: command.fromWordKey,
      to: command.toWordKey,
      params: _checkParams,
      sessionId: sessionId,
      versions: versions,
      strict: command.behavior == SessionBehavior.strict,
    );

    _start = command;
    _sessionId = sessionId;
    _passage = List<Word>.unmodifiable(passage);
    _follower = follower;
    _checker = checker;
    _audioSubscription = _audioSource.events.listen(_onAudioResult);
    _recognitionSubscription = _recognizer.results.listen(_onRecognition);

    final started = await _audioSource.start(sessionId);
    if (started case Error<void>(:final error)) {
      await _cancelSubscriptions();
      _setError(ReadingSessionError.micDenied);
      return Result<void>.error(error);
    }
    _emit(
      SessionStarted(
        sessionId: sessionId,
        atMs: 0,
        fromWordKey: command.fromWordKey,
        toWordKey: command.toWordKey,
        mode: command.mode,
        versions: versions,
      ),
    );
    _setState(const ReadingSessionState(ReadingSessionPhase.ready));
    _checkpointTimer = Timer.periodic(
      _checkpointInterval,
      (_) => unawaited(_saveCheckpoint()),
    );
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _pause() async {
    if (_state.phase != ReadingSessionPhase.listening &&
        _state.phase != ReadingSessionPhase.ready) {
      return _invalidState('pause');
    }
    final result = await _audioSource.pause();
    if (result case Error<void>()) return result;
    _setState(const ReadingSessionState(ReadingSessionPhase.paused));
    await _saveCheckpoint();
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _resume() async {
    if (_state.phase != ReadingSessionPhase.paused) {
      return _invalidState('resume');
    }
    final result = await _audioSource.resume();
    if (result case Error<void>()) return result;
    _setState(const ReadingSessionState(ReadingSessionPhase.listening));
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _stop() async {
    const stoppable = <ReadingSessionPhase>{
      ReadingSessionPhase.ready,
      ReadingSessionPhase.listening,
      ReadingSessionPhase.paused,
      ReadingSessionPhase.error,
    };
    if (!stoppable.contains(_state.phase) || _follower == null) {
      return _invalidState('stop');
    }
    _setState(const ReadingSessionState(ReadingSessionPhase.finishing));
    _checkpointTimer?.cancel();
    final segmentId = _openSegmentId;
    final stopped = await _audioSource.stop();
    if (stopped case Error<void>()) return stopped;
    if (segmentId != null) {
      _closeSegment(segmentId);
      final waiter = _finalWaiters[segmentId];
      if (waiter != null && !waiter.isCompleted) {
        try {
          await waiter.future.timeout(_finishingTimeout);
        } on TimeoutException {
          _audioWasSuitable = false;
          _processCheck(
            _checker!.markUnreliable(
              UnreliableSpan(
                startMs: _atMs,
                endMs: _atMs,
                reason: UnreliableReason.deviceTooSlow,
              ),
            ),
            reason: 'finalRecognitionTimedOut',
          );
        }
      }
    }

    final follow = _follower!.finish(
      sessionId: _sessionId!, // Set together with the follower at start.
      atMs: _atMs,
    );
    _processFollow(follow);
    _processCheck(
      _checker!.finish(_atMs),
      reason: 'sessionFinishedWithoutContext',
    );
    _emit(_buildFinished());
    _setState(const ReadingSessionState(ReadingSessionPhase.finished));
    await _saveCheckpoint();
    await _cancelSubscriptions();
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _hint(HintKind kind) async {
    if (_state.phase != ReadingSessionPhase.ready &&
        _state.phase != ReadingSessionPhase.listening &&
        _state.phase != ReadingSessionPhase.paused) {
      return _invalidState('hint');
    }
    final target = _hintTarget(kind);
    if (target == null) {
      return _failure('noHintTarget', 'There is no word to hint.');
    }
    final affected = kind == HintKind.wholeAyah
        ? _passage
            .where(
              (word) =>
                  word.key.surah == target.surah &&
                  word.key.ayah == target.ayah,
            )
            .map((word) => word.key)
        : <WordKey>[target];
    _hinted.addAll(affected);
    _emit(
      HintGiven(
        sessionId: _sessionId!, // An active phase always has a session id.
        atMs: _atMs,
        kind: kind,
        wordKey: target,
      ),
    );
    if (kind != HintKind.firstLetter) {
      for (final word in affected) {
        if (_revealed.add(word)) {
          _emit(
            WordRevealed(
              sessionId: _sessionId!,
              atMs: _atMs,
              word: word,
              reason: RevealReason.hint,
            ),
          );
        }
      }
    }
    _processCheck(
      _checker!.onHint(target, _atMs),
      reason: 'hintTaken',
    );
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _dispute(String eventId) async {
    if (_checker == null) return _invalidState('dispute');
    final result = _checker!.dispute(eventId, _atMs);
    return switch (result) {
      Ok<CheckUpdate>(:final value) => () {
          _processCheck(value, reason: 'readerDisputed');
          return const Result<void>.ok(null);
        }(),
      Error<CheckUpdate>(:final error) => Result<void>.error(error),
    };
  }

  void _onAudioResult(Result<SessionAudioEvent> result) {
    switch (result) {
      case Ok<SessionAudioEvent>(:final value):
        _onAudio(value);
      case Error<SessionAudioEvent>():
        _setError(ReadingSessionError.micDenied);
    }
  }

  void _onAudio(SessionAudioEvent event) {
    if (_state.phase == ReadingSessionPhase.finishing ||
        _state.phase == ReadingSessionPhase.finished) {
      return;
    }
    _atMs = event.atMs > _atMs ? event.atMs : _atMs;
    switch (event) {
      case SessionAudioSegmentOpened():
        _openSegmentId = event.segmentId;
        if (event.pauseBeforeMs > 0) {
          _processCheck(
            _checker!.onPause(
              SpeechPause(
                startMs: event.atMs - event.pauseBeforeMs,
                endMs: event.atMs,
              ),
            ),
            reason: 'speechPause',
          );
        }
        _beginListening();
      case SessionAudioFrame():
        _recognizer.acceptAudio(
          event.samples,
          event.sampleRateHz,
          event.startMs,
        );
        _beginListening();
      case SessionAudioSegmentClosed():
        _closeSegment(event.segmentId);
      case SignalQuality():
        _audioWasSuitable =
            _audioWasSuitable && event.level == SignalQualityLevel.ok;
        _emit(event);
        _processCheck(
          _checker!.onSignalQuality(event),
          reason: 'signalQualityChanged',
        );
      default:
        break;
    }
  }

  void _onRecognition(RecognitionResult result) {
    if (result.sessionId != _sessionId ||
        _state.phase == ReadingSessionPhase.finished) {
      return;
    }
    _atMs = result.audioEndMs > _atMs ? result.audioEndMs : _atMs;
    final audioDuration = result.audioEndMs - result.audioStartMs;
    if (audioDuration > 0 &&
        result.decodeMs > audioDuration * _maximumDecodeRatio) {
      _audioWasSuitable = false;
      _processCheck(
        _checker!.markUnreliable(
          UnreliableSpan(
            startMs: result.audioStartMs,
            endMs: result.audioEndMs,
            reason: UnreliableReason.deviceTooSlow,
          ),
        ),
        reason: 'deviceTooSlow',
      );
      _setError(ReadingSessionError.deviceTooSlow);
    }
    _processFollow(_follower!.accept(result));
    if (result.isFinal) {
      final waiter = _finalWaiters[result.segmentId];
      if (waiter != null && !waiter.isCompleted) waiter.complete();
    }
  }

  void _processFollow(FollowUpdate update) {
    for (final event in update.events) {
      if (event case PositionUpdate(:final word)) {
        _lastPosition = word;
      }
      if (event case WordRevealed(:final word)) {
        _revealed.add(word);
        if (_start?.mode == SessionMode.test) continue;
      }
      _emit(event);
    }
    _processCheck(
      _checker!.accept(path: update.path, jumps: update.jumps),
      reason: 'checkUpdated',
    );
  }

  void _processCheck(CheckUpdate update, {required String reason}) {
    for (final event in update.events) {
      final previous = _checks[event.eventId];
      _checks[event.eventId] = event;
      _emit(event);
      if (previous != null && previous.state != event.state) {
        _emit(
          CheckStateChanged(
            sessionId: event.sessionId,
            atMs: event.atMs,
            eventId: event.eventId,
            from: previous.state,
            to: event.state,
            reason: reason,
          ),
        );
      }
    }
  }

  SessionFinished _buildFinished() {
    final byWord = <WordKey, CheckState>{};
    for (final event in _checks.values) {
      for (final word in event.words) {
        final known = byWord[word];
        if (known == null ||
            _outcomePriority(event.state) > _outcomePriority(known)) {
          byWord[word] = event.state;
        }
      }
    }
    return SessionFinished(
      sessionId: _sessionId!, // A finishing session always has an id.
      atMs: _atMs,
      words: [
        for (final word in _passage)
          SessionWordResult(
            wordKey: word.key,
            outcome: _wordOutcome(word.key, byWord[word.key]),
          ),
      ],
      eventIds: List<String>.unmodifiable(_checks.keys),
      durationMs: _atMs,
      audioWasSuitable: _audioWasSuitable,
    );
  }

  SessionWordOutcome _wordOutcome(WordKey word, CheckState? check) {
    if (_hinted.contains(word)) return SessionWordOutcome.readWithHint;
    return switch (check) {
      CheckState.confirmed => SessionWordOutcome.error,
      CheckState.corrected => SessionWordOutcome.corrected,
      CheckState.unverified ||
      CheckState.disputed =>
        SessionWordOutcome.unverified,
      CheckState.preliminary => SessionWordOutcome.unverified,
      null => _revealed.contains(word)
          ? SessionWordOutcome.read
          : SessionWordOutcome.notRead,
    };
  }

  int _outcomePriority(CheckState state) => switch (state) {
        CheckState.confirmed => 4,
        CheckState.unverified || CheckState.disputed => 3,
        CheckState.corrected => 2,
        CheckState.preliminary => 1,
      };

  WordKey? _hintTarget(HintKind kind) {
    var next = 0;
    final position = _lastPosition;
    if (position != null) {
      final index = _passage.indexWhere((word) => word.key == position);
      if (index >= 0) next = index + 1;
    } else {
      while (next < _passage.length && _revealed.contains(_passage[next].key)) {
        next++;
      }
    }
    if (next >= _passage.length) return null;
    final target = _passage[next].key;
    if (kind != HintKind.nextAyahStart) return target;
    for (final word in _passage.skip(next + 1)) {
      if (word.key.surah != target.surah || word.key.ayah != target.ayah) {
        return word.key;
      }
    }
    return null;
  }

  void _closeSegment(int segmentId) {
    if (!_closedSegments.add(segmentId)) return;
    _openSegmentId = _openSegmentId == segmentId ? null : _openSegmentId;
    _finalWaiters.putIfAbsent(segmentId, Completer<void>.new);
    _recognizer.closeSegment(segmentId);
  }

  void _beginListening() {
    if (_state.phase == ReadingSessionPhase.ready) {
      _setState(const ReadingSessionState(ReadingSessionPhase.listening));
    }
  }

  Future<void> _saveCheckpoint() async {
    final store = _checkpointStore;
    final start = _start;
    final sessionId = _sessionId;
    if (store == null || start == null || sessionId == null) return;
    await store.save(
      SessionCheckpoint(
        sessionId: sessionId,
        fromWordKey: start.fromWordKey,
        toWordKey: start.toWordKey,
        mode: start.mode,
        behavior: start.behavior,
        phase: _state.phase,
        atMs: _atMs,
        lastPosition: _lastPosition,
      ),
    );
  }

  void _emit(SessionEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  void _setState(ReadingSessionState state) {
    if (_state.phase == state.phase && _state.error == state.error) return;
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  void _setError(ReadingSessionError error) {
    _setState(ReadingSessionState(ReadingSessionPhase.error, error: error));
  }

  Result<void> _invalidState(String operation) => _failure(
        'invalidState',
        'Cannot $operation while the session is ${_state.phase.name}.',
      );

  Result<void> _failure(String code, String message) =>
      Result<void>.error(ReadingSessionException(code, message));

  Future<void> _cancelSubscriptions() async {
    await _audioSubscription?.cancel();
    await _recognitionSubscription?.cancel();
    _audioSubscription = null;
    _recognitionSubscription = null;
  }

  /// Stops active resources and closes public streams.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _checkpointTimer?.cancel();
    if (_state.phase != ReadingSessionPhase.idle &&
        _state.phase != ReadingSessionPhase.finished) {
      await _audioSource.stop();
    }
    await _cancelSubscriptions();
    await _recognizer.dispose();
    await _audioSource.dispose();
    await _events.close();
    await _states.close();
  }
}
