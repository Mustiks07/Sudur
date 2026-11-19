import 'package:material_ui/material_ui.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';

// Keep the constructor spelling consistent with the rest of the application.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Calm placeholder shown only after the 300 ms loading threshold.
class AppSkeleton extends StatelessWidget {
  /// Creates a skeleton.
  const AppSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(AppSpacing.large),
    itemCount: 4,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.medium),
    itemBuilder: (_, index) => Container(
      height: index == 0 ? 32 : 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
    ),
  );
}

/// Recoverable, human-readable load error.
class AppErrorState extends StatelessWidget {
  /// Creates an error state.
  const AppErrorState({required this.onRetry, super.key});

  /// Retry callback.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: AppSpacing.medium),
            Text(l10n.loadError, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.medium),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
            TextButton(onPressed: () {}, child: Text(l10n.reportProblem)),
          ],
        ),
      ),
    );
  }
}
