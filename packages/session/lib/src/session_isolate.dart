import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:session/src/session_state.dart';

/// The part of a reading session hosted by [ReadingSessionIsolate].
abstract interface class SessionIsolateWorker {
  /// Session events forwarded to the owner isolate.
  Stream<SessionEvent> get events;

  /// Lifecycle changes forwarded to the owner isolate.
  Stream<ReadingSessionState> get states;

  /// Strict-mode guidance forwarded to the owner isolate.
  Stream<StrictSignal> get strictSignals;

  /// Current lifecycle state.
  ReadingSessionState get state;

  /// Executes one command in the worker isolate.
  Future<Result<void>> execute(SessionCommand command);

  /// Releases all worker resources.
  Future<void> dispose();
}

/// Creates the session worker around an isolate-safe [audioSource] proxy.
///
/// The function must be top-level or static and [configuration] must be
/// isolate-sendable. The real platform audio source stays in the root isolate;
/// only this proxy is passed to the worker factory.
typedef SessionIsolateWorkerFactory = FutureOr<SessionIsolateWorker> Function(
  SessionAudioSource audioSource,
  Object? configuration,
);

/// Failure of the long-lived reading-session isolate.
final class SessionIsolateFailure implements Exception {
  /// Creates a safe failure that contains neither audio nor recognized text.
  const SessionIsolateFailure(this.code, this.message);

  /// Stable machine-readable code.
  final String code;

  /// Safe diagnostic message.
  final String message;

  @override
  String toString() => 'SessionIsolateFailure($code): $message';
}

/// Command/event bridge to one long-lived reading-session isolate.
///
/// The platform audio source remains in the root isolate because Flutter event
/// channels cannot be listened to from a background isolate. Audio frames are
/// moved to the worker with [TransferableTypedData].
final class ReadingSessionIsolate {
  ReadingSessionIsolate._({
    required Isolate isolate,
    required ReceivePort responses,
    required ReceivePort errors,
    required ReceivePort exit,
    required SessionAudioSource audioSource,
  })  : _isolate = isolate,
        _responses = responses,
        _errors = errors,
        _exit = exit,
        _audioSource = audioSource;

  final Isolate _isolate;
  final ReceivePort _responses;
  final ReceivePort _errors;
  final ReceivePort _exit;
  final SessionAudioSource _audioSource;
  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast(sync: true);
  final StreamController<ReadingSessionState> _states =
      StreamController<ReadingSessionState>.broadcast(sync: true);
  final StreamController<StrictSignal> _strictSignals =
      StreamController<StrictSignal>.broadcast(sync: true);
  final StreamController<SessionIsolateFailure> _failures =
      StreamController<SessionIsolateFailure>.broadcast(sync: true);
  final Map<int, Completer<Result<void>>> _pending =
      <int, Completer<Result<void>>>{};
  final Completer<void> _ready = Completer<void>();
  final Completer<void> _exited = Completer<void>();

  StreamSubscription<Object?>? _responseSubscription;
  StreamSubscription<Object?>? _errorSubscription;
  StreamSubscription<Object?>? _exitSubscription;
  StreamSubscription<Result<SessionAudioEvent>>? _audioSubscription;
  SendPort? _commands;
  SendPort? _audioEvents;
  SessionIsolateFailure? _terminalFailure;
  ReadingSessionState _state = ReadingSessionState.idle;
  var _nextRequestId = 1;
  Future<Result<void>>? _audioDisposal;
  var _disposed = false;

