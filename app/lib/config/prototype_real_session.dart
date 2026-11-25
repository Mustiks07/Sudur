import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:audio_capture/audio_capture.dart' as audio;
import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';
import 'package:session/session.dart';
import 'package:sudur/data/services/prototype_session.dart';

/// Creates the isolate bridge used by a production prototype session.
///
/// The seam keeps lifecycle races deterministic in tests while production uses
/// [ReadingSessionIsolate.spawn].
typedef PrototypeSessionIsolateSpawner =
    Future<Result<ReadingSessionIsolate>> Function({
      required SessionIsolateWorkerFactory factory,
      required SessionAudioSource audioSource,
      Object? configuration,
    });

Future<Result<ReadingSessionIsolate>> _spawnReadingSessionIsolate({
  required SessionIsolateWorkerFactory factory,
  required SessionAudioSource audioSource,
  Object? configuration,
}) => ReadingSessionIsolate.spawn(
  factory: factory,
  audioSource: audioSource,
  configuration: configuration,
);

/// Builds production prototype sessions.
///
/// Scripted sessions remain available to tests through their separate factory.
final class RealPrototypeReadingSessionFactory
    implements PrototypeReadingSessionFactory {
  /// Creates the production factory.
  new({this.spawner = _spawnReadingSessionIsolate});

  /// Isolate lifecycle seam used by regression tests.
  final PrototypeSessionIsolateSpawner spawner;
  var _nextSession = 1;

  @override
  PrototypeReadingSession create(PrototypeSessionConfiguration configuration) =>
      _RealPrototypeReadingSession(
        configuration,
        sessionId: 'prototype-${_nextSession++}',
        spawner: spawner,
      );
}

final class _RealPrototypeReadingSession implements PrototypeReadingSession {
  new(this._configuration, {required this.sessionId, required this._spawner});

  final PrototypeSessionConfiguration _configuration;
  final String sessionId;
  final PrototypeSessionIsolateSpawner _spawner;
  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast(sync: true);
  final StreamController<Exception> _failures =
      StreamController<Exception>.broadcast(sync: true);
  final StreamController<PrototypeSessionDiagnostic> _diagnostics =
      StreamController<PrototypeSessionDiagnostic>.broadcast(sync: true);

  PrototypeSessionInput _input = const PrototypeMicrophoneInput();
  ReadingSessionIsolate? _isolate;
  Future<Result<ReadingSessionIsolate>>? _spawnResult;
  StreamSubscription<SessionEvent>? _eventSubscription;
  StreamSubscription<SessionIsolateFailure>? _failureSubscription;
  ReceivePort? _diagnosticPort;
  StreamSubscription<Object?>? _diagnosticSubscription;
  audio.AudioCaptureService? _capture;
  final List<Timer> _snippetTimers = [];
  var _disposed = false;

  /// ЗВ-02: padding around an event's audio, from the capture parameters.
  static final int _snippetPadMs =
      const audio.AudioCaptureConfig().reviewSnippetPadMs;

  @override
  Stream<SessionEvent> get events => _events.stream;

  @override
  Stream<Exception> get failures => _failures.stream;

  @override
  Stream<PrototypeSessionDiagnostic> get diagnostics => _diagnostics.stream;

  @override
  Future<void> configureInput(PrototypeSessionInput input) async {
    if (_isolate != null || _spawnResult != null) {
      throw const PrototypeRealSessionException(
        'alreadyStarted',
        'The input cannot change after the session worker starts.',
      );
    }
    _input = input;
  }

  @override
  Future<Result<void>> execute(SessionCommand command) async {
    if (_disposed) {
      return const Result<void>.error(
        PrototypeRealSessionException(
          'disposed',
          'The prototype session is disposed.',
        ),
      );
    }
    var isolate = _isolate;
    if (isolate == null) {
      if (command is! StartSession) {
        return const Result<void>.error(
          PrototypeRealSessionException(
            'notStarted',
            'Start the session before sending this command.',
          ),
        );
      }
      final spawned = await (_spawnResult ??= _spawn());
      switch (spawned) {
        case Error<ReadingSessionIsolate>(:final error):
          return Result<void>.error(error);
        case Ok<ReadingSessionIsolate>(:final value):
          isolate = value;
      }
    }
    return await isolate.execute(command);
  }

