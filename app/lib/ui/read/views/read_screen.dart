import 'package:contracts/contracts.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';
import 'package:sudur/ui/read/view_models/read_view_model.dart';

// The class names keep the screen easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor

/// The reading screen (docs/tz 13.3) and, after «Закончить», «Разбор»
/// (13.4). Returns `true` to “Today” with «Дальше» after the passage was
/// read and written, `false` when it was left.
final class ReadScreen extends StatefulWidget {
  /// Creates the screen.
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

final class _ReadScreenState extends State<ReadScreen> {
  late final ReadViewModel _viewModel = context.read<ReadViewModel>();

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final passage = viewModel.passage;
        return Scaffold(
          appBar: AppBar(
            title: passage == null
                ? null
                : Text(
                    l10n.readTitle(
                      passage.from.surah,
                      passage.from.ayah,
                      passage.to.ayah,
                    ),
                  ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: _SoundDot(viewModel.sound),
              ),
            ],
          ),
          body: SafeArea(
            child: switch (viewModel.state) {
              ReadState.preparing => _Message(
                text: l10n.readPreparing,
                busy: true,
              ),
              ReadState.error => _ErrorBody(viewModel: viewModel),
              ReadState.finishing => _Message(
                text: l10n.readSaving,
                busy: true,
              ),
              ReadState.finished => _ReviewBody(viewModel: viewModel),
              _ => _ReadingBody(viewModel: viewModel),
            },
          ),
        );
      },
    );
  }
}

final class _SoundDot extends StatelessWidget {
  const new(this.sound);

  final SoundIndicator sound;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey('read-sound-${sound.name}'),
      width: AppSpacing.medium,
      height: AppSpacing.medium,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (sound) {
          SoundIndicator.hearing => Colors.green,
          SoundIndicator.silence => colors.outline,
          SoundIndicator.poor => Colors.amber,
        },
      ),
    );
  }
}

final class _Message extends StatelessWidget {
  const new({required this.text, this.busy = false});

  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy) const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.medium),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

final class _ErrorBody extends StatelessWidget {
  const new({required this.viewModel});

