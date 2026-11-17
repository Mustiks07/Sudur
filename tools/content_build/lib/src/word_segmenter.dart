import 'package:content_build/src/content_build_exception.dart';

/// Separator between tokens in the Tanzil text.
const String tanzilTokenSeparator = ' ';

/// First code point of the Unicode range of Quranic annotation signs
/// (small high ligatures, pause marks, sajda sign and similar).
const int quranicSignFirst = 0x06D6;

/// Last code point of the Unicode range of Quranic annotation signs.
const int quranicSignLast = 0x06ED;

/// Splits the text of one ayah into words without changing a single
/// character.
///
/// Tanzil writes pause marks and the sajda sign as separate tokens. Such a
/// token is not a word: it stays attached to the preceding word, together
/// with the separator before it. Therefore joining the result with
/// [tanzilTokenSeparator] gives back [ayahText] exactly.
///
/// Throws [ContentBuildException] on an empty token or when a sign token has
/// no word before it.
List<String> segmentAyah(String ayahText) {
  final words = <String>[];
  for (final token in ayahText.split(tanzilTokenSeparator)) {
    if (token.isEmpty) {
      throw ContentBuildException('Empty token in ayah text: "$ayahText".');
    }
    if (isSignToken(token)) {
      if (words.isEmpty) {
        throw ContentBuildException(
          'Ayah text starts with a sign token: "$ayahText".',
        );
      }
      words[words.length - 1] = '${words.last}$tanzilTokenSeparator$token';
    } else {
      words.add(token);
    }
  }
  return words;
}

/// Whether every code point of [token] is a Quranic annotation sign.
bool isSignToken(String token) =>
    token.isNotEmpty &&
    token.runes.every((r) => r >= quranicSignFirst && r <= quranicSignLast);
