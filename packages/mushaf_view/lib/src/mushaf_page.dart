import 'dart:math' as math;

import 'package:contracts/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mushaf_view/src/models.dart';

/// Called when the user taps a rendered word.
typedef MushafWordTapCallback = void Function(WordKey wordKey);

/// Builds a localized semantics label from canonical ayah data.
typedef MushafSemanticsLabelBuilder = String Function(
  MushafAyahSemantics ayah,
);

/// Visual tokens for a [MushafPage].
@immutable
final class MushafPageTheme {
  /// Creates Mushaf visual tokens.
  const MushafPageTheme({
    this.textColor = const Color(0xFF202124),
    this.correctColor = const Color(0xFF176B45),
    this.attentionColor = const Color(0xFF8A5A00),
    this.errorColor = const Color(0xFFB3261E),
    this.mutedColor = const Color(0xFF6F7277),
    this.currentFillColor = const Color(0x1F386A8C),
    this.currentBorderColor = const Color(0xFF386A8C),
    this.hiddenGuideColor = const Color(0x55386A8C),
  });

  /// Default glyph color.
  final Color textColor;

  /// Color for a correctly recited word.
  final Color correctColor;

  /// Color for a possible error.
  final Color attentionColor;

  /// Color for a confirmed error.
  final Color errorColor;

  /// Color for an unheard word.
  final Color mutedColor;

  /// Background color for the current word.
  final Color currentFillColor;

  /// Outline color for the current word.
  final Color currentBorderColor;

  /// Optional guide color at a hidden word's preserved position.
  final Color hiddenGuideColor;
}

/// Exposes cached word rectangles in coordinates local to the page.
///
/// Rectangles become available after the page has been laid out.
final class MushafPageController {
  Map<WordKey, Rect> _wordRects = const <WordKey, Rect>{};

  /// Returns the cached rectangle for [wordKey], or `null` if absent.
  Rect? wordRect(WordKey wordKey) => _wordRects[wordKey];

  void _update(Map<WordKey, Rect> value) {
    _wordRects = Map<WordKey, Rect>.unmodifiable(value);
  }

  void _clear() {
    _wordRects = const <WordKey, Rect>{};
  }
}

/// Renders one fitted, interactive, accessible 15-line Mushaf page.
class MushafPage extends StatefulWidget {
  /// Creates a Mushaf page.
  const MushafPage({
    required this.data,
    required this.fontFamily,
    required this.semanticsLabelBuilder,
    this.wordStates = const <WordKey, MushafWordState>{},
    this.onWordTap,
    this.controller,
    this.theme = const MushafPageTheme(),
    this.showHiddenGuides = false,
    this.maximumFontSize = 52,
    super.key,
  }) : assert(maximumFontSize > 0, 'maximumFontSize must be positive');

  /// The visual layout and canonical accessibility content.
  final MushafPageData data;

  /// The runtime font family registered for this page.
  final String fontFamily;

  /// Per-word visual state. Missing entries are [MushafWordState.normal].
  final Map<WordKey, MushafWordState> wordStates;

  /// Called with a stable word identifier when a word is tapped.
  final MushafWordTapCallback? onWordTap;

  /// Optional access to the page's cached word geometry.
  final MushafPageController? controller;

  /// Visual tokens for word states.
  final MushafPageTheme theme;

  /// Whether hidden positions have thin guides. Defaults to `false`.
  final bool showHiddenGuides;

  /// Upper font-size bound before fitting the widest line.
  final double maximumFontSize;

  /// Localizes the canonical label announced for each ayah.
  final MushafSemanticsLabelBuilder semanticsLabelBuilder;

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  final _PageGeometryCache _geometryCache = _PageGeometryCache();