  /// Starts a worker and waits until its command and audio ports are ready.
  ///
  /// Ownership of [audioSource] transfers to the returned controller. It is
  /// disposed on worker failure, failed startup, or [dispose].
  static Future<Result<ReadingSessionIsolate>> spawn({
    required SessionIsolateWorkerFactory factory,
    required SessionAudioSource audioSource,
    Object? configuration,
  }) async {
    final responses = ReceivePort();
    final errors = ReceivePort();
    final exit = ReceivePort();
    ReadingSessionIsolate? client;
    try {
      final isolate = await Isolate.spawn<List<Object?>>(
        _sessionIsolateMain,
        <Object?>[responses.sendPort, factory, configuration],
        onError: errors.sendPort,
        onExit: exit.sendPort,
        debugName: 'reading-session',
      );
      client = ReadingSessionIsolate._(
        isolate: isolate,
        responses: responses,
        errors: errors,
        exit: exit,
        audioSource: audioSource,
      ).._listen();
      await client._ready.future;
      return Result<ReadingSessionIsolate>.ok(client);
    } on Object catch (error) {
      if (client != null) {
        await client.dispose();
      } else {
        responses.close();
        errors.close();
        exit.close();
        await audioSource.dispose();
      }
      return Result<ReadingSessionIsolate>.error(
        SessionIsolateFailure('spawnFailed', error.runtimeType.toString()),
      );
    }
  }

  /// Session events received from the worker.
  Stream<SessionEvent> get events => _events.stream;

  /// Lifecycle changes received from the worker.
  Stream<ReadingSessionState> get states => _states.stream;

  /// Strict-mode guidance received from the worker.
  Stream<StrictSignal> get strictSignals => _strictSignals.stream;

  /// Explicit worker and transport failures.
  Stream<SessionIsolateFailure> get failures => _failures.stream;

  /// Latest worker lifecycle state.
  ReadingSessionState get state => _state;

  void _listen() {
    _responseSubscription = _responses.listen(_handleResponse);
    _errorSubscription = _errors.listen((_) {
      _fail(const SessionIsolateFailure('workerCrashed', 'Worker crashed.'));
    });
    _exitSubscription = _exit.listen((_) {
      if (!_exited.isCompleted) _exited.complete();
      if (!_disposed) {
        _fail(
          const SessionIsolateFailure(
            'workerExited',
            'Worker exited before disposal.',
          ),
        );
      }
    });
  }

  void _handleResponse(Object? message) {
    if (message is! List<Object?> || message.isEmpty) return;
    switch (message.first) {
      case 'ready':
        _commands = message[1]! as SendPort;
        _audioEvents = message[2]! as SendPort;
        _state = message[3]! as ReadingSessionState;
        _audioSubscription = _audioSource.events.listen(_forwardAudio);
        if (!_ready.isCompleted) _ready.complete();
      case 'event':
        if (!_events.isClosed) _events.add(message[1]! as SessionEvent);
      case 'state':
        _state = message[1]! as ReadingSessionState;
        if (!_states.isClosed) _states.add(_state);
      case 'strict':
        if (!_strictSignals.isClosed) {
          _strictSignals.add(message[1]! as StrictSignal);
        }
      case 'result':
        final id = message[1]! as int;
        _pending.remove(id)?.complete(message[2]! as Result<void>);
      case 'audioRequest':
        unawaited(_handleAudioRequest(message));
      case 'startupFailed':
        _fail(
          const SessionIsolateFailure(
            'startupFailed',
            'Worker initialization failed.',
          ),
        );
      case 'closed':
        if (!_exited.isCompleted) _exited.complete();
    }
  }

  void _forwardAudio(Result<SessionAudioEvent> result) {
    final port = _audioEvents;
    if (port == null || _terminalFailure != null || _disposed) return;
    port.send(<Object?>['audioEvent', _encodeAudioResult(result)]);
  }

