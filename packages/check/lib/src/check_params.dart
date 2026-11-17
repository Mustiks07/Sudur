import 'package:meta/meta.dart';

/// Parameters of checking (docs/tz 12.4, group «Проверка»; shipped with the
/// model in `thresholds.json`).
@immutable
final class CheckParams {
  /// Creates parameters.
  const CheckParams({
    required this.strongMatch,
    required this.substitutionMax,
    required this.confirmContextWords,
    required this.jumpMinWords,
    required this.selfCorrectionMs,
    required this.selfCorrectionWords,
    required this.hesitationPauseMs,
    required this.hesitationTempoFactor,
    required this.strictMaxFails,
    required this.strictMaxWaitMs,
  });

  /// Reads `thresholds.json` values; missing keys keep [defaults].
  ///
  /// Throws [FormatException] if a value has the wrong type.
  factory CheckParams.fromJson(Map<String, Object?> json) {
    const d = defaults;
    int i(String k, int fallback) => switch (json[k]) {
          null => fallback,
          final int v => v,
          final v => throw FormatException('"$k" must be an integer', v),
        };
    double n(String k, double fallback) => switch (json[k]) {
          null => fallback,
          final num v => v.toDouble(),
          final v => throw FormatException('"$k" must be a number', v),
        };
    return CheckParams(
      strongMatch: n('strongMatch', d.strongMatch),
      substitutionMax: n('substitutionMax', d.substitutionMax),
      confirmContextWords: i('confirmContextWords', d.confirmContextWords),
      jumpMinWords: i('jumpMinWords', d.jumpMinWords),
      selfCorrectionMs: i('selfCorrectionMs', d.selfCorrectionMs),
      selfCorrectionWords: i('selfCorrectionWords', d.selfCorrectionWords),
      hesitationPauseMs: i('hesitationPauseMs', d.hesitationPauseMs),
      hesitationTempoFactor: n(
        'hesitationTempoFactor',
        d.hesitationTempoFactor,
      ),
      strictMaxFails: i('strictMaxFails', d.strictMaxFails),
      strictMaxWaitMs: i('strictMaxWaitMs', d.strictMaxWaitMs),
    );
  }

  /// Built-in values of docs/tz 12.4.
  static const CheckParams defaults = CheckParams(
    strongMatch: 0.85,
    substitutionMax: 0.6,
    confirmContextWords: 2,
    jumpMinWords: 3,
    selfCorrectionMs: 2500,
    selfCorrectionWords: 2,
    hesitationPauseMs: 2500,
    hesitationTempoFactor: 3,
    strictMaxFails: 3,
    strictMaxWaitMs: 15000,
  );

  /// Similarity of a confident match.
  final double strongMatch;

  /// Below this similarity a match is a substitution candidate; from here up
  /// to [strongMatch] it is "could not verify".
  final double substitutionMax;

  /// Strong matches after a candidate that confirm it.
  final int confirmContextWords;

  /// Consecutive words at another place that confirm a jump.
  final int jumpMinWords;

  /// Self-correction window in time.
  final int selfCorrectionMs;

  /// Self-correction window in heard words.
  final int selfCorrectionWords;

  /// Shortest pause inside an ayah that may be a hesitation.
  final int hesitationPauseMs;

  /// A hesitation is also longer than this many personal median pauses.
  final double hesitationTempoFactor;

  /// Failed tries in strict mode before a hint is offered.
  final int strictMaxFails;

  /// Wait in strict mode before a hint is offered, ms.
  final int strictMaxWaitMs;
}
