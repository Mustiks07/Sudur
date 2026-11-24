// Recognized text the way the Abdou/quran-asr models output it
// (docs/tz 12.3, «normalizer.json для моделей Abdou/quran-asr…»): only 29
// bare letters and the word separator. Tests of following and checking
// must feed recognized text in this form, not canonical search keys — with
// canonical keys a normalizer that keeps harakat goes unnoticed (found on
// the owner's phone, 19.11.2026).
//
// This is an independent implementation of the rule (keep the 29 letters
// after the replacements), so tests can cross-check the normalizer.json of
// a model package against it. Code points only: no Arabic is typed here.

/// The 29 letters of the model vocabulary (`tokens.txt`, docs/tz 12.3):
/// ء ا ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي.
const Set<int> modelLetterCodes = {
  0x0621, 0x0627, 0x0628, 0x062A, 0x062B, 0x062C, 0x062D, 0x062E, //
  0x062F, 0x0630, 0x0631, 0x0632, 0x0633, 0x0634, 0x0635, 0x0636, //
  0x0637, 0x0638, 0x0639, 0x063A, 0x0641, 0x0642, 0x0643, 0x0644, //
  0x0645, 0x0646, 0x0647, 0x0648, 0x064A, //
};

/// Replacements before the letters are kept (docs/tz 12.3, in order):
/// alif forms → alif, ya forms → ya, waw with hamza → waw, ta marbuta → ha,
/// keheh → kaf.
const Map<int, int> modelLetterReplacements = {
  0x0623: 0x0627, 0x0625: 0x0627, 0x0622: 0x0627, 0x0671: 0x0627, //
  0x0672: 0x0627, 0x0673: 0x0627, //
  0x0649: 0x064A, 0x0626: 0x064A, 0x06D2: 0x064A, 0x06CC: 0x064A, //
  0x0624: 0x0648, 0x0629: 0x0647, 0x06A9: 0x0643, //
};

/// One canonical word as the model would output it: replacements applied,
/// then everything but the 29 letters dropped (harakat, small alif,
/// tatweel, pause and reading marks).
String modelLetters(String canonicalWord) => String.fromCharCodes([
      for (final r in canonicalWord.runes)
        if (modelLetterCodes.contains(modelLetterReplacements[r] ?? r))
          modelLetterReplacements[r] ?? r,
    ]);

/// Whether [text] could be model output: only the 29 letters and spaces.
bool isModelOutput(String text) =>
    text.runes.every((r) => r == 0x0020 || modelLetterCodes.contains(r));
