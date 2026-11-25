import 'dart:convert';
import 'dart:io';

import 'package:sudur/data/models/canon_index.dart';
import 'package:sudur/data/services/app_canon_service.dart';

/// The canonical text fixture (ADR 0004), read from `packages/testing`.
String fixtureQuranText() =>
    File('../packages/testing/fixtures/quran_text.json').readAsStringSync();

/// Index of the fixture text with the D01 passages if the fixture is there
/// (after #23 is merged), otherwise one passage per ayah.
CanonIndex fixtureCanon() {
  final text = fixtureQuranText();
  final derived = File('../packages/testing/fixtures/derived.json');
  return CanonIndex.parse(
    text,
    derived.existsSync() ? derived.readAsStringSync() : ayahPassages(text),
  );
}

/// Derived JSON with one passage per ayah of [text].
String ayahPassages(String text) {
  final root = jsonDecode(text) as Map<String, Object?>;
  final version = root['contentVersion']! as Map<String, Object?>;
  var next = 1;
  return jsonEncode(<String, Object?>{
    'format': 1,
    'kind': 'derived',
    'textCanonSha256': version['canonSha256'],
    'passages': <Object?>[
      for (final ayah in root['ayahs']! as List<Object?>)
        <int>[next, (next += _wordsOf(ayah)) - 1],
    ],
  });
}

int _wordsOf(Object? ayah) =>
    ((ayah! as List<Object?>)[2]! as List<Object?>).length;

/// Canon service over the fixture; [fail] makes `load` fail like no network.
final class FixtureCanonService implements AppCanonService {
  /// Creates the service.
  // ignore: unnecessary_type_name_in_constructor
  FixtureCanonService({this.fail = false});

  /// Whether `load` throws.
  bool fail;

  /// Number of `load` calls.
  int loads = 0;

  static final CanonIndex _index = fixtureCanon();

  @override
  Future<CanonIndex> load() async {
    loads++;
    if (fail) throw const SocketException('offline');
    return _index;
  }
}