  Future<Result<ReadingSessionIsolate>> _spawn() async {
    final diagnosticPort = ReceivePort();
    _diagnosticPort = diagnosticPort;
    _diagnosticSubscription = diagnosticPort.listen(_onDiagnosticMessage);
    late final PrototypeSessionAudioSource source;
    final capture = audio.AudioCaptureService(sessionId: sessionId);
    _capture = capture;
    source = PrototypeSessionAudioSource(
      capture: capture,
      input: _input,
      vadModelPath: _configuration.vadModelPath,
      expectedSessionId: sessionId,
      onDiagnostic: _diagnostics.add,
      onFileFinished: () {
        final isolate = _isolate;
        if (isolate != null) unawaited(isolate.execute(const Stop()));
      },
    );
    final spawned = await _spawner(
      factory: createPrototypeSessionWorker,
      audioSource: source,
      configuration: _workerConfiguration(
        _configuration,
        sessionId,
        diagnosticPort.sendPort,
      ),
    );
    if (spawned case Ok<ReadingSessionIsolate>(:final value)) {
      if (_disposed) {
        await value.dispose();
        return const Result<ReadingSessionIsolate>.error(
          PrototypeRealSessionException(
            'disposed',
            'The prototype session was disposed during startup.',
          ),
        );
      }
      _isolate = value;
      _eventSubscription = value.events.listen((event) {
        if (event is CheckEvent) _keepSnippet(event);
        _events.add(event);
      });
      _failureSubscription = value.failures.listen(_failures.add);
    }
    return spawned;
  }

  /// Keeps the audio around [event] in memory (ЗВ-02): at once with what
  /// has been heard, and again once the padding after it was recorded.
  void _keepSnippet(CheckEvent event) {
    void keep() {
      final capture = _capture;
      if (capture == null || _disposed) return;
      unawaited(
        capture.retainReviewSnippet(
          eventId: event.eventId,
          startMs: event.audioStartMs > _snippetPadMs
              ? event.audioStartMs - _snippetPadMs
              : 0,
          endMs: event.audioEndMs + _snippetPadMs,
        ),
      );
    }

    keep();
    _snippetTimers.add(Timer(Duration(milliseconds: _snippetPadMs), keep));
  }

  @override
  ReviewAudio? reviewSnippet(String eventId) =>
      switch (_capture?.reviewSnippet(eventId)) {
        final audio.AudioSnippet s => ReviewAudio(
          samples: s.samples,
          sampleRate: s.sampleRate,
        ),
        null => null,
      };

  @override
  void closeReview() {
    for (final timer in _snippetTimers) {
      timer.cancel();
    }
    _snippetTimers.clear();
    _capture?.closeReview();
  }