  Future<void> _handleAudioRequest(List<Object?> message) async {
    final id = message[1]! as int;
    final operation = message[2]! as String;
    final argument = message[3];
    final responsePort = message[4]! as SendPort;
    Result<void> result;
    try {
      result = switch (operation) {
        'start' => await _audioSource.start(argument! as String),
        'pause' => await _audioSource.pause(),
        'resume' => await _audioSource.resume(),
        'stop' => await _audioSource.stop(),
        'dispose' => await _disposeAudioSource(),
        _ => const Result<void>.error(
            SessionIsolateFailure(
              'unknownAudioOperation',
              'Unknown audio operation.',
            ),
          ),
      };
    } on Object {
      result = const Result<void>.error(
        SessionIsolateFailure(
          'audioOperationFailed',
          'Platform audio operation failed.',
        ),
      );
    }
    responsePort.send(<Object?>['audioResult', id, _safeResult(result)]);
  }

  Future<Result<void>> _disposeAudioSource() =>
      _audioDisposal ??= _performAudioDisposal();

  Future<Result<void>> _performAudioDisposal() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _audioSource.dispose();
    return const Result<void>.ok(null);
  }

  /// Sends one command with a request id and returns its explicit result.
  Future<Result<void>> execute(SessionCommand command) {
    if (_disposed) {
      return Future<Result<void>>.value(
        const Result<void>.error(
          SessionIsolateFailure('disposed', 'Session isolate is disposed.'),
        ),
      );
    }
    final failure = _terminalFailure;
    if (failure != null) {
      return Future<Result<void>>.value(Result<void>.error(failure));
    }
    final port = _commands;
    if (port == null) {
      return Future<Result<void>>.value(
        const Result<void>.error(
          SessionIsolateFailure('notReady', 'Session isolate is not ready.'),
        ),
      );
    }
    final id = _nextRequestId++;
    final completer = Completer<Result<void>>();
    _pending[id] = completer;
    port.send(<Object?>['execute', id, command]);
    return completer.future;
  }

  void _fail(SessionIsolateFailure failure) {
    final isFirst = _terminalFailure == null;
    final terminal = _terminalFailure ??= failure;
    _commands = null;
    _audioEvents = null;
    if (!_failures.isClosed && isFirst) _failures.add(terminal);
    _completePending(terminal);
    if (!_ready.isCompleted) _ready.completeError(terminal);
    unawaited(_disposeAudioSource());
  }

  void _completePending(SessionIsolateFailure failure) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.complete(Result<void>.error(failure));
      }
    }
    _pending.clear();
  }

  /// Asks the worker to dispose, then closes every receive port and stream.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    const disposedFailure = SessionIsolateFailure(
      'disposed',
      'Session isolate is disposed.',
    );
    _completePending(disposedFailure);
    final port = _commands;
    _commands = null;
    _audioEvents = null;
    if (port != null) {
      port.send(const <Object?>['dispose']);
      try {
        await _exited.future.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        _isolate.kill(priority: Isolate.immediate);
      }
    } else {
      _isolate.kill(priority: Isolate.immediate);
    }
    await _disposeAudioSource();
    await _responseSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _exitSubscription?.cancel();
    _responses.close();
    _errors.close();
    _exit.close();
    await _events.close();
    await _states.close();
    await _strictSignals.close();
    await _failures.close();
  }
}

Future<void> _sessionIsolateMain(List<Object?> bootstrap) async {
  final owner = bootstrap[0]! as SendPort;
  final factory = bootstrap[1]! as SessionIsolateWorkerFactory;
  final configuration = bootstrap[2];
  final commands = ReceivePort();
  final audioSource = _WorkerAudioSource(owner);
  SessionIsolateWorker worker;
  try {
    worker = await factory(audioSource, configuration);
  } on Object {
    await audioSource.dispose();
    owner.send(const <Object?>['startupFailed']);
    commands.close();
    return;
  }

  final subscriptions = <StreamSubscription<Object>>[
    worker.events.listen((event) => owner.send(<Object?>['event', event])),
    worker.states.listen((state) => owner.send(<Object?>['state', state])),
    worker.strictSignals.listen(
      (signal) => owner.send(<Object?>['strict', signal]),
    ),
  ];
  owner.send(
    <Object?>[
      'ready',
      commands.sendPort,
      audioSource.eventPort,
      worker.state,
    ],
  );

  final done = Completer<void>();
  var closing = false;
  var commandQueue = Future<void>.value();
  final commandSubscription = commands.listen((message) {
    if (message is! List<Object?> || message.isEmpty || closing) return;
    if (message.first == 'dispose') {
      closing = true;
      unawaited(
        _closeWorker(
          owner: owner,
          commands: commands,
          subscriptions: subscriptions,
          worker: worker,
          done: done,
        ),
      );
      return;
    }
    if (message.first == 'execute') {
      commandQueue = commandQueue.then((_) async {
        if (closing) return;
        await _executeWorkerCommand(owner, message, worker);
      });
      unawaited(commandQueue);
    }
  });
  await done.future;
  await commandSubscription.cancel();
}

