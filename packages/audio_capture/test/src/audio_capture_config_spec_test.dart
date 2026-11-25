import 'dart:io';

import 'package:audio_capture/audio_capture.dart';
import 'package:flutter_test/flutter_test.dart';

// The built-in defaults must be the values of docs/tz 12.4, table «Звук»
// (review of #27: segmentEndPauseMs changed to 300 there and stayed 700
// here). The table is read from the spec itself, so a change in the spec
// fails this test until the default follows.
void main() {
  test('defaults match the audio table of spec 12.4', () {
    final spec = _audioTable(
      File('../../docs/tz/12-formaty-i-parametry.md').readAsStringSync(),
    );
    final defaults = const AudioCaptureConfig().toMessage();

    final checked = <String>[];
    for (final MapEntry(key: name, value: expected) in spec.entries) {
      if (!defaults.containsKey(name)) continue;
      expect(defaults[name], expected, reason: name);
      checked.add(name);
    }
    expect(
      checked,
      containsAll(<String>[
        'ringBufferSec',
        'preRollMs',
        'postRollMs',
        'segmentEndPauseMs',
        'maxSegmentMs',
        'reviewSnippetPadMs',
        'quietDbfs',
        'noisyDbfs',
        'clippingRatio',
        'signalHoldMs',
      ]),
      reason: 'the spec table was not read',
    );
  });
}

/// Parameter → default from the rows of «### Звук» in section 12.4.
Map<String, num> _audioTable(String spec) {
  final start = spec.indexOf('## 12.4');
  final table = spec.indexOf('### Звук', start);
  final end = spec.indexOf('\n### ', table + 1);
  final rows = spec.substring(table, end).split('\n');
  final number = RegExp(r'[−-]?\d{1,3}(?: \d{3})+|[−-]?\d+(?:,\d+)?');
  final names = RegExp('`([A-Za-z]+)`');
  final values = <String, num>{};
  for (final row in rows) {
    final cells = row.split('|');
    if (cells.length < 4) continue;
    final keys = [for (final m in names.allMatches(cells[1])) m.group(1)!];
    // group(1) is the whole name inside the backticks, always present.
    final numbers = [
      for (final m in number.allMatches(cells[2]))
        num.parse(
          m[0]!
              // m[0] is the whole match, always present.
              .replaceAll('−', '-')
              .replaceAll(' ', '')
              .replaceAll(',', '.'),
        ),
    ];
    // The first numbers of the cell belong to the names in order; anything
    // after them is an explanation (like «было 700»).
    for (final (i, key) in keys.indexed) {
      if (i < numbers.length) values[key] = numbers[i];
    }
  }
  return values;
}
