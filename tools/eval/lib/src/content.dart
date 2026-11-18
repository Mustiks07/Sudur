import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';

/// Words of a content file from `tools/content_build`: the whole-Quran text
/// (`text.json`, format 2, ADR 0004) or prototype pages (`content.json`,
/// format 1). The file kind is told by its `kind` field.
Result<List<Word>> loadContentWords(String json) =>
    switch (_object(json)?['kind']) {
      'text' => QuranTextJsonSource(json).loadWords(),
      _ => ContentJsonSource(json).loadWords(),
    };

/// Version of the content text for `CheckEvent.versions` (ПО-11):
/// `contentVersion.version`, or `unknown`.
String contentTextVersion(String json) =>
    switch (_object(json)?['contentVersion']) {
      {'version': final String v} => v,
      _ => 'unknown',
    };

Map<String, Object?>? _object(String json) {
  try {
    return switch (jsonDecode(json)) {
      final Map<String, Object?> m => m,
      _ => null,
    };
  } on FormatException {
    // Not JSON: the sources report it with their own error.
    return null;
  }
}
