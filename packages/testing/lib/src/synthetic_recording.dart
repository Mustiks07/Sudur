import 'package:testing/src/recognition_script.dart';

/// A synthetic annotated recording for testing `tools/eval`: the test says
/// what the reader did with each expected word, and the builder produces
/// both the annotation (docs/tz 12.6 `<id>.ann.json`) and the recognition
/// results, so the right answer is known in advance.
///
/// Heard words are given by the test; build them from the canon (search
/// keys), never from typed Arabic text.
final class SyntheticRecording {
  /// Starts a recording of the expected range [from]..[to].
  SyntheticRecording({
    required this.id,
    required this.speakerId,
    required this.from,
    required this.to,
    this.nativeLanguage = 'kk',
    this.gender = 'f',
    this.device = 'budget-android',
    this.noise = 'quiet',
    this.msPerWord = 400,
  }) : script = RecognitionScript(sessionId: id, msPerWord: msPerWord);

  /// Recording id.
  final String id;

  /// Person id.
  final String speakerId;

  /// First expected word key, `surah:ayah:word`.
  final String from;

  /// Last expected word key.
  final String to;

  /// Native language group.
  final String nativeLanguage;

  /// Gender group.
  final String gender;

  /// Phone class group.
  final String device;

  /// Noise group.
  final String noise;

  /// Audio length of one word, ms; the same as in [script].
  final int msPerWord;

  /// Recognition results being built.
  final RecognitionScript script;

  final List<Map<String, Object?>> _words = [];
  final List<Map<String, Object?>> _insertions = [];
  final List<Map<String, Object?>> _jumps = [];
  final List<String> _segment = [];
  int _clockMs = 0;
  int _segmentStartMs = 0;

  int _say(String heard) {
    if (_segment.isEmpty) _segmentStartMs = _clockMs;
    _segment.add(heard);
    return _segmentStartMs + (_segment.length - 1) * msPerWord;
  }

  void _word(String key, String status, int? startMs, {String? heard}) {
    _words.add({
      'wordKey': key,
      'status': status,
      if (heard != null) 'heard': heard,
      if (startMs != null) 'startMs': startMs,
      if (startMs != null) 'endMs': startMs + msPerWord,
    });
  }

  /// The word [key] was read correctly as [heard].
  void correct(String key, String heard) => _word(key, 'correct', _say(heard));

  /// The word [key] was not read.
  void omitted(String key) => _word(key, 'omitted', null);

  /// [heard] was read instead of [key].
  void substituted(String key, String heard) =>
      _word(key, 'substituted', _say(heard), heard: heard);

  /// [wrong] was read for [key], then corrected to [right].
  void selfCorrected(String key, String wrong, String right) {
    final start = _say(wrong);
    _say(right);
    _word(key, 'selfCorrected', start);
  }

  /// The word [key] was read [times] times, correctly.
  void repeated(String key, String heard, {int times = 2}) {
    final start = _say(heard);
    for (var i = 1; i < times; i++) {
      _say(heard);
    }
    _word(key, 'repeated', start);
  }

  /// The word [key] could not be judged by annotators.
  void unclear(String key, String heard) => _word(key, 'unclear', _say(heard));

  /// An extra word [heard] after [afterKey].
  void inserted(String afterKey, String heard) {
    final start = _say(heard);
    _insertions.add({
      'afterWordKey': afterKey,
      'heard': heard,
      'startMs': start,
      'endMs': start + msPerWord,
    });
  }

  /// Reading [heard] at another place [to], after [afterKey].
  void jumped(String afterKey, String to, List<String> heard) {
    final starts = heard.map(_say).toList();
    _jumps.add({
      'fromWordKey': afterKey,
      'to': to,
      'startMs': starts.first,
      'endMs': starts.last + msPerWord,
    });
  }

  /// Ends the current speech segment and pauses for [pauseMs].
  void endSegment({int pauseMs = 800}) {
    if (_segment.isNotEmpty) {
      script.segment(List.of(_segment));
      _clockMs = _segmentStartMs + _segment.length * msPerWord;
      _segment.clear();
    }
    script.pause(pauseMs);
    _clockMs += pauseMs;
  }

  /// The annotation as a JSON object (docs/tz 12.6).
  Map<String, Object?> annotationJson() {
    endSegment(pauseMs: 0);
    return {
      'recordingId': id,
      'speaker': {
        'id': speakerId,
        'nativeLanguage': nativeLanguage,
        'gender': gender,
      },
      'conditions': {'device': device, 'noise': noise},
      'expected': {'from': from, 'to': to},
      'words': List.of(_words),
      'insertions': List.of(_insertions),
      'jumps': List.of(_jumps),
      'annotators': ['synthetic'],
    };
  }
}