Future<void> _executeWorkerCommand(
  SendPort owner,
  List<Object?> message,
  SessionIsolateWorker worker,
) async {
  final id = message[1]! as int;
  final command = message[2]! as SessionCommand;
  Result<void> result;
  try {
    result = await worker.execute(command);
  } on Object {
    result = const Result<void>.error(
      SessionIsolateFailure('commandFailed', 'Worker command failed.'),
    );
  }
  owner.send(<Object?>['result', id, result]);
}

Future<void> _closeWorker({
  required SendPort owner,
  required ReceivePort commands,
  required List<StreamSubscription<Object>> subscriptions,
  required SessionIsolateWorker worker,
  required Completer<void> done,
}) async {
  commands.close();
  for (final subscription in subscriptions) {
    await subscription.cancel();
  }
  await worker.dispose();
  owner.send(const <Object?>['closed']);
  if (!done.isCompleted) done.complete();
}

final class _WorkerAudioSource implements SessionAudioSource {
  _WorkerAudioSource(this._owner) {
    _eventSubscription = _eventMessages.listen(_handleEvent);
    _responseSubscription = _responses.listen(_handleResponse);
  }

  final SendPort _owner;
  final ReceivePort _eventMessages = ReceivePort();
  final ReceivePort _responses = ReceivePort();
  final StreamController<Result<SessionAudioEvent>> _events =
      StreamController<Result<SessionAudioEvent>>.broadcast(sync: true);
  final Map<int, Completer<Result<void>>> _pending =
      <int, Completer<Result<void>>>{};
  late final StreamSubscription<Object?> _eventSubscription;
  late final StreamSubscription<Object?> _responseSubscription;
  var _nextRequestId = 1;
  var _disposed = false;

  SendPort get eventPort => _eventMessages.sendPort;

  @override
  Stream<Result<SessionAudioEvent>> get events => _events.stream;

  @override
  Future<Result<void>> start(String sessionId) => _request('start', sessionId);

  @override
  Future<Result<void>> pause() => _request('pause');

  @override
  Future<Result<void>> resume() => _request('resume');

  @override
  Future<Result<void>> stop() => _request('stop');

  Future<Result<void>> _request(String operation, [Object? argument]) {
    if (_disposed) {
      return Future<Result<void>>.value(
        const Result<void>.error(
          SessionIsolateFailure('audioDisposed', 'Audio bridge is disposed.'),
        ),
      );
    }
    final id = _nextRequestId++;
    final completer = Completer<Result<void>>();
    _pending[id] = completer;
    _owner.send(
      <Object?>[
        'audioRequest',
        id,
        operation,
        argument,
        _responses.sendPort,
      ],
    );
    return completer.future;
  }

  void _handleEvent(Object? message) {
    if (_disposed || message is! List<Object?> || message.isEmpty) return;
    if (message.first == 'audioEvent') {
      _events.add(_decodeAudioResult(message[1]!));
    }
  }

