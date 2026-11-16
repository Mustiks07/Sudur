import 'dart:convert';

import 'package:content_build/src/tanzil_parser.dart';
import 'package:crypto/crypto.dart';

/// SHA-256 of the canonical text, independent of the file wrapper.
///
/// Hashes the UTF-8 bytes of one line `surah|ayah|text\n` per ayah, in
/// order. The copyright block and XML formatting are left out, so a new
/// copyright year in the source file does not change the checksum, while any
/// change of a single character of the text does.
String canonChecksum(TanzilQuran quran) {
  final buffer = StringBuffer();
  for (final surah in quran.surahs) {
    for (final ayah in surah.ayahs) {
      buffer
        ..write(surah.index)
        ..write('|')
        ..write(ayah.index)
        ..write('|')
        ..write(ayah.text)
        ..write('\n');
    }
  }
  return sha256.convert(utf8.encode(buffer.toString())).toString();
}

/// SHA-256 of raw bytes, as a lowercase hex string.
String bytesChecksum(List<int> bytes) => sha256.convert(bytes).toString();
