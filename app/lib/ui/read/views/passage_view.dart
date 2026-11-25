import 'package:contracts/contracts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';

// Views of a passage shared by reading, review and self-check.

/// Temporary plain text view from the canon, for places without page
/// layout (ADR 0002): words in reading order, hidden ones drawn with a
/// transparent colour so nothing moves when they appear.
final class PassageTextView extends StatelessWidget {
  /// Creates the view.
  const new({required this.passage, required this.states, super.key});

  /// The passage.

  final ReadingPassage passage;

  /// State of each word; a word without one is drawn normally.
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

/// The passage on its mushaf pages; words outside it stay visible.
final class PassagePagesView extends StatelessWidget {
  /// Creates the view.
  const new({required this.passage, required this.states, super.key});

  /// The passage.

  final ReadingPassage passage;

  /// State of each word; a word without one is drawn normally.
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
