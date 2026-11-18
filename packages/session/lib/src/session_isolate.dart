import 'dart:async';
import 'dart:isolate';

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

/// Creates all session dependencies inside the worker isolate.
///
/// The function must be top-level or static and [configuration] must be
/// isolate-sendable. This prevents native audio and ASR objects from first
/// being created on the UI isolate.
typedef SessionIsolateWorkerFactory = FutureOr<SessionIsolateWorker> Function(
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
final class ReadingSessionIsolate {
  ReadingSessionIsolate._({
    required Isolate isolate,
    required ReceivePort responses,
    required ReceivePort errors,
    required ReceivePort exit,
  })  : _isolate = isolate,
        _responses = responses,
        _errors = errors,
        _exit = exit;

  final Isolate _isolate;
  final ReceivePort _responses;
  final ReceivePort _errors;
  final ReceivePort _exit;
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
  SendPort? _commands;
  ReadingSessionState _state = ReadingSessionState.idle;
  var _nextRequestId = 1;
  var _disposed = false;

  /// Starts a worker and waits until its command port is ready.
  static Future<Result<ReadingSessionIsolate>> spawn({
    required SessionIsolateWorkerFactory factory,
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
      ).._listen();
      await client._ready.future;
      return Result<ReadingSessionIsolate>.ok(client);
    } on Exception catch (error) {
      if (client != null) {
        await client.dispose();
      } else {
        responses.close();
        errors.close();
        exit.close();
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
        _state = message[2]! as ReadingSessionState;
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

  /// Sends one command with a request id and returns its explicit result.
  Future<Result<void>> execute(SessionCommand command) {
    if (_disposed) {
      return Future<Result<void>>.value(
        const Result<void>.error(
          SessionIsolateFailure('disposed', 'Session isolate is disposed.'),
        ),
      );
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
    if (!_failures.isClosed) _failures.add(failure);
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.complete(Result.error(failure));
    }
    _pending.clear();
    if (!_ready.isCompleted) _ready.completeError(failure);
  }

  /// Asks the worker to dispose, then closes every receive port and stream.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final port = _commands;
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
  SessionIsolateWorker worker;
  try {
    worker = await factory(configuration);
  } on Object {
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
  owner.send(<Object?>['ready', commands.sendPort, worker.state]);

  await for (final message in commands) {
    if (message is! List<Object?> || message.isEmpty) continue;
    if (message.first == 'dispose') {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await worker.dispose();
      owner.send(const <Object?>['closed']);
      commands.close();
      return;
    }
    if (message.first != 'execute') continue;
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
}
