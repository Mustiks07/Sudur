import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/routing/app_router.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/progress/view_models/progress_view_model.dart';

/// Colour and icon of a memory state (11.1).
(Color, IconData) memoryLook(ColorScheme colors, MemoryStatus status) =>
    switch (status) {
      MemoryStatus.notStarted => (
        colors.surfaceContainerHighest,
        Icons.circle_outlined,
      ),
      MemoryStatus.introduced => (colors.outline, Icons.visibility_outlined),
      MemoryStatus.withHelp => (colors.tertiary, Icons.lightbulb_outline),
      MemoryStatus.independent => (colors.primary, Icons.check),
      MemoryStatus.confirmed => (colors.primary, Icons.done_all),
      MemoryStatus.stale => (colors.secondary, Icons.history),
      MemoryStatus.hardSpot => (colors.error, Icons.build_outlined),
    };

/// Name of a memory state.
String memoryLabel(AppLocalizations l10n, MemoryStatus status) =>
    switch (status) {
      MemoryStatus.notStarted => l10n.memoryNotStarted,
      MemoryStatus.introduced => l10n.memoryIntroduced,
      MemoryStatus.withHelp => l10n.memoryWithHelp,
      MemoryStatus.independent => l10n.memoryIndependent,
      MemoryStatus.confirmed => l10n.memoryConfirmed,
      MemoryStatus.stale => l10n.memoryStale,
      MemoryStatus.hardSpot => l10n.memoryHardSpot,
    };

/// «Прогресс»: the grid of surahs with a legend, no overall percent.
final class ProgressScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ProgressViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final colors = Theme.of(context).colorScheme;
        final surahs = viewModel.surahs;
        if (viewModel.failed) return Center(child: Text(l10n.readFailed));
        if (surahs == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return CustomScrollView(
          key: const ValueKey('progress'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: AppSpacing.medium,
                  runSpacing: AppSpacing.small,
                  children: [
                    for (final status in MemoryStatus.values)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            memoryLook(colors, status).$2,
                            color: memoryLook(colors, status).$1,
                            size: AppSpacing.large,
                          ),
                          Text(memoryLabel(l10n, status)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 64,
                  mainAxisSpacing: AppSpacing.small,
                  crossAxisSpacing: AppSpacing.small,
                ),
                itemCount: 114,
                itemBuilder: (context, i) {
                  final number = i + 1;
                  final surah = viewModel.surah(number);
                  final status = surah?.status ?? MemoryStatus.notStarted;
                  final (color, icon) = memoryLook(colors, status);
                  return InkWell(
                    key: ValueKey('progress-surah-$number'),
                    onTap: surah == null
                        ? null
                        : () => unawaited(
                            GoRouter.of(context)
                                .push('/progress/surah', extra: number),
                          ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$number'),
                          Icon(icon, color: color, size: AppSpacing.large),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A surah (КП-04): passages, last check and its way, hints, hard spots.
final class SurahProgressScreen extends StatelessWidget {
  /// Creates the screen for [surah].
  const new({required this.surah, super.key});

  /// Surah number.
  final int surah;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ProgressViewModel>();
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final data = viewModel.surah(surah);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.surahNumber(surah))),
      body: data == null
          ? const SizedBox.shrink()
          : ListView(
              children: [
                for (final passage in data.passages)
                  ListTile(
                    key: ValueKey('passage-${passage.unitId}'),
                    leading: Icon(
                      memoryLook(colors, passage.status).$2,
                      color: memoryLook(colors, passage.status).$1,
                    ),
                    title: Text(
                      '${passage.from} – ${passage.to} · '
                      '${memoryLabel(l10n, passage.status)}',
                    ),
                    subtitle: Text(
                      [
                        if (passage.lastCheckAt case final at?)
                          l10n.progressLastCheck(
                            MaterialLocalizations.of(context)
                                .formatShortDate(at.toLocal()),
                            switch (passage.lastMethod) {
                              LastCheckMethod.voice => l10n.methodVoice,
                              LastCheckMethod.self => l10n.methodSelf,
                              LastCheckMethod.listener ||
                              null => l10n.methodListener,
                            },
                          ),
                        l10n.progressHints(passage.hints),
                        if (passage.hardSpots > 0)
                          l10n.progressHardSpots(passage.hardSpots),
                      ].join(' · '),
                    ),
                    trailing: TextButton(
                      onPressed: () => unawaited(
                        GoRouter.of(context).push(
                          selfCheckLocation(
                            passage.from,
                            passage.to,
                            path: '/read',
                          ),
                        ),
                      ),
                      child: Text(l10n.progressRepeatNow),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Reminders (11.8): up to two times a day, removing all turns them off.
final class RemindersScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<RemindersViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final text = l10n.reminderText;
        String format(int minutes) => MaterialLocalizations.of(
          context,
        ).formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
        return Scaffold(
          appBar: AppBar(title: Text(l10n.reminders)),
          body: ListView(
            children: [
              if (viewModel.times.isEmpty)
                ListTile(title: Text(l10n.remindersOff)),
              for (final time in viewModel.times)
                ListTile(
                  title: Text(format(time)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => viewModel.remove(time, text),
                  ),
                ),
              if (viewModel.canAdd)
                ListTile(
                  key: const ValueKey('reminder-add'),
                  leading: const Icon(Icons.add_alarm),
                  title: Text(l10n.reminderAdd),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null) {
                      await viewModel.add(
                        picked.hour * 60 + picked.minute,
                        text,
                      );
                    }
                  },
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Text(
                  l10n.remindersNotYet,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
