/// A non-library-specific storage failure.
final class StorageException implements Exception {
  /// Creates a storage failure with a stable [code].
  const StorageException(this.code);

  /// Machine-readable failure code. It never contains user data.
  final String code;

  @override
  String toString() => 'StorageException($code)';
}
