import 'package:contracts/contracts.dart';

/// Result of one numbered request sent to the recognizer isolate.
final class RecognizerRequestOutcome {
  /// Creates a request outcome.
  const RecognizerRequestOutcome({
    required this.requestId,
    required this.result,
  });

  /// Monotonically increasing request number.
  final int requestId;

  /// A recognition result, no result for an accepted chunk, or an error.
  final Result<RecognitionResult?> result;
}
