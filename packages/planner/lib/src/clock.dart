/// Supplies current time to planner operations.
abstract interface class Clock {
  /// Current instant. Planner converts it to UTC before scheduling.
  DateTime now();
}

/// Reads the system clock.
final class SystemClock implements Clock {
  /// Creates a system clock.
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A mutable clock intended for deterministic simulations and tests.
final class SimulatedClock implements Clock {
  /// Creates a clock at [value].
  SimulatedClock(DateTime value) : _value = value;

  DateTime _value;

  @override
  DateTime now() => _value;

  /// Moves the clock to [newValue].
  // A named method is clearer than a write-only property in simulations.
  // ignore: use_setters_to_change_properties
  void moveTo(DateTime newValue) => _value = newValue;

  /// Moves the clock forward by [duration].
  void advance(Duration duration) => _value = _value.add(duration);
}
