import 'package:meta/meta.dart';

/// Interface languages of lesson texts (docs/tz 16.3, ГЛ-01).
enum LessonLanguage {
  /// Russian.
  ru,

  /// Kazakh.
  kk,

  /// Uzbek.
  uz,

  /// English.
  en,
}

/// Marker of content that is not written yet (docs/tz 4.9). A package with it
/// must not reach a release build.
const String todoContent = 'TODO_CONTENT';

/// A lesson text in every interface language (УЧ-10).
@immutable
final class LocalizedText {
  /// Creates a text with all four languages.
  const LocalizedText({
    required this.ru,
    required this.kk,
    required this.uz,
    required this.en,
  });

  /// Russian.
  final String ru;

  /// Kazakh.
  final String kk;

  /// Uzbek.
  final String uz;

  /// English.
  final String en;

  /// The text in [language].
  String of(LessonLanguage language) => switch (language) {
        LessonLanguage.ru => ru,
        LessonLanguage.kk => kk,
        LessonLanguage.uz => uz,
        LessonLanguage.en => en,
      };

  /// Whether any language is still a [todoContent] placeholder.
  bool get hasTodo => LessonLanguage.values.any(
        (l) => of(l).contains(todoContent),
      );

  @override
  bool operator ==(Object other) =>
      other is LocalizedText &&
      other.ru == ru &&
      other.kk == kk &&
      other.uz == uz &&
      other.en == en;

  @override
  int get hashCode => Object.hash(ru, kk, uz, en);
}
