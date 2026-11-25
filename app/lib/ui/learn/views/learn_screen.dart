import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/learn/view_models/learn_view_model.dart';

/// Learning a new passage (docs/tz 13.6). Returns `true` when learned.
final class LearnScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<LearnViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final plan = viewModel.plan;
        final step = viewModel.current;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.learnTitle)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: switch (viewModel.state) {
                LearnState.preparing => const CircularProgressIndicator(),
                LearnState.error => Text(l10n.readFailed),
                LearnState.learned => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.learnLearned,
                      key: const ValueKey('learn-learned'),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.reviewNext),
                    ),
                  ],
                ),
                LearnState.step when plan != null && step != null => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: viewModel.index / plan.steps.length,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      _title(l10n, step.kind),
                      key: ValueKey('learn-step-${step.kind.name}'),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text('${step.from} – ${step.to}'),
                    const SizedBox(height: AppSpacing.large),
                    if (step.kind == LearnStepKind.listen) ...[
                      // No reciter audio yet: the step is shown, not faked.
                      Text(
                        l10n.learnListenUnavailable,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      OutlinedButton(
                        key: const ValueKey('learn-skip-listen'),
                        onPressed: viewModel.skipListening,
                        child: Text(l10n.learnSkipListening),
                      ),
                    ] else
                      FilledButton(
                        key: const ValueKey('learn-start'),
                        onPressed: () async {
                          final clean = await GoRouter.of(context).push<bool>(
                            selfCheckLocation(
                              step.from,
                              step.to,
                              path: '/read',
                              // The passage's own steps count for its unit.
                              stepId:
                                  step.from == plan.from && step.to == plan.to
                                  ? viewModel.stepId
                                  : null,
                              mode: _mode(step.kind),
                            ),
                          );
                          await viewModel.stepFinished(clean: clean ?? false);
                        },
                        child: Text(l10n.readStart),
                      ),
                  ],
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        );
      },
    );
  }

  static String _mode(LearnStepKind kind) => switch (kind) {
    LearnStepKind.supported => 'supported',
    LearnStepKind.recall => 'recall',
    LearnStepKind.listen ||
    LearnStepKind.test ||
    LearnStepKind.junction ||
    LearnStepKind.combined => 'test',
  };

  static String _title(AppLocalizations l10n, LearnStepKind kind) =>
      switch (kind) {
        LearnStepKind.listen => l10n.learnListen,
        LearnStepKind.supported => l10n.learnSupported,
        LearnStepKind.recall => l10n.learnRecall,
        LearnStepKind.test => l10n.learnTest,
        LearnStepKind.junction => l10n.learnJunction,
        LearnStepKind.combined => l10n.learnCombined,
      };
}
