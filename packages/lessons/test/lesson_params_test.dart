import 'package:lessons/lessons.dart';
import 'package:test/test.dart';

void main() {
  test('defaults are the spec values (12.4, 11.2)', () {
    expect(LessonParams.defaults.quizPassPercent, 80);
    expect(LessonParams.defaults.skillReviewQuestions, 3);
  });

  test('config values override, missing keys keep defaults', () {
    final p = LessonParams.fromJson(const {'quizPassPercent': 70});
    expect(p.quizPassPercent, 70);
    expect(p.skillReviewQuestions, 3);
  });

  test('wrong values are rejected', () {
    expect(
      () => LessonParams.fromJson(const {'quizPassPercent': 101}),
      throwsFormatException,
    );
    expect(
      () => LessonParams.fromJson(const {'skillReviewQuestions': 0}),
      throwsFormatException,
    );
    expect(
      () => LessonParams.fromJson(const {'quizPassPercent': '80'}),
      throwsFormatException,
    );
  });

  test('localized text picks the language and finds placeholders', () {
    const t = LocalizedText(ru: 'а', kk: 'ә', uz: 'o', en: todoContent);
    expect(t.of(LessonLanguage.kk), 'ә');
    expect(t.hasTodo, isTrue);
    expect(
      const LocalizedText(ru: 'а', kk: 'ә', uz: 'o', en: 'e').hasTodo,
      isFalse,
    );
  });
}
