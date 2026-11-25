import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/read/views/passage_view.dart';
import 'package:sudur/ui/self_check/view_models/self_check_view_model.dart';

/// Self-check (docs/tz 13.7). Returns `true` when the answer was written.
final class SelfCheckScreen extends StatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  State<SelfCheckScreen> createState() => _SelfCheckScreenState();
}

final class _SelfCheckScreenState extends State<SelfCheckScreen> {
  late final SelfCheckViewModel _viewModel = context.read<SelfCheckViewModel>();
  var _closed = false;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onChange);
  }

  void _onChange() {
    if (_viewModel.step == SelfCheckStep.done && !_closed && mounted) {
      _closed = true;
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final viewModel = _viewModel;
      final passage = viewModel.passage;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.selfTitle)),
        body: SafeArea(
          child: switch (viewModel.step) {
            SelfCheckStep.preparing || SelfCheckStep.done => const Center(
              child: CircularProgressIndicator(),
            ),
            SelfCheckStep.error => Center(child: Text(l10n.readFailed)),
            SelfCheckStep.recall when passage != null => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.selfPrompt(
                        passage.from.surah,
                        passage.from.ayah,
                        passage.to.ayah,
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    FilledButton(
                      key: const ValueKey('self-done'),
                      onPressed: viewModel.reveal,
                      child: Text(l10n.selfDone),
                    ),
                  ],
                ),
              ),
            ),
            SelfCheckStep.rate when passage != null => Column(
              children: [
                Expanded(
                  child: passage.pages == null
                      ? PassageTextView(passage: passage, states: const {})
                      : PassagePagesView(passage: passage, states: const {}),
                ),
                Text(
                  l10n.selfHowWasIt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Wrap(
                    spacing: AppSpacing.medium,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (answer, label) in [
                        (SelfCheckAnswer.remembered, l10n.selfRemembered),
                        (SelfCheckAnswer.withDifficulty, l10n.selfDifficulty),
                        (SelfCheckAnswer.forgotten, l10n.selfForgot),
                      ])
                        OutlinedButton(
                          key: ValueKey('self-${answer.name}'),
                          onPressed: () => viewModel.rate(answer),
                          child: Text(label),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      );
    },
  );
}
