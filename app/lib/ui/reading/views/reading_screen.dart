import 'dart:async';

import 'package:contracts/contracts.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/reading/view_models/reading_view_model.dart';

/// Standalone surah 78 reading and measurement prototype.
final class ReadingScreen extends StatefulWidget {
  /// Creates the reading screen; [from]–[to] and [stepId] when it reads a
  /// step of “Today”.
  const new({super.key, this.from, this.to, this.stepId});

  /// First word of today's step, or `null` for the whole prototype passage.
  final WordKey? from;

  /// Last word of today's step.
  final WordKey? to;

  /// Step of “Today” being read: when it is set, a finished reading offers
  /// «Готово», which returns `true` to “Today”.
  final String? stepId;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

final class _ReadingScreenState extends State<ReadingScreen> {
  final Map<int, MushafPageController> _pageControllers =
      <int, MushafPageController>{};

  @override
  void initState() {
    super.initState();
    unawaited(
      context.read<ReadingViewModel>().useRange(widget.from, widget.to),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ReadingViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final localizations = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(localizations.prototypeTitle)),
          body: SafeArea(
            child: switch (viewModel.state) {
              ReadingPrototypeState.preparing => _PreparingBody(
                viewModel: viewModel,
              ),
              ReadingPrototypeState.error => _ErrorBody(viewModel: viewModel),
              ReadingPrototypeState.rangeUnavailable =>
                const _UnavailableBody(),
              _ => _ReadyBody(
                viewModel: viewModel,
                onDone: widget.stepId == null
                    ? null
                    : () => Navigator.of(context).pop(true),
                pageControllers: _pageControllers,
              ),
            },
          ),
        );
      },
    );
  }
}

final class _PreparingBody extends StatelessWidget {
  const new({required this.viewModel});

  final ReadingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final progress = viewModel.progress;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                localizations.prototypePreparing,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress?.fraction),
              const SizedBox(height: 12),
              if (progress != null)
                Text(
                  localizations.prototypeDownloadProgress(
                    progress.resourceName,
                    (progress.fraction * 100).round(),
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ErrorBody extends StatelessWidget {
  const new({required this.viewModel});

  final ReadingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(localizations.prototypeError, textAlign: TextAlign.center),
            if (viewModel.error case final error?) ...<Widget>[
              const SizedBox(height: 8),
              SelectableText(error.toString(), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: viewModel.retry,
              icon: const Icon(Icons.refresh),
              label: Text(localizations.prototypeRetry),
            ),
          ],
        ),
      ),
    );
  }
}

final class _UnavailableBody extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.menu_book_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              localizations.readingRangeUnavailable,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.back),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ReadyBody extends StatelessWidget {
  const new({
    required this.viewModel,
    required this.pageControllers,
    required this.onDone,
  });

  final ReadingViewModel viewModel;
  final VoidCallback? onDone;
  final Map<int, MushafPageController> pageControllers;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                localizations.prototypeMockNotice,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _ModelSelector(viewModel: viewModel),
                  OutlinedButton.icon(
                    onPressed: viewModel.isBenchmarking
                        ? null
                        : viewModel.runDeviceTest,
                    icon: const Icon(Icons.speed),
                    label: Text(
                      viewModel.isBenchmarking
                          ? localizations.prototypePhoneTesting
                          : localizations.prototypePhoneTest,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: viewModel.chooseWav,
                    icon: const Icon(Icons.audio_file),
                    label: Text(localizations.prototypeChooseWav),
                  ),
                  if (viewModel.selectedWavName != null)
                    TextButton(
                      onPressed: viewModel.useMicrophone,
                      child: Text(localizations.prototypeUseMicrophone),
                    ),
                ],
              ),
              if (viewModel.selectedWavName case final fileName?)
                Text(localizations.prototypeWavSelected(fileName)),
              if (viewModel.benchmarkResult case final result?)
                Text(
                  localizations.prototypePhoneResult(
                    result.speedRatio.toStringAsFixed(2),
                    result.decodeMs,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            itemCount: viewModel.pages.length,
            itemBuilder: (context, index) {
              final page = viewModel.pages[index];
              final controller = pageControllers.putIfAbsent(
                page.pageNumber,
                MushafPageController.new,
              );
              viewModel.beginPageRender(page.pageNumber);
              SchedulerBinding.instance.addPostFrameCallback(
                (_) => viewModel.markPageRendered(page.pageNumber),
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MushafPage(
                  key: ValueKey<String>('prototype-page-${page.pageNumber}'),
                  data: page,
                  fontFamily:
                      viewModel.fontFamilyForPage(page.pageNumber) ??
                      'sans-serif',
                  controller: controller,
                  wordStates: viewModel.wordStates,
                  semanticsLabelBuilder: (ayah) =>
                      localizations.mushafAyahSemantics(
                        ayah.surah,
                        ayah.ayah,
                        ayah.canonicalText,
                      ),
                ),
              );
            },
          ),
        ),
        _SessionControls(viewModel: viewModel, onDone: onDone),
      ],
    );
  }
}

