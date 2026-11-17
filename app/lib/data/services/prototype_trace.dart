import 'dart:convert';

/// Bounded metadata trace, with no audio or recognized strings.
final class PrototypeTrace {
  /// Creates a trace with a configurable memory limit.
  new({this.capacity = 200000});

  /// Maximum events retained in memory.
  final int capacity;
  final Stopwatch _clock = Stopwatch();
  final List<Map<String, Object?>> _events = [];
  int _dropped = 0;

  /// Starts a new monotonic trace.
  void start() {
    _events.clear();
    _dropped = 0;
    _clock
      ..reset()
      ..start();
  }

  /// Adds only numeric timing/position metadata and an internal event name.
  void add(
    String kind, {
    int? audioMs,
    int? startMs,
    int? segment,
    int? wordIndex,
    int? durationUs,
    int? samples,
    int? requestId,
    int? buildUs,
    int? rasterUs,
  }) {
    if (_events.length >= capacity) {
      _dropped++;
      return;
    }
    _events.add({
      'kind': kind,
      'wallUs': _clock.elapsedMicroseconds,
      'audioMs': ?audioMs,
      'startMs': ?startMs,
      'segment': ?segment,
      'wordIndex': ?wordIndex,
      'durationUs': ?durationUs,
      'samples': ?samples,
      'requestId': ?requestId,
      'buildUs': ?buildUs,
      'rasterUs': ?rasterUs,
    });
  }

  /// Exports metadata only; dropped events make a measurement invalid.
  String encode(String model) => jsonEncode({
    'format': 1,
    'model': model,
    'droppedEvents': _dropped,
    'clock': 'monotonic microseconds since start',
    'events': _events,
  });
}
