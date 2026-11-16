import 'package:contracts/contracts.dart';

/// Allowed state changes of a check event (docs/tz 10.5):
///
/// ```text
/// preliminary ─→ confirmed ─→ disputed
///      ├──────→ corrected
///      └──────→ unverified
/// ```
///
/// Nothing leaves `corrected`, `unverified` or `disputed`; `confirmed`
/// never becomes `corrected` (a correction after confirmation is a new
/// attempt).
const Map<CheckState, Set<CheckState>> allowedTransitions = {
  CheckState.preliminary: {
    CheckState.confirmed,
    CheckState.corrected,
    CheckState.unverified,
  },
  CheckState.confirmed: {CheckState.disputed},
  CheckState.corrected: {},
  CheckState.unverified: {},
  CheckState.disputed: {},
};

/// Whether an event may go from [from] to [to].
bool canMove(CheckState from, CheckState to) =>
    allowedTransitions[from]?.contains(to) ?? false;

/// A forbidden state change was requested.
final class CheckTransitionException implements Exception {
  /// Creates the exception.
  const CheckTransitionException(this.message);

  /// What was refused.
  final String message;

  @override
  String toString() => 'CheckTransitionException: $message';
}
