import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

// The model output rule of docs/tz 12.3, checked on the whole Tanzil text
// fixture. Code points only: no Arabic is typed here.

List<String> canonicalWords() {
  final json = jsonDecode(File('fixtures/quran_text.json').readAsStringSync())
      as Map<String, Object?>;
  return [
    for (final a in json['ayahs']! as List<Object?>) // Fixture shape.
      for (final w in (a! as List<Object?>)[2]! as List<Object?>) w! as String,
  ];
}

void main() {
  late List<String> words;
  setUpAll(() => words = canonicalWords());

  test('every canonical word becomes non-empty model output', () {
    expect(words, hasLength(77433));
    for (final w in words) {
      final out = modelLetters(w);
      expect(out, isNotEmpty);
      expect(isModelOutput(out), isTrue);
    }
  });

  test('model output has no harakat, small alif or tatweel', () {
    const dropped = {0x064E, 0x064F, 0x0650, 0x0651, 0x0652, 0x0670, 0x0640};
    expect(
      words.any((w) => w.runes.any(dropped.contains)),
      isTrue,
      reason: 'the canon has them',
    );
    for (final w in words) {
      expect(modelLetters(w).runes.any(dropped.contains), isFalse);
    }
  });

  test('a canonical key with harakat is not model output', () {
    final withHarakat = words.firstWhere((w) => w.runes.contains(0x064E));
    expect(isModelOutput(withHarakat), isFalse);
  });

  test('the recognition script and the fake recognizer refuse it', () {
    final withHarakat = words.firstWhere((w) => w.runes.contains(0x064E));
    expect(
      () => RecognitionScript(modelOutput: true).segment([withHarakat]),
      throwsArgumentError,
    );
    final script = RecognitionScript()..segment([withHarakat]);
    expect(
      () => FakeSpeechRecognizer.modelOutput(
        script.results,
        info: scriptedRecognizerInfo,
      ),
      throwsArgumentError,
    );
    final model = RecognitionScript(modelOutput: true)
      ..segment([modelLetters(withHarakat)]);
    expect(
      FakeSpeechRecognizer.modelOutput(
        model.results,
        info: scriptedRecognizerInfo,
      ).script,
      hasLength(2),
    );
  });

  test('the alphabet has 29 letters, all Arabic', () {
    expect(modelLetterCodes, hasLength(29));
    expect(modelLetterCodes.every((c) => c >= 0x0621 && c <= 0x064A), isTrue);
    // A Result import keeps the contracts dependency honest in tests.
    expect(const Result<int>.ok(1), isA<Ok<int>>());
  });
}
