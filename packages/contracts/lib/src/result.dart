/// Outcome of an operation that can fail.
///
/// Used across layers instead of throwing exceptions
/// (docs/tz section 17.2, Flutter architecture guide).
sealed class Result<T> {
  const Result();

  /// Creates a successful result holding [value].
  const factory Result.ok(T value) = Ok<T>;

  /// Creates a failed result holding [error].
  const factory Result.error(Exception error) = Error<T>;
}

/// A successful [Result].
final class Ok<T> extends Result<T> {
  /// Creates a successful result holding [value].
  const Ok(this.value);

  /// The value produced by the operation.
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// A failed [Result].
final class Error<T> extends Result<T> {
  /// Creates a failed result holding [error].
  const Error(this.error);

  /// The reason the operation failed.
  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}
