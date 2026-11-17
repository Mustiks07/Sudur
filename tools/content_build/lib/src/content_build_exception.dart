/// A content build step failed: bad source data, failed check or I/O error.
final class ContentBuildException implements Exception {
  /// Creates an exception with a human-readable [message].
  const ContentBuildException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'ContentBuildException: $message';
}
