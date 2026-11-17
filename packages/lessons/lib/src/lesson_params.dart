import 'package:meta/meta.dart';

/// Lesson parameters (docs/tz 12.4, group «Прочее»; the `config` package).
@immutable
final class LessonParams {
  /// Creates parameters.
  const LessonParams({
    required this.quizPassPercent,
    required this.skillReviewQuestions,
  });

  /// Reads `config` values; missing keys keep [defaults].
  ///
  /// Throws [FormatException] if a value has the wrong type or range.
  factory LessonParams.fromJson(Map<String, Object?> json) {
    const d = defaults;
    final pass = switch (json['quizPassPercent']) {
      null => d.quizPassPercent,
      final num v when v >= 0 && v <= 100 => v.toDouble(),
      final v => throw FormatException(
          '"quizPassPercent" must be a number in 0..100',
          v,
        ),
    };
    final questions = switch (json['skillReviewQuestions']) {
      null => d.skillReviewQuestions,
      final int v when v >= 1 => v,
      final v => throw FormatException(
          '"skillReviewQuestions" must be a positive integer',
          v,
        ),
    };
    return LessonParams(
      quizPassPercent: pass,
      skillReviewQuestions: questions,
    );
  }

  /// Built-in values: 12.4 and 11.2.
  static const LessonParams defaults = LessonParams(
    quizPassPercent: 80,
    skillReviewQuestions: 3,
  );

  /// A lesson is passed when its mini-quiz reaches this percent (УЧ-04,
  /// `quizPassPercent`). A quiz step of a package may set its own value.
  final double quizPassPercent;

  /// Questions in one skill review (docs/tz 11.2: «3 вопроса»). Not in the
  /// 12.4 table yet; proposed for it.
  final int skillReviewQuestions;
}