  final ReadViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void leave() => Navigator.of(context).pop(false);
    final (text, actions) = switch (viewModel.error) {
      ReadError.micDenied => (
        l10n.readMicDenied,
        [
          FilledButton(
            key: const ValueKey('read-open-settings'),
            onPressed: viewModel.openSettings,
            child: Text(l10n.readOpenSettings),
          ),
          OutlinedButton(onPressed: leave, child: Text(l10n.readWithoutMic)),
        ],
      ),
      ReadError.modelMissing => (
        l10n.readModelMissing,
        [
          FilledButton(
            key: const ValueKey('read-download'),
            onPressed: viewModel.downloadProgress == null
                ? viewModel.downloadModel
                : null,
            child: Text(l10n.readDownload),
          ),
          OutlinedButton(onPressed: leave, child: Text(l10n.readWithoutVoice)),
        ],
      ),
      ReadError.deviceTooSlow => (
        l10n.readDeviceTooSlow,
        [OutlinedButton(onPressed: leave, child: Text(l10n.back))],
      ),
      ReadError.network => (
        l10n.networkError,
        [OutlinedButton(onPressed: leave, child: Text(l10n.back))],
      ),
      ReadError.other || null => (
        l10n.readFailed,
        [OutlinedButton(onPressed: leave, child: Text(l10n.back))],
      ),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (viewModel.downloadProgress case final progress?) ...[
              const SizedBox(height: AppSpacing.medium),
              LinearProgressIndicator(value: progress),
            ],
            const SizedBox(height: AppSpacing.large),
            Wrap(
              spacing: AppSpacing.medium,
              alignment: WrapAlignment.center,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ReadingBody extends StatelessWidget {
  const new({required this.viewModel});

  final ReadViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final passage = viewModel.passage;
    if (passage == null) return const SizedBox.shrink();
    final ready = viewModel.state == ReadState.ready;
    return Stack(
      children: [
        Column(
          children: [
            if (ready) _Options(viewModel: viewModel),
            Expanded(
              child: passage.pages == null
                  ? _TextView(passage: passage, states: viewModel.wordStates)
                  : _PagesView(passage: passage, states: viewModel.wordStates),
            ),
            _Banners(viewModel: viewModel),
            _Controls(viewModel: viewModel),
          ],
        ),
        if (viewModel.state == ReadState.paused)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: .6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.readPaused,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    FilledButton(
                      onPressed: viewModel.resume,
                      child: Text(l10n.readResume),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _Options extends StatelessWidget {
  const new({required this.viewModel});

  final ReadViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.small),
      child: Column(
        children: [
          SegmentedButton<ReadMode>(
            key: const ValueKey('read-mode'),
            segments: [
              ButtonSegment(
                value: ReadMode.supported,
                label: Text(l10n.readModeSupported),
              ),
              ButtonSegment(
                value: ReadMode.recall,
                label: Text(l10n.readModeRecall),
              ),
              ButtonSegment(
                value: ReadMode.test,
                label: Text(l10n.readModeTest),
              ),
            ],
            selected: {viewModel.mode},
            onSelectionChanged: (value) => viewModel.setMode(value.first),
          ),
          Wrap(
            spacing: AppSpacing.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Toggle(
                label: l10n.readStrict,
                value: viewModel.strict,
                onChanged: (v) => viewModel.setStrict(value: v),
              ),
              if (viewModel.mode != ReadMode.supported)
                _Toggle(
                  label: l10n.readShowFirstWord,
                  value: viewModel.showFirstWord,
                  onChanged: (v) => viewModel.setShowFirstWord(value: v),
                ),
            ],
          ),
          Text(
            l10n.readChecksNotice,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

final class _Toggle extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Switch(value: value, onChanged: onChanged),
      Text(label),
    ],
  );
}

/// Temporary plain text view from the canon, for places without page
/// layout (ADR 0002): words in reading order, hidden ones drawn with a
/// transparent colour so nothing moves when they appear.
final class _TextView extends StatelessWidget {
  const new({required this.passage, required this.states});

  final ReadingPassage passage;
  final Map<WordKey, MushafWordState> states;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      key: const ValueKey('read-text-view'),
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Text(
          l10n.readTextView,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.medium),
        for (final ayah in passage.ayahs)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.medium),
            child: Wrap(
              textDirection: TextDirection.rtl,
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                for (final word in ayah.words)
                  Text(
                    word.text,
                    key: ValueKey('read-word-${word.key}'),
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: _colorOf(theme.colorScheme, states[word.key]),
                      decoration: states[word.key] == MushafWordState.current
                          ? TextDecoration.underline
                          : null,
                    ),
                  ),
                Text(
                  '(${ayah.ayah})',
                  style: theme.textTheme.bodyMedium,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Color _colorOf(ColorScheme colors, MushafWordState? state) =>
      switch (state) {
        MushafWordState.hidden => Colors.transparent,
        MushafWordState.current => colors.primary,
        MushafWordState.possibleError => colors.tertiary,
        MushafWordState.error => colors.error,
        MushafWordState.corrected => colors.secondary,
        MushafWordState.notHeard => colors.outline,
        MushafWordState.revealedByHint => colors.secondary,
        MushafWordState.correct ||
        MushafWordState.normal ||
        null => colors.onSurface,
      };
}

final class _PagesView extends StatelessWidget {
  const new({required this.passage, required this.states});

  final ReadingPassage passage;
  final Map<WordKey, MushafWordState> states;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Checked by the caller: this view is used only with pages.
    final pages = passage.pages!;
    // Words outside the passage stay visible on its pages.
    final keys = <WordKey>[
      for (final page in pages)
        for (final line in page.lines)
          for (final fragment in line.fragments) ?fragment.wordKey,
    ];
    final shown = <WordKey, MushafWordState>{
      for (final key in keys) key: states[key] ?? MushafWordState.normal,
    };
    final first = pages.indexWhere(
      (page) => page.lines.any(
        (line) => line.fragments.any((f) => f.wordKey == passage.from),
      ),
    );
    return PageView(
      controller: PageController(initialPage: first < 0 ? 0 : first),
      children: [
        for (final page in pages)
          RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
              ),
              child: MushafPage(
                data: page,
                fontFamily: passage.fontFamilies[page.pageNumber] ?? '',
                wordStates: shown,
                semanticsLabelBuilder: (ayah) => l10n.mushafAyahSemantics(
                  ayah.surah,
                  ayah.ayah,
                  ayah.canonicalText,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _Banners extends StatelessWidget {
  const new({required this.viewModel});

  final ReadViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (viewModel.strictWord != null)
          Text(l10n.readStrictAgain, key: const ValueKey('read-strict-again')),
        if (viewModel.offerHint)
          TextButton(
            key: const ValueKey('read-offer-hint'),
            onPressed: viewModel.hint,
            child: Text(l10n.readOfferHint),
          ),
        if (viewModel.stuckWord != null)
          OutlinedButton(
            key: const ValueKey('read-unlock'),
            onPressed: viewModel.unlockStuckWord,
            child: Text(l10n.readUnlock),
          ),
      ],
    );
  }
}

final class _Controls extends StatelessWidget {
  const new({required this.viewModel});

  final ReadViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = viewModel.state;
    if (state == ReadState.ready || state == ReadState.starting) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          children: [
            Text(l10n.readReady),
            const SizedBox(height: AppSpacing.small),
            FilledButton.icon(
              key: const ValueKey('read-start'),
              onPressed: state == ReadState.ready ? viewModel.start : null,
              icon: const Icon(Icons.mic),
              label: Text(l10n.readStart),
            ),
          ],
        ),
      );
    }
    final listening = state == ReadState.listening;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Wrap(
        spacing: AppSpacing.medium,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('read-hint'),
            onPressed: listening ? viewModel.hint : null,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(l10n.readHint),
          ),
          OutlinedButton.icon(
            onPressed: listening ? viewModel.pause : null,
            icon: const Icon(Icons.pause),
            label: Text(l10n.readPause),
          ),
          FilledButton.icon(
            key: const ValueKey('read-finish'),
            onPressed: viewModel.finish,
            icon: const Icon(Icons.stop),
            label: Text(l10n.readFinish),
          ),
        ],
      ),
    );
  }
}

