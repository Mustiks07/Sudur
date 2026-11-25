import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planner/planner.dart';
import 'package:provider/provider.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/exercise/view_models/exercise_view_model.dart';

/// The exercise screen (docs/tz 13.5).
final class ExerciseScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ExerciseViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final plan = viewModel.plan;
        final step = viewModel.current;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.exerciseTitle)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: switch (viewModel.state) {
                ExerciseState.preparing => const CircularProgressIndicator(),
                ExerciseState.error => Text(l10n.readFailed),
                ExerciseState.closed || ExerciseState.again => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewModel.state == ExerciseState.closed
                          ? l10n.exerciseClosed
                          : l10n.exerciseAgain,
                      key: const ValueKey('exercise-result'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.reviewNext),
                    ),
                  ],
                ),
                ExerciseState.step when plan != null && step != null => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_kind(l10n, plan.kind)} · ${plan.place}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      l10n.exerciseProgress(
                        viewModel.index + 1,
                        plan.steps.length,
                      ),
                    ),
                    if (plan.usesSimilarPairs)
                      Text(
                        l10n.exerciseUnverifiedPairs,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      '${step.from} – ${step.to} · ${_mode(l10n, step.mode)}',
                    ),
                    const SizedBox(height: AppSpacing.large),
                    FilledButton(
                      key: const ValueKey('exercise-step'),
                      onPressed: () async {
                        final clean = await GoRouter.of(context).push<bool>(
                          selfCheckLocation(
                            step.from,
                            step.to,
                            path: '/read',
                            mode: step.mode.name,
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

  static String _kind(AppLocalizations l10n, ExerciseKind kind) =>
      switch (kind) {
        ExerciseKind.hardPassage => l10n.exerciseHardPassage,
        ExerciseKind.transition => l10n.exerciseTransition,
        ExerciseKind.startInMiddle => l10n.exerciseStartInMiddle,
        ExerciseKind.fadingHelp => l10n.exerciseFadingHelp,
        ExerciseKind.similarAyahs => l10n.exerciseSimilar,
        ExerciseKind.rereadOrSelfCheck => l10n.exerciseReread,
      };

  static String _mode(AppLocalizations l10n, ExerciseReadMode mode) =>
      switch (mode) {
        ExerciseReadMode.supported => l10n.readModeSupported,
        ExerciseReadMode.recall => l10n.readModeRecall,
        ExerciseReadMode.test => l10n.readModeTest,
      };
}
