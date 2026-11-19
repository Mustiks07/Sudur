import 'dart:async';

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

  PrototypeSessionInput _input = const PrototypeMicrophoneInput();
  ReadingSessionIsolate? _isolate;
  Future<Result<ReadingSessionIsolate>>? _spawnResult;
  StreamSubscription<SessionEvent>? _eventSubscription;
  StreamSubscription<SessionIsolateFailure>? _failureSubscription;
  var _disposed = false;

  @override
  Stream<SessionEvent> get events => _events.stream;

  @override
  Stream<Exception> get failures => _failures.stream;

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
    late final PrototypeSessionAudioSource source;
    source = PrototypeSessionAudioSource(
      capture: audio.AudioCaptureService(sessionId: sessionId),
      input: _input,
      vadModelPath: _configuration.vadModelPath,
      expectedSessionId: sessionId,
      onFileFinished: () {
        final isolate = _isolate;
        if (isolate != null) unawaited(isolate.execute(const Stop()));
      },
    );
    final spawned = await _spawner(
      factory: createPrototypeSessionWorker,
      audioSource: source,
      configuration: _workerConfiguration(_configuration, sessionId),
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
      _eventSubscription = value.events.listen(_events.add);
      _failureSubscription = value.failures.listen(_failures.add);
    }
    return spawned;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _spawnResult;
    await _eventSubscription?.cancel();
    await _failureSubscription?.cancel();
    await _isolate?.dispose();
    await _events.close();
    await _failures.close();
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
  });

  final audio.AudioCaptureService _capture;
  final PrototypeSessionInput _input;
  final String _vadModelPath;
  final String _expectedSessionId;
  final void Function() _onFileFinished;
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
        if (event != null) _events.add(Result<SessionAudioEvent>.ok(event));
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
  final words = switch (ContentJsonSource(contentJson).loadWords()) {
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
    recognizer: SherpaCtcRecognizer(sessionId: sessionId),
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
) => <String, Object?>{
  'contentJson': configuration.contentJson,
  'normalizerJson': configuration.normalizerJson,
  'modelDirectory': configuration.modelDirectory,
  'textVersion': configuration.textVersion,
  'rulesVersion': configuration.rulesVersion,
  'sessionId': sessionId,
};

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