/// «Разбор» (13.4, РБ-01…05): summary, marked words, events and actions.
final class _ReviewBody extends StatelessWidget {
  const new({required this.viewModel});

  final ReadViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final passage = viewModel.passage;
    final summary = viewModel.summary;
    final checks = viewModel.reviewChecks;
    return Column(
      key: const ValueKey('review'),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            children: [
              Text(l10n.reviewTitle, style: theme.textTheme.titleLarge),
              if (viewModel.clean)
                Text(
                  l10n.reviewClean,
                  key: const ValueKey('review-clean'),
                  style: theme.textTheme.titleMedium,
                ),
              Wrap(
                spacing: AppSpacing.medium,
                alignment: WrapAlignment.center,
                children: [
                  Text(l10n.reviewIndependent(summary.independent)),
                  Text(l10n.reviewWithHints(summary.withHints)),
                  Text(l10n.reviewErrors(summary.errors)),
                  Text(l10n.reviewUnverified(summary.unverified)),
                ],
              ),
            ],
          ),
        ),
        if (passage != null)
          Expanded(
            flex: 3,
            child: passage.pages == null
                ? _TextView(passage: passage, states: viewModel.wordStates)
                : _PagesView(passage: passage, states: viewModel.wordStates),
          ),
        Wrap(
          spacing: AppSpacing.small,
          children: [
            for (final filter in ReviewFilter.values)
              ChoiceChip(
                label: Text(switch (filter) {
                  ReviewFilter.all => l10n.reviewFilterAll,
                  ReviewFilter.errors => l10n.reviewFilterErrors,
                  ReviewFilter.corrections => l10n.reviewFilterCorrections,
                  ReviewFilter.unverified => l10n.reviewFilterUnverified,
                }),
                selected: viewModel.reviewFilter == filter,
                onSelected: (_) => viewModel.setReviewFilter(filter),
              ),
          ],
        ),
        Expanded(
          flex: 2,
          child: checks.isEmpty
              ? Center(child: Text(l10n.reviewNoEvents))
              : ListView(
                  key: const ValueKey('review-events'),
                  children: [
                    for (final check in checks)
                      _ReviewEvent(viewModel: viewModel, check: check),
                  ],
                ),
        ),
        TextButton.icon(
          key: const ValueKey('review-share'),
          onPressed: () => viewModel.shareSummary(
            l10n.reviewShareText(
              passage?.from.surah ?? 0,
              passage?.from.ayah ?? 0,
              passage?.to.ayah ?? 0,
              summary.independent,
              summary.withHints,
              summary.errors,
              summary.unverified,
            ),
          ),
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.reviewShare),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: FilledButton(
            key: const ValueKey('review-next'),
            onPressed: () {
              viewModel.closeReview();
              Navigator.of(context).pop(true);
            },
            child: Text(l10n.reviewNext),
          ),
        ),
      ],
    );
  }
}

