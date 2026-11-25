import 'dart:async';

import 'package:contracts/contracts.dart';
import 'package:go_router/go_router.dart';
import 'package:lessons/lessons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/course/view_models/course_view_models.dart';

/// Text of [text] in the interface language (content, never written here).
String localized(BuildContext context, LocalizedText text) =>
    switch (Localizations.localeOf(context).languageCode) {
      'kk' => text.kk,
      'uz' => text.uz,
      'en' => text.en,
      _ => text.ru,
    };

/// «Учусь читать»: the path of stages and lessons (docs/tz 13.9).
final class CourseScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<CourseViewModel>();
    final config = context.read<E01Config>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final data = viewModel.data;
        if (viewModel.failed) return Center(child: Text(l10n.readFailed));
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final next = data.next;
        return ListView(
          key: const ValueKey('course'),
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            Text(
              l10n.courseAvailable(data.lessonCount),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (next != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.medium,
                ),
                child: FilledButton(
                  key: const ValueKey('course-continue'),
                  onPressed: () => _open(context, viewModel, next.id),
                  child: Text(l10n.continueAction),
                ),
              ),
            for (var stage = 1; stage <= config.courseStages; stage++)
              _Stage(
                stage: stage,
                paid: stage >= config.firstPaidStage,
                lessons: [
                  for (final p in data.packages)
                    if (p.stage == stage) ...p.lessons,
                ],
                states: data.states,
                next: next?.id,
                onOpen: (id) => _open(context, viewModel, id),
              ),
            TextButton(
              onPressed: () => unawaited(GoRouter.of(context).push('/tajweed')),
              child: Text(l10n.courseTajweed),
            ),
          ],
        );
      },
    );
  }

  Future<void> _open(
    BuildContext context,
    CourseViewModel viewModel,
    String lessonId,
  ) async {
    await GoRouter.of(context).push('/lesson', extra: lessonId);
    await viewModel.load();
  }
}

final class _Stage extends StatelessWidget {
  const new({
    required this.stage,
    required this.paid,
    required this.lessons,
    required this.states,
    required this.next,
    required this.onOpen,
  });

  final int stage;
  final bool paid;
  final List<Lesson> lessons;
  final Map<String, LessonState> states;
  final String? next;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(l10n.courseStage(stage)),
            trailing: paid
                ? Tooltip(
                    message: l10n.coursePaid,
                    child: const Icon(Icons.workspace_premium_outlined),
                  )
                : null,
            subtitle: lessons.isEmpty ? Text(l10n.courseSoon) : null,
          ),
          for (final lesson in lessons)
            ListTile(
              key: ValueKey('lesson-${lesson.id}'),
              enabled: states[lesson.id] != LessonState.locked,
              leading: Icon(switch (states[lesson.id]) {
                LessonState.passed => Icons.check_circle,
                LessonState.locked || null => Icons.lock_outline,
                _ => Icons.radio_button_unchecked,
              }),
              title: Text(
                localized(context, lesson.title),
                style: lesson.id == next
                    ? theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      )
                    : null,
              ),
              onTap: () => onOpen(lesson.id),
            ),
        ],
      ),
    );
  }
}

/// One lesson (docs/tz 13.10): one step per screen.
final class LessonScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<LessonViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final run = viewModel.run;
        final step = run?.current;
        final Widget body;
        if (viewModel.failed || run == null) {
          body = viewModel.failed
              ? Text(l10n.readFailed)
              : const CircularProgressIndicator();
        } else if (run.state == LessonState.passed) {
          body = _Finished(
            text: l10n.lessonPassed,
            score: run.quizScore,
            action: (l10n.reviewNext, () => Navigator.of(context).pop(true)),
          );
        } else if (run.state == LessonState.failed) {
          body = _Finished(
            text: l10n.lessonFailed,
            score: run.quizScore,
            action: (l10n.lessonRepeat, viewModel.retry),
          );
        } else if (step != null) {
          body = _StepView(
            key: ValueKey('step-${step.id}-${run.position}'),
            step: step,
            viewModel: viewModel,
          );
        } else {
          body = const SizedBox.shrink();
        }
        return Scaffold(
          appBar: AppBar(
            title: run == null
                ? null
                : Text(localized(context, run.lesson.title)),
            bottom: run == null || run.queue.isEmpty
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: LinearProgressIndicator(
                      value: run.position / run.queue.length,
                    ),
                  ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: body,
            ),
          ),
        );
      },
    );
  }
}

final class _Finished extends StatelessWidget {
  const new({required this.text, required this.score, required this.action});

  final String text;
  final QuizScored? score;
  final (String, VoidCallback) action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          key: const ValueKey('lesson-finished'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (score case final score?)
          Text(l10n.lessonQuizScore(score.percent.round())),
        const SizedBox(height: AppSpacing.large),
        FilledButton(onPressed: action.$2, child: Text(action.$1)),
      ],
    );
  }
}

