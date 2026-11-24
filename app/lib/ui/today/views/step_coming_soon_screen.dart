import 'package:material_ui/material_ui.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';

/// Opened for a step of “Today” whose screen is not built yet (a lesson
/// before Q12). Returns `false`: the step stays not done.
final class StepComingSoonScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty, size: AppIconSize.large),
              const SizedBox(height: AppSpacing.medium),
              Text(l10n.stepComingSoon, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.large),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
