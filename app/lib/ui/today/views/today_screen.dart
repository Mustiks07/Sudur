import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/core/widgets/load_state_widgets.dart';
import 'package:sudur/ui/today/view_models/today_view_model.dart';

// Keep the constructor spelling consistent with the rest of the application.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Daily plan screen from spec 13.2.
class TodayScreen extends StatelessWidget {
  /// Creates the screen.
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TodayViewModel>();
    if (viewModel.loading) {
      return viewModel.showSkeleton ? const AppSkeleton() : const SizedBox();
    }
    if (viewModel.error != null || viewModel.data == null) {
      return AppErrorState(onRetry: viewModel.reload);
    }
    final data = viewModel.data!;
    final l10n = AppLocalizations.of(context);
    return ListView(
      key: ValueKey('today-${data.condition.name}'),
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Text(
          l10n.todayAroundMinutes(data.approximateMinutes),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(_condition(l10n, data.condition)),
        const SizedBox(height: AppSpacing.large),
        if (data.nextStep == null)
          _DayComplete(
            doneCount: data.doneCount,
            extraReview: data.extraReview,
            onReview: data.extraReview.isEmpty
                ? null
                : () => _open(
                    context,
                    viewModel,
                    viewModel.startAt(data.extraReview.first.id),
                  ),
          )
        else ...[
          for (final step in data.steps)
            Card(
              child: InkWell(
                onTap: step.done
                    ? null
                    : () =>
                          _open(context, viewModel, viewModel.startAt(step.id)),
                onLongPress: () => _confirmSkip(context, viewModel, step.id),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: ListTile(
                  leading: Icon(
                    step.done ? Icons.check_circle : _icon(step.kind),
                  ),
                  title: Text(_title(l10n, step)),
                  subtitle: Text(_reason(l10n, step.reason)),
                  trailing: step.selfCheck
                      ? Tooltip(
                          message: l10n.selfCheck,
                          child: const Icon(Icons.fact_check_outlined),
                        )
                      : null,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.medium),
          FilledButton.icon(
            key: const ValueKey('today-main-action'),
            onPressed: () => _open(context, viewModel, viewModel.start()),
            icon: const Icon(Icons.play_arrow),
            label: Text(
              data.inProgress ? l10n.continueAction : l10n.startAction,
            ),
          ),
        ],
      ],
    );
  }

  /// Opens the step [starting] resolves to and reports how it ended.
  Future<void> _open(
    BuildContext context,
    TodayViewModel viewModel,
    Future<TodayStepData?> starting,
  ) async {
    final step = await starting;
    if (step == null || !context.mounted) return;
    final finished = await context.push<bool>(locationOfStep(step));
    await viewModel.returnedFrom(step.id, finished: finished ?? false);
  }

  Future<void> _confirmSkip(
    BuildContext context,
    TodayViewModel viewModel,
    String id,
  ) async {
    final l10n = AppLocalizations.of(context);
    final skip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.skipTodayTitle),
        content: Text(l10n.skipTodayBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.skipToday),
          ),
        ],
      ),
    );
    if (skip == true) await viewModel.skip(id);
  }

  String _condition(AppLocalizations l10n, TodayCondition value) =>
      switch (value) {
        TodayCondition.firstDay => l10n.todayFirstDay,
        TodayCondition.normal => l10n.todayNormal,
        TodayCondition.returning => l10n.todayReturning,
        TodayCondition.completed => l10n.todayCompleted,
        TodayCondition.freeLimitReached => l10n.todayFreeLimit,
        TodayCondition.modelMissing => l10n.todayModelMissing,
      };

  String _title(AppLocalizations l10n, TodayStepData step) =>
      switch (step.kind) {
        TodayStepKind.diagnostic => l10n.stepDiagnostic,
        TodayStepKind.passage =>
          step.surah == null ? l10n.stepPassage : l10n.stepSurah(step.surah!),
        TodayStepKind.hardSpot => l10n.stepHardSpot,
        TodayStepKind.lesson => l10n.stepLesson,
        TodayStepKind.skill => l10n.stepSkill,
      };

  String _reason(AppLocalizations l10n, TodayStepReason value) =>
      switch (value) {
        TodayStepReason.returnDiagnosis => l10n.reasonReturnDiagnosis,
        TodayStepReason.yesterdayNew => l10n.reasonYesterdayNew,
        TodayStepReason.yesterdayError => l10n.reasonYesterdayError,
        TodayStepReason.recentDue => l10n.reasonRecentDue,
        TodayStepReason.longUnchecked => l10n.reasonLongUnchecked,
        TodayStepReason.newMaterial => l10n.reasonNewMaterial,
        TodayStepReason.courseLesson => l10n.reasonCourseLesson,
        TodayStepReason.skillDue => l10n.reasonSkillDue,
        TodayStepReason.userAdded => l10n.reasonUserAdded,
      };

  IconData _icon(TodayStepKind value) => switch (value) {
    TodayStepKind.diagnostic => Icons.health_and_safety_outlined,
    TodayStepKind.passage => Icons.menu_book_outlined,
    TodayStepKind.hardSpot => Icons.build_outlined,
    TodayStepKind.lesson => Icons.school_outlined,
    TodayStepKind.skill => Icons.extension_outlined,
  };
}

class _DayComplete extends StatelessWidget {
  const _DayComplete({
    required this.doneCount,
    required this.extraReview,
    required this.onReview,
  });
  final int doneCount;
  final List<TodayStepData> extraReview;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, size: AppIconSize.large),
            const SizedBox(height: AppSpacing.medium),
            Text(l10n.dayDone, style: Theme.of(context).textTheme.titleLarge),
            if (doneCount > 0) ...[
              const SizedBox(height: AppSpacing.small),
              Text(l10n.todaySummary(doneCount)),
            ],
            if (extraReview.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.medium),
              OutlinedButton(onPressed: onReview, child: Text(l10n.reviewMore)),
            ],
          ],
        ),
      ),
    );
  }
}