final class _ModelSelector extends StatelessWidget {
  const new({required this.viewModel});

  final ReadingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final selector = DropdownButton<PrototypeModelChoice>(
      key: const ValueKey<String>('prototype-model-selector'),
      value: viewModel.selectedModel,
      onChanged: viewModel.canSelectModel
          ? (value) {
              if (value != null) unawaited(viewModel.selectModel(value));
            }
          : null,
      items: <DropdownMenuItem<PrototypeModelChoice>>[
        DropdownMenuItem<PrototypeModelChoice>(
          value: PrototypeModelChoice.small,
          child: Text(localizations.prototypeModelSmall),
        ),
        DropdownMenuItem<PrototypeModelChoice>(
          value: PrototypeModelChoice.tiny,
          child: Text(localizations.prototypeModelTiny),
        ),
      ],
    );
    if (viewModel.canSelectModel) return selector;
    return Tooltip(
      message: localizations.prototypeFinishReadingFirst,
      triggerMode: TooltipTriggerMode.tap,
      child: selector,
    );
  }
}

final class _SessionControls extends StatelessWidget {
  const new({required this.viewModel, required this.onDone});

  final ReadingViewModel viewModel;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          if (onDone case final done?
              when viewModel.state == ReadingPrototypeState.finished)
            FilledButton.icon(
              key: const ValueKey('reading-done'),
              onPressed: done,
              icon: const Icon(Icons.check),
              label: Text(localizations.readingDone),
            ),
          FilledButton.icon(
            onPressed: switch (viewModel.state) {
              ReadingPrototypeState.ready ||
              ReadingPrototypeState.finished => viewModel.start,
              ReadingPrototypeState.paused => viewModel.resume,
              _ => null,
            },
            icon: Icon(
              viewModel.state == ReadingPrototypeState.paused
                  ? Icons.play_arrow
                  : Icons.mic,
            ),
            label: Text(
              viewModel.state == ReadingPrototypeState.paused
                  ? localizations.prototypeResume
                  : localizations.prototypeStart,
            ),
          ),
          OutlinedButton.icon(
            onPressed: viewModel.canPause ? viewModel.pause : null,
            icon: const Icon(Icons.pause),
            label: Text(localizations.prototypePause),
          ),
          OutlinedButton.icon(
            onPressed:
                viewModel.state == ReadingPrototypeState.running ||
                    viewModel.state == ReadingPrototypeState.paused
                ? viewModel.stop
                : null,
            icon: const Icon(Icons.stop),
            label: Text(localizations.prototypeStop),
          ),
          OutlinedButton.icon(
            onPressed: viewModel.requestHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(localizations.prototypeHint),
          ),
          OutlinedButton.icon(
            onPressed: viewModel.shareLog,
            icon: const Icon(Icons.share),
            label: Text(localizations.prototypeShareLog),
          ),
        ],
      ),
    );
  }
}