  void _handleResponse(Object? message) {
    if (message is! List<Object?> || message.length < 3) return;
    if (message.first != 'audioResult') return;
    final id = message[1]! as int;
    _pending.remove(id)?.complete(message[2]! as Result<void>);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    final result = await _request('dispose');
    _disposed = true;
    final failure = switch (result) {
      Error<void>(:final error) => error,
      Ok<void>() => const SessionIsolateFailure(
          'audioDisposed',
          'Audio bridge is disposed.',
        ),
    };
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.complete(Result.error(failure));
    }
    _pending.clear();
    await _eventSubscription.cancel();
    await _responseSubscription.cancel();
    _eventMessages.close();
    _responses.close();
    await _events.close();
  }
}

Object _encodeAudioResult(Result<SessionAudioEvent> result) => switch (result) {
      Error<SessionAudioEvent>() => const <Object?>['error'],
      Ok<SessionAudioEvent>(:final value) => _encodeAudioEvent(value),
    };

Object _encodeAudioEvent(SessionAudioEvent event) => switch (event) {
      SessionAudioFrame() => <Object?>[
          'frame',
          event.atMs,
          event.segmentId,
          TransferableTypedData.fromList(<TypedData>[
            event.samples.buffer.asUint8List(
              event.samples.offsetInBytes,
              event.samples.lengthInBytes,
            ),
          ]),
          event.sampleRateHz,
          event.startMs,
          event.endMs,
        ],
      SessionAudioSegmentOpened() => <Object?>[
          'opened',
          event.atMs,
          event.segmentId,
          event.pauseBeforeMs,
        ],
      SessionAudioSegmentClosed() => <Object?>[
          'closed',
          event.atMs,
          event.segmentId,
        ],
      SignalQuality() => <Object?>[
          'quality',
          event.sessionId,
          event.atMs,
          event.level.index,
          event.sinceMs,
          event.dbfs,
          event.clippedRatio,
        ],
      _ => const <Object?>['error'],
    };

Result<SessionAudioEvent> _decodeAudioResult(Object encoded) {
  if (encoded is! List<Object?> || encoded.isEmpty) {
    return const Result<SessionAudioEvent>.error(
      SessionIsolateFailure('invalidAudioMessage', 'Invalid audio message.'),
    );
  }
  return switch (encoded.first) {
    'frame' => Result<SessionAudioEvent>.ok(
        SessionAudioFrame(
          atMs: encoded[1]! as int,
          segmentId: encoded[2]! as int,
          samples: (encoded[3]! as TransferableTypedData)
              .materialize()
              .asFloat32List(),
          sampleRateHz: encoded[4]! as int,
          startMs: encoded[5]! as int,
          endMs: encoded[6]! as int,
        ),
      ),
    'opened' => Result<SessionAudioEvent>.ok(
        SessionAudioSegmentOpened(
          atMs: encoded[1]! as int,
          segmentId: encoded[2]! as int,
          pauseBeforeMs: encoded[3]! as int,
        ),
      ),
    'closed' => Result<SessionAudioEvent>.ok(
        SessionAudioSegmentClosed(
          atMs: encoded[1]! as int,
          segmentId: encoded[2]! as int,
        ),
      ),
    'quality' => Result<SessionAudioEvent>.ok(
        SignalQuality(
          sessionId: encoded[1]! as String,
          atMs: encoded[2]! as int,
          level: SignalQualityLevel.values[encoded[3]! as int],
          sinceMs: encoded[4] as int?,
          dbfs: encoded[5] as double?,
          clippedRatio: encoded[6] as double?,
        ),
      ),
    _ => const Result<SessionAudioEvent>.error(
        SessionIsolateFailure(
          'audioSourceError',
          'Platform audio source failed.',
        ),
      ),
  };
}

Result<void> _safeResult(Result<void> result) => switch (result) {
      Ok<void>() => const Result<void>.ok(null),
      Error<void>() => const Result<void>.error(
          SessionIsolateFailure(
            'audioOperationFailed',
            'Platform audio operation failed.',
          ),
        ),
    };