  @override
  void didUpdateWidget(MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._clear();
    }
  }

  @override
  void dispose() {
    widget.controller?._clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.hasBoundedWidth ? constraints.maxWidth : 360.0;
        final fallbackHeight = width * 1.55;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : fallbackHeight;
        final pageSize = Size(width, height);
        final geometry = _geometryCache.resolve(
          data: widget.data,
          size: pageSize,
          fontFamily: widget.fontFamily,
          maximumFontSize: widget.maximumFontSize,
        );
        widget.controller?._update(geometry.wordRects);

        return SizedBox.fromSize(
          size: pageSize,
          child: RepaintBoundary(
            key: ValueKey<String>('mushaf-page-${widget.data.pageNumber}'),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final wordKey = geometry.hitTest(details.localPosition);
                      if (wordKey != null) widget.onWordTap?.call(wordKey);
                    },
                    child: Column(
                      children: <Widget>[
                        for (var index = 0;
                            index < geometry.lines.length;
                            index += 1)
                          SizedBox(
                            height: geometry.lineHeight,
                            width: width,
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _MushafLinePainter(
                                  line: widget.data.lines[index],
                                  geometry: geometry.lines[index],
                                  states: _statesForLine(
                                    widget.data.lines[index],
                                    widget.wordStates,
                                  ),
                                  fontFamily: widget.fontFamily,
                                  fontSize: geometry.fontSize,
                                  theme: widget.theme,
                                  showHiddenGuides: widget.showHiddenGuides,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.data.ayahSemantics.isNotEmpty)
                  IgnorePointer(
                    child: Column(
                      children: <Widget>[
                        for (final ayah in widget.data.ayahSemantics)
                          Expanded(
                            child: Semantics(
                              container: true,
                              label: widget.semanticsLabelBuilder(ayah),
                              child: const SizedBox.expand(),
                            ),
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
}

Map<WordKey, MushafWordState> _statesForLine(
  MushafLineData line,
  Map<WordKey, MushafWordState> states,
) {
  return <WordKey, MushafWordState>{
    for (final fragment in line.fragments)
      if (fragment.wordKey case final wordKey?)
        wordKey: states[wordKey] ?? MushafWordState.normal,
  };
}

final class _PageGeometryCache {
  MushafPageData? _data;
  Size? _size;
  String? _fontFamily;
  double? _maximumFontSize;
  late _PageGeometry _geometry;

  _PageGeometry resolve({
    required MushafPageData data,
    required Size size,
    required String fontFamily,
    required double maximumFontSize,
  }) {
    if (identical(data, _data) &&
        size == _size &&
        fontFamily == _fontFamily &&
        maximumFontSize == _maximumFontSize) {
      return _geometry;
    }

    final geometry = _PageGeometry.calculate(
      data: data,
      size: size,
      fontFamily: fontFamily,
      maximumFontSize: maximumFontSize,
    );
    _data = data;
    _size = size;
    _fontFamily = fontFamily;
    _maximumFontSize = maximumFontSize;
    _geometry = geometry;
    return geometry;
  }
}

final class _PageGeometry {
  _PageGeometry({
    required this.fontSize,
    required this.lineHeight,
    required this.lines,
    required this.wordRects,
  });

  factory _PageGeometry.calculate({
    required MushafPageData data,
    required Size size,
    required String fontFamily,
    required double maximumFontSize,
  }) {
    final lineHeight = size.height / 15;
    var scale = 1.0;
    for (final line in data.lines) {
      final painter = _layoutPainter(
        line: line,
        fontFamily: fontFamily,
        fontSize: maximumFontSize,
        colorForWord: (_) => const Color(0xFF000000),
        maxWidth: double.infinity,
      );
      if (painter.width > size.width && painter.width > 0) {
        scale = math.min(scale, size.width / painter.width);
      }
      if (painter.height > lineHeight && painter.height > 0) {
        scale = math.min(scale, lineHeight / painter.height);
      }
    }
    final fontSize = math.max(1, maximumFontSize * scale * 0.98).toDouble();
    final lines = <_LineGeometry>[];
    final pageRects = <WordKey, Rect>{};

    for (var index = 0; index < data.lines.length; index += 1) {
      final line = data.lines[index];
      final painter = _layoutPainter(
        line: line,
        fontFamily: fontFamily,
        fontSize: fontSize,
        colorForWord: (_) => const Color(0xFF000000),
        maxWidth: size.width,
      );
      final paintOffset = Offset(0, (lineHeight - painter.height) / 2);
      final ranges = _fragmentRanges(line);
      final localRects = <WordKey, Rect>{};
      for (var fragmentIndex = 0;
          fragmentIndex < line.fragments.length;
          fragmentIndex += 1) {
        final wordKey = line.fragments[fragmentIndex].wordKey;
        if (wordKey == null) continue;
        final range = ranges[fragmentIndex];
        final boxes = painter.getBoxesForSelection(
          TextSelection(baseOffset: range.start, extentOffset: range.end),
        );
        if (boxes.isEmpty) continue;
        var rect = boxes.first.toRect();
        for (final box in boxes.skip(1)) {
          rect = rect.expandToInclude(box.toRect());
        }
        rect = rect.shift(paintOffset);
        localRects[wordKey] = rect;
        pageRects[wordKey] = rect.shift(Offset(0, index * lineHeight));
      }
      lines.add(
        _LineGeometry(
          paintOffset: paintOffset,
          wordRects: Map<WordKey, Rect>.unmodifiable(localRects),
        ),
      );
    }

    return _PageGeometry(
      fontSize: fontSize,
      lineHeight: lineHeight,
      lines: List<_LineGeometry>.unmodifiable(lines),
      wordRects: Map<WordKey, Rect>.unmodifiable(pageRects),
    );
  }

  final double fontSize;
  final double lineHeight;
  final List<_LineGeometry> lines;
  final Map<WordKey, Rect> wordRects;

  WordKey? hitTest(Offset position) {
    for (final entry in wordRects.entries) {
      if (entry.value.inflate(2).contains(position)) return entry.key;
    }
    return null;
  }
}

final class _LineGeometry {
  const _LineGeometry({
    required this.paintOffset,
    required this.wordRects,
  });

  final Offset paintOffset;
  final Map<WordKey, Rect> wordRects;
}

final class _TextRange {
  const _TextRange(this.start, this.end);

  final int start;
  final int end;
}

List<_TextRange> _fragmentRanges(MushafLineData line) {
  var offset = 0;
  final ranges = <_TextRange>[];
  for (var index = 0; index < line.fragments.length; index += 1) {
    final end = offset + line.fragments[index].glyph.length;
    ranges.add(_TextRange(offset, end));
    offset = end + (index == line.fragments.length - 1 ? 0 : 1);
  }
  return ranges;
}

TextPainter _layoutPainter({
  required MushafLineData line,
  required String fontFamily,
  required double fontSize,
  required Color Function(WordKey? wordKey) colorForWord,
  required double maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(
      children: <InlineSpan>[
        for (var index = 0; index < line.fragments.length; index += 1)
          TextSpan(
            text: '${line.fragments[index].glyph}'
                '${index == line.fragments.length - 1 ? '' : ' '}',
            style: TextStyle(
              color: colorForWord(line.fragments[index].wordKey),
              fontFamily: fontFamily,
              fontSize: fontSize,
              height: 1,
            ),
          ),
      ],
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.rtl,
    maxLines: 1,
  )..layout(maxWidth: maxWidth);
  return painter;
}

final class _MushafLinePainter extends CustomPainter {
  _MushafLinePainter({
    required this.line,
    required this.geometry,
    required this.states,
    required this.fontFamily,
    required this.fontSize,
    required this.theme,
    required this.showHiddenGuides,
  });

  final MushafLineData line;
  final _LineGeometry geometry;
  final Map<WordKey, MushafWordState> states;
  final String fontFamily;
  final double fontSize;
  final MushafPageTheme theme;
  final bool showHiddenGuides;

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in geometry.wordRects.entries) {
      final state = states[entry.key] ?? MushafWordState.normal;
      if (state == MushafWordState.current) {
        final highlight = RRect.fromRectAndRadius(
          entry.value.inflate(2),
          const Radius.circular(3),
        );
        canvas
          ..drawRRect(
            highlight,
            Paint()..color = theme.currentFillColor,
          )
          ..drawRRect(
            highlight,
            Paint()
              ..color = theme.currentBorderColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
      }
    }

    _layoutPainter(
      line: line,
      fontFamily: fontFamily,
      fontSize: fontSize,
      colorForWord: _colorForWord,
      maxWidth: size.width,
    ).paint(canvas, geometry.paintOffset);

    for (final entry in geometry.wordRects.entries) {
      _paintStateMarker(
        canvas,
        entry.value,
        states[entry.key] ?? MushafWordState.normal,
      );
    }
  }

  Color _colorForWord(WordKey? wordKey) {
    if (wordKey == null) return theme.textColor;
    return switch (states[wordKey] ?? MushafWordState.normal) {
      MushafWordState.hidden => const Color(0x00000000),
      MushafWordState.correct ||
      MushafWordState.corrected =>
        theme.correctColor,
      MushafWordState.possibleError => theme.attentionColor,
      MushafWordState.error => theme.errorColor,
      MushafWordState.notHeard => theme.mutedColor,
      MushafWordState.normal ||
      MushafWordState.current ||
      MushafWordState.revealedByHint =>
        theme.textColor,
    };
  }

  void _paintStateMarker(Canvas canvas, Rect rect, MushafWordState state) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, fontSize / 24).toDouble()
      ..strokeCap = StrokeCap.round;
    final filled = Paint()..style = PaintingStyle.fill;

    switch (state) {
      case MushafWordState.normal:
      case MushafWordState.current:
        return;
      case MushafWordState.hidden:
        if (showHiddenGuides) {
          canvas.drawLine(
            Offset(rect.left, rect.bottom - 1),
            Offset(rect.right, rect.bottom - 1),
            stroke..color = theme.hiddenGuideColor,
          );
        }
        return;
      case MushafWordState.correct:
        _paintCheck(canvas, rect, stroke..color = theme.correctColor);
        return;
      case MushafWordState.possibleError:
        canvas.drawCircle(
          Offset(rect.center.dx, rect.bottom + 1),
          math.max(1.5, fontSize / 18),
          filled..color = theme.attentionColor,
        );
        return;
      case MushafWordState.error:
        canvas.drawLine(
          Offset(rect.left, rect.bottom + 1),
          Offset(rect.right, rect.bottom + 1),
          stroke..color = theme.errorColor,
        );
        return;
      case MushafWordState.corrected:
        _paintCheck(canvas, rect, stroke..color = theme.correctColor);
        _paintCheck(
          canvas,
          rect.shift(Offset(fontSize / 10, 0)),
          stroke,
        );
        return;
      case MushafWordState.notHeard:
        final radius = math.max(2.5, fontSize / 8);
        final center = Offset(rect.left + radius, rect.top + radius);
        canvas
          ..drawCircle(center, radius, stroke..color = theme.mutedColor)
          ..drawLine(
            Offset(center.dx, center.dy - radius / 2),
            Offset(center.dx, center.dy + radius / 4),
            stroke,
          )
          ..drawCircle(
            Offset(center.dx, center.dy + radius / 1.7),
            math.max(0.8, radius / 5),
            filled..color = theme.mutedColor,
          );
        return;
      case MushafWordState.revealedByHint:
        final center = rect.topLeft + Offset(fontSize / 8, fontSize / 8);
        final radius = math.max(2, fontSize / 10).toDouble();
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(path, filled..color = theme.currentBorderColor);
        return;
    }
  }

  void _paintCheck(Canvas canvas, Rect rect, Paint paint) {
    final size = math.max(3, fontSize / 7);
    final origin = Offset(rect.left, rect.top + size);
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + size / 2, origin.dy + size / 2)
      ..lineTo(origin.dx + size * 1.4, origin.dy - size / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MushafLinePainter oldDelegate) {
    return oldDelegate.line != line ||
        oldDelegate.geometry != geometry ||
        !mapEquals(oldDelegate.states, states) ||
        oldDelegate.fontFamily != fontFamily ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.theme != theme ||
        oldDelegate.showHiddenGuides != showHiddenGuides;
  }
}
