import 'package:material_ui/material_ui.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';

/// Placeholder displayed until a feature screen is implemented.
class SectionPlaceholder extends StatelessWidget {
  /// Creates a section placeholder.
  const new({required this.icon, required this.title, super.key});

  /// Icon associated with the destination.
  final IconData icon;

  /// Localized destination title.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.large),
            const SizedBox(height: AppSpacing.medium),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.small),
            Text(
              AppLocalizations.of(context).sectionComingSoon,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
