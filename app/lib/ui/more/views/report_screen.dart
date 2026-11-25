import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/more/view_models/report_view_model.dart';

/// «Сообщить о проблеме» (13.14): the system share sheet sends the report to
/// Telegram, mail or any other app the person chooses.
final class ReportScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ReportViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.reportProblem)),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.large),
            children: [
              Text(l10n.reportExplain),
              SwitchListTile(
                key: const ValueKey('report-diagnostics'),
                value: viewModel.withDiagnostics,
                onChanged: (v) => viewModel.setWithDiagnostics(value: v),
                title: Text(l10n.reportAttach),
                subtitle: Text(l10n.reportAttachNote),
              ),
              if (viewModel.failed) Text(l10n.loadError),
              const SizedBox(height: AppSpacing.medium),
              FilledButton(
                key: const ValueKey('report-send'),
                onPressed: viewModel.send,
                child: Text(l10n.reportSend),
              ),
            ],
          ),
        );
      },
    );
  }
}
