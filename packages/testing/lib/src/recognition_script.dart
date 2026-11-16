import 'package:contracts/contracts.dart';

/// Model description used by scripted results.
const RecognizerInfo scriptedRecognizerInfo = RecognizerInfo(
  modelId: 'fake/scripted',
  modelVersion: '0',
  output: AsrOutputKind.uthmaniLettersNoDiacritics,
  isStreaming: false,
  hasTokenTimes: false,
);

/// Builds a sequence of [RecognitionResult]s the way the recognizer emits
/// them (docs/tz 10.3): growing partial results while a segment is open,
/// then one final result for the whole segment.
///
/// Words are given by the test. Build them from the canon (search keys of
/// words, with skips, repeats and letter distortions), never from typed
/// Arabic text.
final class RecognitionScript {
  /// Creates an empty script.
  RecognitionScript({
    this.sessionId = 'test-session',
    this.msPerWord = 400,
    this.separator = ' ',
  });

  /// Session id put into every result.
  final String sessionId;

  /// Audio length of one word, in ms.
  final int msPerWord;

  /// Word separator of the recognized text.
  final String separator;

  final List<RecognitionResult> _results = [];
  int _segmentId = 0;
  int _clockMs = 0;

  /// Results so far, in order.
  List<RecognitionResult> get results => List.unmodifiable(_results);

  /// A segment with one partial result per word (the text so far), then
  /// the final result.
  void segment(List<String> words) {
    final start = _clockMs;
    _segmentId++;
    for (var n = 1; n <= words.length; n++) {
      _add(words.sublist(0, n), start, start + n * msPerWord, isFinal: false);
    }
    _clockMs = start + words.length * msPerWord;
    _add(words, start, _clockMs, isFinal: true);
  }

  /// A segment with the given partial texts (each a list of words), then
  /// the final result [finalWords].
  void segmentWithPartials(
    List<List<String>> partials,
    List<String> finalWords,
  ) {
    final start = _clockMs;
    _segmentId++;
    for (var i = 0; i < partials.length; i++) {
      _add(partials[i], start, start + (i + 1) * msPerWord, isFinal: false);
    }
    _clockMs = start + finalWords.length * msPerWord;
    _add(finalWords, start, _clockMs, isFinal: true);
  }

  /// A long segment whose partial results cover only the last
  /// [windowWords] words, like the simulated streaming of docs/tz 10.3.
  void slidingSegment(List<String> words, {required int windowWords}) {
    final start = _clockMs;
    _segmentId++;
    for (var n = 1; n <= words.length; n++) {
      final first = n > windowWords ? n - windowWords : 0;
      _add(
        words.sublist(first, n),
        start + first * msPerWord,
        start + n * msPerWord,
        isFinal: false,
      );
    }
    _clockMs = start + words.length * msPerWord;
    _add(words, start, _clockMs, isFinal: true);
  }

  /// Silence of [ms] between segments.
  void pause(int ms) => _clockMs += ms;

  void _add(
    List<String> words,
    int startMs,
    int endMs, {
    required bool isFinal,
  }) {
    _results.add(
      RecognitionResult(
        sessionId: sessionId,
        segmentId: _segmentId,
        isFinal: isFinal,
        text: words.join(separator),
        tokens: [for (final w in words) AsrToken(text: w)],
        audioStartMs: startMs,
        audioEndMs: endMs,
        decodeMs: 0,
        info: scriptedRecognizerInfo,
      ),
    );
  }
}

/// [word] without the code point at [index]: a recognition error that
/// loses one letter.
String dropLetter(String word, int index) {
  final runes = word.runes.toList()..removeAt(index);
  return String.fromCharCodes(runes);
}

/// [word] with the code points at [index] and [index] + 1 swapped.
String swapLetters(String word, int index) {
  final runes = word.runes.toList();
  final t = runes[index];
  runes[index] = runes[index + 1];
  runes[index + 1] = t;
  return String.fromCharCodes(runes);
}
