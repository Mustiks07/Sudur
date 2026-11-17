import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:contracts/contracts.dart';
import 'package:follow/follow.dart';
import 'package:quran_text/quran_text.dart';
import 'package:sudur/config/prototype_config.dart';

/// Ordered following hosted off the UI isolate for one reading session.
final class PrototypeFollow {
  new _(this._isolate, this._port, this._responses);
  final Isolate _isolate;
  final SendPort _port;
  final ReceivePort _responses;

  /// Starts and validates the content and model normalizer inside the worker.
  static Future<PrototypeFollow> start(String root, String model) async {
    final responses = ReceivePort();
    final ready = Completer<SendPort>();
    final subscription = responses.listen((message) {
      if (message is SendPort) ready.complete(message);
      if (message is String) ready.completeError(StateError(message));
    });
    final isolate = await Isolate.spawn(_run, (
      responses.sendPort,
      root,
      model,
    ));
    try {
      final port = await ready.future.timeout(
        const PrototypeConfig().followTimeout,
      );
      await subscription.cancel();
      // Each operation supplies its own response port.
      return PrototypeFollow._(isolate, port, responses);
    } on Object {
      isolate.kill();
      await subscription.cancel();
      responses.close();
      rethrow;
    }
  }

  /// Feeds one recognition result without changing recognized text.
  Future<List<SessionEvent>> accept(RecognitionResult result) =>
      _request(result);

  /// Flushes the final path only after all ASR requests have completed.
  Future<List<SessionEvent>> finish(String session, int atMs) =>
      _request((session, atMs));

  Future<List<SessionEvent>> _request(Object command) async {
    final reply = ReceivePort();
    try {
      _port.send((command, reply.sendPort));
      final response = await reply.first.timeout(
        const PrototypeConfig().followTimeout,
      );
      if (response is List<SessionEvent>) return response;
      throw StateError('followFailed');
    } finally {
      reply.close();
    }
  }

  /// Releases worker-owned recognition history.
  void dispose() {
    _isolate.kill();
    _responses.close();
  }
}

void _run((SendPort, String, String) args) {
  final (ready, root, model) = args;
  try {
    final content = File('$root/content.json').readAsStringSync();
    final words = switch (ContentJsonSource(content).loadWords()) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    final normalizer = switch (Normalizer.fromJson(
      File('$root/$model/normalizer.json').readAsStringSync(),
    )) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    final params = FollowParams.fromJson(
      jsonDecode(File('$root/$model/thresholds.json').readAsStringSync())
          as Map<String, Object?>,
    );
    final text = InMemoryQuranText(
      words: words,
      normalizers: [normalizer],
      params: SearchParams(ngramSize: params.ngramSize),
    );
    final passage = words.where((w) => w.key.surah == 78).toList();
    final follow = Follower(
      text: text,
      normalizer: normalizer,
      from: passage.first.key,
      to: passage.last.key,
      params: params,
    );
    final requests = ReceivePort();
    ready.send(requests.sendPort);
    requests.listen((raw) {
      if (raw case (final Object command, final SendPort reply)) {
        try {
          final events = switch (command) {
            final RecognitionResult r => follow.accept(r).events,
            (final String id, final int atMs) =>
              follow.finish(sessionId: id, atMs: atMs).events,
            _ => throw StateError('invalidFollowRequest'),
          };
          reply.send(events);
        } on Object {
          reply.send('followFailed');
        }
      }
    });
  } on Object {
    ready.send('contentOrNormalizerInvalid');
  }
}
