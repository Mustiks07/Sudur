import 'dart:async';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:provider/provider.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/prototype/view_models/prototype_view_model.dart';

/// Dev prototype for recall and reproducible owner measurements.
class PrototypeScreen extends StatefulWidget {
  /// Creates the prototype screen.
  const new({super.key});
  @override
  State<PrototypeScreen> createState() => _PrototypeScreenState();
}

class _PrototypeScreenState extends State<PrototypeScreen>
    with WidgetsBindingObserver {
  late PrototypeViewModel _model;
  Object? _lastFonts;
  @override
  void initState() {
    super.initState();
    _model = context.read<PrototypeViewModel>();
    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance.addTimingsCallback(_timings);
    unawaited(_model.prepare());
  }

  void _timings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _model.repository.trace.add(
        'frame',
        durationUs: timing.totalSpan.inMicroseconds,
        buildUs: timing.buildDuration.inMicroseconds,
        rasterUs: timing.rasterDuration.inMicroseconds,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_model.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        final content = _model.content;
        final fonts = _model.fonts;
        if (fonts != null && !identical(fonts, _lastFonts)) {
          _lastFonts = fonts;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _model.repository.trace.add('pageFirstFrame');
          });
        }

        final enabled = !_model.busy && !_model.running;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.prototypeTitle),
            actions: [
              IconButton(
                tooltip: l10n.prototypeShare,
                onPressed: _model.busy || _model.running ? null : _model.share,
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(l10n.prototypeNotice),
                ),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: _model.model,
                      items: [
                        DropdownMenuItem(
                          value: 'quran-asr-small',
                          child: Text(l10n.prototypeSmall),
                        ),
                        DropdownMenuItem(
                          value: 'quran-asr-tiny',
                          child: Text(l10n.prototypeTiny),
                        ),
                      ],
                      onChanged: enabled
                          ? (value) {
                              if (value != null) _model.selectModel(value);
                            }
                          : null,
                    ),
                    TextButton(
                      onPressed: enabled ? _model.benchmark : null,
                      child: Text(l10n.prototypeBenchmark),
                    ),
                    TextButton(
                      onPressed: enabled ? _model.prepare : null,
                      child: Text(l10n.prototypeReload),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: Text(l10n.prototypeFile),
                  value: _model.fromFile,
                  onChanged: enabled ? _model.selectFile : null,
                ),
                TextButton(
                  onPressed: enabled ? _model.showForSelfCheck : null,
                  child: Text(l10n.prototypeSelfCheck),
                ),
                Text(_status(l10n)),
                if (_model.recommendation case final recommendation?)
                  Text(
                    '${l10n.prototypeRecommendation}: '
                    '${_recommendation(l10n, recommendation)}',
                  ),
                if (_model.busy) const LinearProgressIndicator(),
                Expanded(
                  child: content == null || fonts == null
                      ? Center(child: Text(l10n.prototypeInstall))
                      : PageView(
                          onPageChanged: (index) => _model.repository.trace.add(
                            'pageChanged',
                            segment: index,
                          ),
                          children: [
                            for (final page in content.pages)
                              Column(
                                children: [
                                  Text('${page.pageNumber}'),
                                  Expanded(
                                    child: RepaintBoundary(
                                      child: MushafPage(
                                        data: page,
                                        fontFamily: fonts.familyForPage(
                                          page.pageNumber,
                                        ),
                                        wordStates: Map.unmodifiable(
                                          _model.words,
                                        ),
                                        semanticsLabelBuilder: (ayah) =>
                                            '${ayah.surah}:${ayah.ayah} '
                                            '${ayah.canonicalText}',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton(
                        onPressed:
                            enabled &&
                                fonts != null &&
                                _model.recommendation !=
                                    AsrDeviceDecision.selfCheck
                            ? () async {
                                if (!_model.fromFile) {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(l10n.prototypeMicTitle),
                                      content: Text(l10n.prototypeMicReason),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(l10n.prototypeCancel),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(l10n.prototypeContinue),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true || !mounted) return;
                                }
                                await _model.start();
                              }
                            : null,
                        child: Text(l10n.prototypeStart),
                      ),
                      OutlinedButton(
                        onPressed: _model.running && !_model.busy
                            ? _model.stop
                            : null,
                        child: Text(l10n.prototypeStop),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _recommendation(AppLocalizations l10n, AsrDeviceDecision decision) =>
      switch (decision) {
        AsrDeviceDecision.small => l10n.prototypeSmall,
        AsrDeviceDecision.tiny => l10n.prototypeTiny,
        AsrDeviceDecision.smallWithSlowPartials => l10n.prototypeSlow,
        AsrDeviceDecision.selfCheck => l10n.prototypeSelfCheck,
      };

  String _status(AppLocalizations l10n) => switch (_model.state) {
    'failed' => l10n.prototypeFailed,
    'loading' => l10n.prototypeLoading,
    'running' => l10n.prototypeRunning,
    'lost' => l10n.prototypeLost,
    'stopping' => l10n.prototypeStopping,
    'interrupted' => l10n.prototypeInterrupted,
    'stopped' => l10n.prototypeStopped,
    _ => l10n.prototypeReady,
  };
}