final class _StepView extends StatefulWidget {
  const new({required this.step, required this.viewModel, super.key});

  final LessonStep step;
  final LessonViewModel viewModel;

  @override
  State<_StepView> createState() => _StepViewState();
}

final class _StepViewState extends State<_StepView> {
  final List<int> _order = [];
  final Set<WordKey> _marked = {};

  void _answer(StepAnswer answer) => unawaited(widget.viewModel.answer(answer));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = widget.step;
    final feedback = switch (widget.viewModel.lastResult) {
      final Answered a => a.correct ? l10n.lessonRight : l10n.lessonWrong,
      _ => null,
    };
    Widget choices(List<String> values, {List<String>? labels}) => Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      alignment: WrapAlignment.center,
      children: [
        for (final (i, value) in values.indexed)
          OutlinedButton(
            key: ValueKey('choice-$i'),
            onPressed: () => _answer(Choice(value)),
            child: Text(labels?[i] ?? value),
          ),
      ],
    );
    final audioNote = Text(
      l10n.lessonAudioSoon,
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
    final next = FilledButton(
      key: const ValueKey('lesson-next'),
      onPressed: () => _answer(const Acknowledged()),
      child: Text(l10n.reviewNext),
    );
    final selfAssess = Wrap(
      spacing: AppSpacing.medium,
      children: [
        FilledButton(
          key: const ValueKey('lesson-got-it'),
          onPressed: () => _answer(const SelfAssessment(gotIt: true)),
          child: Text(l10n.lessonGotIt),
        ),
        OutlinedButton(
          onPressed: () => _answer(const SelfAssessment(gotIt: false)),
          child: Text(l10n.lessonNotQuite),
        ),
      ],
    );
    final content = switch (step) {
      ExplainStep(:final text) => [Text(localized(context, text)), next],
      ListenStep(:final highlight) => [Text(highlight), audioNote, next],
      // УЧ-06: recording stays in memory; until audio and recording are in
      // the app the step is assessed by the person.
      RepeatAndCompareStep() || SpeakAndCheckStep() => [
        Text(l10n.lessonRepeatCompare),
        audioNote,
        selfAssess,
      ],
      HearAndChooseStep(:final options) => [audioNote, choices(options)],
      SeeAndChooseStep(:final prompt, :final optionsAudio) => [
        Text(prompt),
        audioNote,
        choices(
          optionsAudio,
          labels: [
            for (var i = 0; i < optionsAudio.length; i++)
              l10n.lessonOption(i + 1),
          ],
        ),
      ],
      PairDiscriminateStep(:final pair) => [
        audioNote,
        choices([pair.$1, pair.$2]),
      ],
      FindFormStep(:final letter, :final options) => [
        Text(letter),
        choices(options),
      ],
      BuildSyllableStep(:final pieces) => [
        Text(l10n.lessonBuild),
        Wrap(
          spacing: AppSpacing.small,
          children: [
            for (final (i, piece) in pieces.indexed)
              FilterChip(
                label: Text(piece),
                selected: _order.contains(i),
                onSelected: (_) => setState(() {
                  _order.contains(i) ? _order.remove(i) : _order.add(i);
                }),
              ),
          ],
        ),
        FilledButton(
          onPressed: _order.length == pieces.length
              ? () => _answer(PieceOrder(List.of(_order)))
              : null,
          child: Text(l10n.selfDone),
        ),
      ],
      ReadSupportedStep(:final from, :final to) => [
        Text('$from – $to'),
        FilledButton(
          onPressed: () async {
            await GoRouter.of(context).push<bool>(
              selfCheckLocation(from, to, path: '/read', mode: 'supported'),
            );
            _answer(const SupportedReadingFinished());
          },
          child: Text(l10n.readStart),
        ),
      ],
      FindRuleStep(:final from, :final to, :final answerWords) => [
        Text(l10n.lessonFindRule),
        Text('$from – $to'),
        Wrap(
          spacing: AppSpacing.small,
          children: [
            // Word places only: the text comes from the canon on «Чтение».
            for (final word in {...answerWords, from, to})
              FilterChip(
                label: Text('$word'),
                selected: _marked.contains(word),
                onSelected: (_) => setState(() {
                  _marked.contains(word)
                      ? _marked.remove(word)
                      : _marked.add(word);
                }),
              ),
          ],
        ),
        FilledButton(
          onPressed: () => _answer(RuleWords(Set.of(_marked))),
          child: Text(l10n.selfDone),
        ),
      ],
      QuizStep() => [next],
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (feedback != null)
          Text(feedback, key: const ValueKey('lesson-feedback')),
        const SizedBox(height: AppSpacing.medium),
        for (final widget in content) ...[
          widget,
          const SizedBox(height: AppSpacing.medium),
        ],
      ],
    );
  }
}

/// Tajweed reference (docs/tz 13.11): its rules come with the course
/// content; until then the screen says so.
final class TajweedScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.courseTajweed)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Text(l10n.tajweedSoon, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