  void _onDiagnosticMessage(Object? message) {
    if (message case ['recognition', final bool isFinal, final int decodeMs]) {
      _diagnostics.add(
        PrototypeSessionDiagnostic(
          isFinal
              ? PrototypeDiagnosticKind.recognitionFinal
              : PrototypeDiagnosticKind.recognitionPartial,
          decodeMs: decodeMs,
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    closeReview();
    _disposed = true;
    await _spawnResult;
    await _eventSubscription?.cancel();
    await _failureSubscription?.cancel();
    await _diagnosticSubscription?.cancel();
    _diagnosticPort?.close();
    await _isolate?.dispose();
    await _events.close();
    await _failures.close();
    await _diagnostics.close();
  }
}

/// Root-isolate audio source shared by live microphone and real-time WAV input.
final class PrototypeSessionAudioSource implements SessionAudioSource {
  /// Creates a source around the platform-facing capture service.
  new({
    required this._capture,
    required this._input,
    required this._vadModelPath,
    required this._expectedSessionId,
    required this._onFileFinished,
    required this._onDiagnostic,
  });

  final audio.AudioCaptureService _capture;
  final PrototypeSessionInput _input;
  final String _vadModelPath;
  final String _expectedSessionId;
  final void Function() _onFileFinished;
  final void Function(PrototypeSessionDiagnostic) _onDiagnostic;
  final audio.AudioCaptureSessionEventMapper _mapper =
      audio.AudioCaptureSessionEventMapper();
  final StreamController<Result<SessionAudioEvent>> _events =
      StreamController<Result<SessionAudioEvent>>.broadcast(sync: true);

  StreamSubscription<Result<Object>>? _subscription;
  var _started = false;
  var _disposed = false;
  var _fileFinished = false;

  @override
  Stream<Result<SessionAudioEvent>> get events => _events.stream;

  @override
  Future<Result<void>> start(String sessionId) async {
    if (_disposed) return _failure('disposed', 'The source is disposed.');
    if (_started) return _failure('alreadyStarted', 'The source has started.');
    if (sessionId != _expectedSessionId) {
      return _failure('sessionIdMismatch', 'The session id does not match.');
    }
    _subscription = _capture.events.listen(_forward);
    final result = switch (_input) {
      PrototypeMicrophoneInput() => _capture.startMicrophone(
        vadModelPath: _vadModelPath,
        permissionExplanationShown: true,
      ),
      PrototypeWavInput(:final path) => _capture.startFile(
        vadModelPath: _vadModelPath,
        wavPath: path,
      ),
    };
    final started = await result;
    if (started case Error<void>()) {
      await _subscription?.cancel();
      _subscription = null;
      return started;
    }
    _started = true;
    return started;
  }

  void _forward(Result<Object> result) {
    switch (result) {
      case Error<Object>(:final error):
        _events.add(Result<SessionAudioEvent>.error(error));
      case Ok<Object>(:final value):
        if (value is audio.FileInputFinished && !_fileFinished) {
          _fileFinished = true;
          _onFileFinished();
        }
        final event = _mapper.map(value);
        if (event != null) {
          if (event is SessionAudioSegmentOpened) {
            _onDiagnostic(
              const PrototypeSessionDiagnostic(
                PrototypeDiagnosticKind.segmentOpened,
              ),
            );
          } else if (event is SessionAudioSegmentClosed) {
            _onDiagnostic(
              const PrototypeSessionDiagnostic(
                PrototypeDiagnosticKind.segmentClosed,
              ),
            );
          }
          _events.add(Result<SessionAudioEvent>.ok(event));
        }
    }
  }

  @override
  Future<Result<void>> pause() => switch (_input) {
    PrototypeMicrophoneInput() => _capture.notifyInterruption(
      audio.CapturePauseReason.background,
    ),
    PrototypeWavInput() => Future<Result<void>>.value(
      _failure('wavPauseUnsupported', 'WAV playback cannot be paused.'),
    ),
  };

  @override
  Future<Result<void>> resume() => switch (_input) {
    PrototypeMicrophoneInput() => _capture.resumeMicrophone(),
    PrototypeWavInput() => Future<Result<void>>.value(
      _failure('wavResumeUnsupported', 'WAV playback cannot be resumed.'),
    ),
  };

  @override
  Future<Result<void>> stop() => _capture.stop();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _subscription?.cancel();
    await _capture.dispose();
    await _events.close();
  }

  Result<void> _failure(String code, String message) =>
      Result<void>.error(PrototypeRealSessionException(code, message));
}

/// Top-level worker factory required by [ReadingSessionIsolate].
SessionIsolateWorker createPrototypeSessionWorker(
  SessionAudioSource audioSource,
  Object? rawConfiguration,
) {
  if (rawConfiguration is! Map<String, Object?>) {
    throw const PrototypeRealSessionException(
      'invalidConfiguration',
      'The session worker configuration is invalid.',
    );
  }
  final contentJson = _requiredString(rawConfiguration, 'contentJson');
  final normalizerJson = _requiredString(rawConfiguration, 'normalizerJson');
  final sessionId = _requiredString(rawConfiguration, 'sessionId');
  final diagnosticPort = rawConfiguration['diagnosticPort'];
  if (diagnosticPort is! SendPort) {
    throw const PrototypeRealSessionException(
      'invalidConfiguration',
      'The diagnostic port is invalid.',
    );
  }
  // Either the prototype content (pages 582–583) or the whole-Quran text
  // (format 2, ADR 0004) for any passage.
  final loaded = rawConfiguration['wholeQuranText'] == true
      ? QuranTextJsonSource(contentJson).loadWords()
      : ContentJsonSource(contentJson).loadWords();
  final words = switch (loaded) {
    Ok(:final value) => value,
    Error(:final error) => throw error,
  };
  final normalizer = switch (Normalizer.fromJson(normalizerJson)) {
    Ok(:final value) => value,
    Error(:final error) => throw error,
  };
  final text = InMemoryQuranText(
    words: words,
    normalizers: <Normalizer>[normalizer],
    params: SearchParams.defaults,
  );
  return ReadingSession(
    recognizer: _DiagnosticSpeechRecognizer(
      SherpaCtcRecognizer(sessionId: sessionId),
      diagnosticPort,
    ),
    audioSource: audioSource,
    text: text,
    normalizer: normalizer,
    versions: ReadingVersions(
      modelId: 'pending',
      modelVersion: 'pending',
      rulesVersion: _requiredString(rawConfiguration, 'rulesVersion'),
      textVersion: _requiredString(rawConfiguration, 'textVersion'),
    ),
    modelDirectory: _requiredString(rawConfiguration, 'modelDirectory'),
    createSessionId: () => sessionId,
  );
}

Map<String, Object?> _workerConfiguration(
  PrototypeSessionConfiguration configuration,
  String sessionId,
  SendPort diagnosticPort,
) => <String, Object?>{
  'contentJson': configuration.contentJson,
  'wholeQuranText': configuration.wholeQuranText,
  'normalizerJson': configuration.normalizerJson,
  'modelDirectory': configuration.modelDirectory,
  'textVersion': configuration.textVersion,
  'rulesVersion': configuration.rulesVersion,
  'sessionId': sessionId,
  'diagnosticPort': diagnosticPort,
};

final class _DiagnosticSpeechRecognizer implements SpeechRecognizer {
  new(this._delegate, this._diagnosticPort);

  final SpeechRecognizer _delegate;
  final SendPort _diagnosticPort;

  @override
  RecognizerInfo get info => _delegate.info;

  @override
  Stream<RecognitionResult> get results => _delegate.results.map((result) {
    _diagnosticPort.send(<Object?>[
      'recognition',
      result.isFinal,
      result.decodeMs,
    ]);
    return result;
  });

  @override
  Future<Result<void>> load(String modelDirectory) =>
      _delegate.load(modelDirectory);

  @override
  void acceptAudio(Float32List samples, int sampleRateHz, int startMs) =>
      _delegate.acceptAudio(samples, sampleRateHz, startMs);

  @override
  void closeSegment(int segmentId) => _delegate.closeSegment(segmentId);

  @override
  Future<void> dispose() => _delegate.dispose();
}

String _requiredString(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is String && value.isNotEmpty) return value;
  throw PrototypeRealSessionException(
    'invalidConfiguration',
    'The session worker field $key is invalid.',
  );
}

/// Safe configuration or lifecycle failure without audio or recognized text.
final class PrototypeRealSessionException implements Exception {
  /// Creates a safe failure.
  const new(this.code, this.message);

  /// Stable machine-readable code.
  final String code;

  /// Safe diagnostic text.
  final String message;

  @override
  String toString() => 'PrototypeRealSessionException($code): $message';
}
