import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/core/widgets/load_state_widgets.dart';
import 'package:sudur/ui/more/view_models/more_view_model.dart';
import 'package:sudur/ui/start/view_models/start_view_model.dart';

// Dialog callbacks keep the settings screen compact and readable.
// ignore_for_file: unnecessary_type_name_in_constructor
// ignore_for_file: curly_braces_in_flow_control_structures

/// Settings and data management screen from spec 13.14.
class MoreScreen extends StatelessWidget {
  /// Creates the screen.
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MoreViewModel>();
    final l10n = AppLocalizations.of(context);
    if (viewModel.loading && viewModel.settings == null)
      return const AppSkeleton();
    if (viewModel.error != null && viewModel.settings == null) {
      return AppErrorState(onRetry: viewModel.initialize);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      children: [
        _item(
          context,
          Icons.tune,
          l10n.activities,
          () => _activities(context, viewModel),
        ),
        _item(
          context,
          Icons.language,
          l10n.language,
          () => _language(context, viewModel),
        ),
        _item(
          context,
          Icons.download_outlined,
          l10n.downloads,
          () => _downloads(context, viewModel),
        ),
        _item(
          context,
          Icons.folder_outlined,
          l10n.myData,
          () => _data(context, viewModel),
        ),
        const Divider(),
        _soon(context, Icons.workspace_premium_outlined, l10n.subscription),
        ListTile(
          key: const ValueKey('more-reminders'),
          leading: const Icon(Icons.notifications_outlined),
          title: Text(l10n.reminders),
          onTap: () => GoRouter.of(context).push('/reminders'),
        ),
        _soon(context, Icons.science_outlined, l10n.improveChecking),
        _soon(context, Icons.bug_report_outlined, l10n.reportProblem),
        const Divider(),
        _item(
          context,
          Icons.info_outline,
          l10n.aboutApp,
          () => showAboutDialog(
            context: context,
            applicationName: l10n.appName,
            applicationVersion: '0.1.0',
          ),
        ),
        _item(
          context,
          Icons.description_outlined,
          l10n.sourcesLicenses,
          () =>
              showLicensePage(context: context, applicationName: l10n.appName),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );

  Widget _soon(BuildContext context, IconData icon, String title) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(AppLocalizations.of(context).comingSoon),
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
    ),
  );

  Future<void> _activities(
    BuildContext context,
    MoreViewModel viewModel,
  ) async {
    final current = viewModel.settings;
    if (current == null) return;
    var minutes = current.profile.dailyMinutes;
    var strict = current.profile.strictBehavior;
    var firstWord = current.profile.showFirstWord;
    var repeats = current.memorizationRepeats;
    final l10n = AppLocalizations.of(context);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.activities),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: minutes,
                  decoration: InputDecoration(labelText: l10n.dailyTime),
                  items: [5, 10, 20, 30]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(l10n.minutesCount(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => minutes = value ?? minutes),
                ),
                SwitchListTile(
                  value: strict,
                  title: Text(l10n.strictMode),
                  onChanged: (value) => setState(() => strict = value),
                ),
                SwitchListTile(
                  value: firstWord,
                  title: Text(l10n.showFirstWord),
                  onChanged: (value) => setState(() => firstWord = value),
                ),
                DropdownButtonFormField<int>(
                  initialValue: repeats,
                  decoration: InputDecoration(
                    labelText: l10n.memorizationRepeats,
                  ),
                  items: [1, 2, 3, 4, 5]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => repeats = value ?? repeats),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (save == true) {
      await viewModel.updateStudySettings(
        dailyMinutes: minutes,
        strictBehavior: strict,
        showFirstWord: firstWord,
        memorizationRepeats: repeats,
      );
    }
  }

  Future<void> _language(BuildContext context, MoreViewModel viewModel) async {
    final l10n = AppLocalizations.of(context);
    final labels = {
      AppLanguage.ru: l10n.languageRussian,
      AppLanguage.kk: l10n.languageKazakh,
      AppLanguage.uz: l10n.languageUzbek,
      AppLanguage.en: l10n.languageEnglish,
    };
    final value = await showDialog<AppLanguage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.chooseLanguage),
        children: [
          for (final entry in labels.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, entry.key),
              child: Text(entry.value),
            ),
        ],
      ),
    );
    if (value != null) await viewModel.updateLanguage(value);
  }

  Future<void> _downloads(BuildContext context, MoreViewModel viewModel) =>
      showDialog<void>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          final models = viewModel.downloads
              .where((item) => item.kind == 'model')
              .toList();
          return AlertDialog(
            title: Text(l10n.downloads),
            content: models.isEmpty
                ? Text(l10n.noModels)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final model in models)
                        ListTile(
                          title: Text(l10n.speechModel),
                          subtitle: Text(l10n.megabytes(model.bytes / 1048576)),
                        ),
                    ],
                  ),
            actions: [
              if (models.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await viewModel.deleteModels();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(l10n.deleteAction),
                ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      );

  Future<void> _data(BuildContext context, MoreViewModel viewModel) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final l10n = AppLocalizations.of(dialogContext);
          return SimpleDialog(
            title: Text(l10n.myData),
            children: [
              ListTile(
                leading: const Icon(Icons.upload),
                title: Text(l10n.exportData),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await viewModel.exportData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(l10n.importData),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await viewModel.importData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: Text(l10n.deleteAllData),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  final confirmed = await _confirmDelete(context);
                  if (confirmed && context.mounted) {
                    await viewModel.eraseAll();
                    if (context.mounted)
                      await context.read<StartViewModel>().initialize();
                  }
                },
              ),
            ],
          );
        },
      );

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.deleteAllData),
            content: Text(l10n.deleteAllDataWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.deleteAction),
              ),
            ],
          ),
        ) ??
        false;
  }
}