final class _ReviewEvent extends StatelessWidget {
  const new({required this.viewModel, required this.check});

  final ReadViewModel viewModel;
  final CheckEvent check;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kind = switch (check.kind) {
      CheckKind.omission => l10n.reviewKindOmission,
      CheckKind.substitution => l10n.reviewKindSubstitution,
      CheckKind.insertion => l10n.reviewKindInsertion,
      CheckKind.jump => l10n.reviewKindJump,
      CheckKind.repetition => l10n.reviewKindRepetition,
      CheckKind.hesitation => l10n.reviewKindHesitation,
    };
    final state = switch (check.state) {
      CheckState.preliminary => l10n.reviewStatePreliminary,
      CheckState.confirmed => l10n.reviewStateConfirmed,
      CheckState.corrected => l10n.reviewStateCorrected,
      CheckState.unverified => l10n.reviewStateUnverified,
      CheckState.disputed => l10n.reviewStateDisputed,
    };
    final place = check.words.isEmpty ? '' : '${check.words.first} · ';
    return ExpansionTile(
      key: ValueKey('review-event-${check.eventId}'),
      title: Text('$place$kind · $state'),
      children: [
        Wrap(
          spacing: AppSpacing.small,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              key: ValueKey('review-listen-${check.eventId}'),
              onPressed: viewModel.canListenToSelf(check.eventId)
                  ? () => viewModel.listenToSelf(check.eventId)
                  : null,
              child: Text(l10n.reviewListenSelf),
            ),
            Tooltip(
              message: l10n.reviewAudioSoon,
              child: OutlinedButton(
                onPressed: null,
                child: Text(l10n.reviewListenReciter),
              ),
            ),
            if (check.state != CheckState.disputed)
              OutlinedButton(
                key: ValueKey('review-dispute-${check.eventId}'),
                onPressed: () => viewModel.dispute(check.eventId),
                child: Text(l10n.reviewDispute),
              ),
            OutlinedButton(
              key: ValueKey('review-practice-${check.eventId}'),
              // The exercise screen comes with Q10.
              onPressed: () => GoRouter.of(context).push('/soon'),
              child: Text(l10n.reviewPractice),
            ),
          ],
        ),
      ],
    );
  }
}
