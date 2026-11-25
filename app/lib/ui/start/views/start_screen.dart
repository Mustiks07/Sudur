import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/core/widgets/load_state_widgets.dart';
import 'package:sudur/ui/start/view_models/start_view_model.dart';

// Keep the constructor spelling consistent with the rest of the application.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Resumable first-run flow from spec 13.1.
class StartScreen extends StatelessWidget {
  /// Creates the screen.
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StartViewModel>();
    final l10n = AppLocalizations.of(context);
    if (viewModel.loading) {
      return Scaffold(
        body: viewModel.showSkeleton ? const AppSkeleton() : const SizedBox(),
      );
    }
    if (viewModel.error != null &&
        viewModel.draft.step == OnboardingStep.language) {
      return Scaffold(body: AppErrorState(onRetry: viewModel.initialize));
    }
    return Scaffold(
      appBar: AppBar(
        leading: viewModel.draft.step == OnboardingStep.language
            ? null
            : BackButton(onPressed: viewModel.back),
        title: Text(l10n.startTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value:
                    (viewModel.draft.step.index + 1) /
                    (OnboardingStep.values.length - 1),
              ),
              const SizedBox(height: AppSpacing.large),
              if (viewModel.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: Text(
                    viewModel.draft.step == OnboardingStep.model
                        ? l10n.networkError
                        : l10n.loadError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Expanded(child: _step(context, viewModel, l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(
    BuildContext context,
    StartViewModel viewModel,
    AppLocalizations l10n,
  ) => switch (viewModel.draft.step) {
    OnboardingStep.language => _ChoiceStep(
      title: l10n.chooseLanguage,
      choices: [
        (l10n.languageRussian, () => viewModel.chooseLanguage(AppLanguage.ru)),
        (l10n.languageKazakh, () => viewModel.chooseLanguage(AppLanguage.kk)),
        (l10n.languageUzbek, () => viewModel.chooseLanguage(AppLanguage.uz)),
        (l10n.languageEnglish, () => viewModel.chooseLanguage(AppLanguage.en)),
      ],
    ),
    OnboardingStep.path => _ChoiceStep(
      title: l10n.choosePath,
      choices: [
        (
          l10n.pathLearnReading,
          () => viewModel.choosePath(AppLearningPath.learnReading),
        ),
        (
          l10n.pathMemorize,
          () => viewModel.choosePath(AppLearningPath.memorize),
        ),
        (l10n.pathRestore, () => viewModel.choosePath(AppLearningPath.restore)),
      ],
    ),
    OnboardingStep.familiarSurahs => _SurahStep(viewModel: viewModel),
    OnboardingStep.dailyTime => _TimeStep(viewModel: viewModel),
    OnboardingStep.model => _ModelStep(viewModel: viewModel),
    OnboardingStep.startPoint => _ChoiceStep(
      title: l10n.chooseStartPoint,
      choices: [
        (
          l10n.startFirstSurah,
          () => viewModel.chooseStartPoint(AppStartPoint.firstSurah),
        ),
        (
          l10n.startShortSurahs,
          () => viewModel.chooseStartPoint(AppStartPoint.shortSurahs),
        ),
      ],
    ),
    OnboardingStep.letters => _ChoiceStep(
      title: l10n.knowLetters,
      choices: [
        (l10n.lettersNo, () => viewModel.chooseLetters(LetterKnowledge.no)),
        (
          l10n.lettersALittle,
          () => viewModel.chooseLetters(LetterKnowledge.aLittle),
        ),
      ],
    ),
    OnboardingStep.completed => const Center(
      child: CircularProgressIndicator(),
    ),
  };
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({required this.title, required this.choices});

  final String title;
  final List<(String, VoidCallback)> choices;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.large),
      for (final choice in choices)
        Card(
          child: ListTile(
            minTileHeight: 72,
            title: Text(choice.$1),
            trailing: const Icon(Icons.arrow_forward),
            onTap: choice.$2,
          ),
        ),
    ],
  );
}

class _SurahStep extends StatelessWidget {
  const _SurahStep({required this.viewModel});
  final StartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.chooseFamiliarSurahs,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.medium),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.searchSurah,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: viewModel.searchSurah,
        ),
        const SizedBox(height: AppSpacing.small),
        Expanded(
          child: ListView(
            children: [
              for (final number in viewModel.visibleSurahs)
                CheckboxListTile(
                  value: viewModel.draft.familiarSurahs.contains(number),
                  title: Text(l10n.surahNumber(number)),
                  subtitle: switch (viewModel.surahName(number)) {
                    final String name => Text(name),
                    null => null,
                  },
                  onChanged: (_) => viewModel.toggleSurah(number),
                ),
            ],
          ),
        ),
        FilledButton(
          onPressed: viewModel.finishSurahs,
          child: Text(
            viewModel.draft.familiarSurahs.isEmpty
                ? l10n.skip
                : l10n.continueAction,
          ),
        ),
      ],
    );
  }
}

class _TimeStep extends StatelessWidget {
  const _TimeStep({required this.viewModel});
  final StartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ChoiceStep(
      title: l10n.chooseDailyTime,
      choices: [
        for (final minutes in const [5, 10, 20])
          (l10n.minutesCount(minutes), () => viewModel.chooseMinutes(minutes)),
        (l10n.customTime, () => _custom(context)),
      ],
    );
  }

  Future<void> _custom(BuildContext context) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.customTime),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.minutes),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: Text(l10n.continueAction),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await viewModel.chooseMinutes(value);
  }
}

class _ModelStep extends StatelessWidget {
  const _ModelStep({required this.viewModel});
  final StartViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (viewModel.downloading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LinearProgressIndicator(value: viewModel.downloadProgress),
          const SizedBox(height: AppSpacing.medium),
          Text(l10n.modelDownloading),
        ],
      );
    }
    return _ChoiceStep(
      title: l10n.modelTitle,
      choices: [
        (l10n.downloadModel, () => viewModel.chooseModel(downloadNow: true)),
        (l10n.downloadLater, () => viewModel.chooseModel(downloadNow: false)),
      ],
    );
  }
}
