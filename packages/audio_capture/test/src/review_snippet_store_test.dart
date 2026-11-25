import 'dart:typed_data';

import 'package:audio_capture/audio_capture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('20 minutes of review events stay within 20 MiB and clear', () {
    const limit = 20 * 1024 * 1024;
    final store = ReviewSnippetStore(maxBytes: limit);

    // One event per ten seconds is deliberately dense. Each
    // event contains the configured 3 s before and after at 16 kHz Float32.
    for (var second = 0; second < 20 * 60; second += 10) {
      final retained = store.retain(
        'event-$second',
        AudioSnippet(
          samples: Float32List(6 * 16000),
          sampleRate: 16000,
          startMs: second * 1000,
          endMs: second * 1000 + 6000,
        ),
      );
      expect(retained, isTrue);
      expect(store.retainedBytes, lessThanOrEqualTo(limit));
    }

    expect(store.length, lessThan(20 * 60 ~/ 10));
    store.closeReview();
    expect(store.retainedBytes, 0);
    expect(store.length, 0);
  });

  test('releasing a reviewed event drops its sample memory', () {
    final store = ReviewSnippetStore(maxBytes: 1024);
    expect(
      store.retain(
        'check-1',
        AudioSnippet(
          samples: Float32List(100),
          sampleRate: 1000,
          startMs: 0,
          endMs: 100,
        ),
      ),
      isTrue,
    );

    expect(store.retainedBytes, 400);
    expect(store['check-1'], isNotNull);
    store.release('check-1');
    expect(store.retainedBytes, 0);
    expect(store['check-1'], isNull);
  });
}
