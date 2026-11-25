import 'package:flutter_test/flutter_test.dart';
import 'package:lessons/lessons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/course/view_models/course_view_models.dart';
import 'package:sudur/ui/course/views/course_screens.dart';

import '../../test_helpers/fake_course_repository.dart';

StepAnswer _rightAnswer(LessonStep step) => switch (step) {
  ExplainStep() || ListenStep() || QuizStep() => const Acknowledged(),
  RepeatAndCompareStep() ||
  SpeakAndCheckStep() => const SelfAssessment(gotIt: true),
  HearAndChooseStep(:final answer) ||
  SeeAndChooseStep(:final answer) ||
  PairDiscriminateStep(:final answer) ||
  FindFormStep(:final answer) => Choice(answer),
  BuildSyllableStep(:final pieces) => PieceOrder([
    for (var i = 0; i < pieces.length; i++) i,
  ]),
  ReadSupportedStep() => const SupportedReadingFinished(),
  FindRuleStep(:final answerWords) => RuleWords(answerWords.toSet()),
};

void main() {
  test('the course: lessons of the stage, the first one is next', () async {
    final viewModel = CourseViewModel(FakeCourseRepository());
    await viewModel.load();
    final data = viewModel.data!;
    // Loaded just above.
    expect(data.lessonCount, 2);
    expect(data.next?.id, 'test-stage1-01');
    expect(data.states['test-stage1-02'], LessonState.locked);
  });

  test(
    'a lesson played to the end writes progress and skills (11.2)',
    () async {
      final repository = FakeCourseRepository();
      final course = CourseViewModel(repository);
      await course.load();
      final lesson = LessonViewModel(
        repository,
        const LessonEngine(params: LessonParams.defaults, clock: DateTime.now),
      );
      await lesson.start(course.data!, 'test-stage1-01');
      // Loaded just above.
      for (var i = 0; i < 50; i++) {
        final step = lesson.run?.current;
        if (step == null) break;
        await lesson.answer(_rightAnswer(step));
      }

      expect(lesson.run?.state, LessonState.passed);
      expect(repository.progress['test-stage1-01']?.state, LessonState.passed);
      expect(repository.skills, isNotEmpty);
      await course.load();
      expect(course.data?.next?.id, 'test-stage1-02', reason: 'opens the next');
    },
  );

  testWidgets('the course screen shows stages, the paid badge and Continue', (
    tester,
  ) async {
    final viewModel = CourseViewModel(FakeCourseRepository());
    await viewModel.load();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: viewModel),
          Provider<E01Config>.value(value: const E01Config()),
        ],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CourseScreen()),
        ),
      ),
    );
    expect(find.text('Доступно уроков: 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('course-continue')), findsOneWidget);
    expect(find.text('Этап 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Этап 4'), 200);
    expect(find.byIcon(Icons.workspace_premium_outlined), findsWidgets);
  });
}
