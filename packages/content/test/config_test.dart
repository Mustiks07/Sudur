import 'dart:convert';
import 'dart:io';

import 'package:content/content.dart';
import 'package:contracts/contracts.dart';
import 'package:test/test.dart';

import 'helpers.dart';

// Test keys and documents built here have a known shape: `!` on them
// cannot fail.

const String configFixtures = '../testing/fixtures/config';
const String spec = '../../docs/tz/12-formaty-i-parametry.md';

/// The parameter tables of docs/tz 12.4 that belong to `config`, by
/// section: name → value as written in the spec.
Map<String, Map<String, String>> specTables() {
  final text = File(spec).readAsStringSync();
  final part = text.substring(
    text.indexOf('## 12.4'),
    text.indexOf('## 12.5'),
  );
  const sections = {
    'Звук': 'audio',
    'Распознавание': 'recognition',
    'План': 'plan',
    'Прочее': 'other',
  };
  final tables = <String, Map<String, String>>{};
  String? section;
  for (final line in part.split('\n')) {
    if (line.startsWith('### ')) {
      section = sections[line.substring(4).trim()];
      continue;
    }
    if (section == null || !line.startsWith('|') || line.contains('---')) {
      continue;
    }
    final cells = line.split('|').map((c) => c.trim()).toList();
    final names = cells[1];
    // A value may be followed by « — » and an explanation (12.4, 25.11).
    final value = cells[2].split(' — ').first;
    if (names == 'Параметр') continue;
    final ids = names == 'Множители шагов'
        ? ['stepMultipliers']
        : [for (final m in RegExp(r'`(\w+)`').allMatches(names)) m[1]!];
    final values = ids.length == 1
        ? [value]
        : value.split(value.contains(';') ? ';' : ',').map((v) => v.trim());
    for (final (id, v) in [for (final (i, v) in values.indexed) (ids[i], v)]) {
      (tables[section] ??= {})[id] = v;
    }
  }
  return tables;
}

num specNumber(String text) {
  final m = RegExp(r'^[−-]?[\d  ]+(,\d+)?').firstMatch(text.trim())!;
  return num.parse(
    m[0]!
        .replaceAll('−', '-')
        .replaceAll(RegExp('[  ]'), '')
        .replaceAll(',', '.'),
  );
}

/// The spec cell [text] read the way [kind] needs.
Object specValue(String text, ParamKind kind) {
  final t = text.replaceAll(RegExp(r'\s*\(.*\)$'), '').trim();
  return switch (kind) {
    ParamKind.boolean => t == 'true',
    ParamKind.integerList => [
        for (final x in t.replaceAll(RegExp(r'[\[\]]'), '').split(','))
          specNumber(x),
      ],
    ParamKind.numberTriple => [for (final x in t.split(';')) specNumber(x)],
    ParamKind.range => {
        'min': specNumber(t.split('–')[0]),
        'max': specNumber(t.split('–')[1]),
      },
    _ => specNumber(t),
  };
}

/// Equal JSON values, numbers compared by value (2 == 2.0).
bool sameValue(Object? a, Object? b) => switch ((a, b)) {
      (final num x, final num y) => x == y,
      (final List<Object?> x, final List<Object?> y) => x.length == y.length &&
          [for (var i = 0; i < x.length; i++) sameValue(x[i], y[i])]
              .every((e) => e),
      (final Map<String, Object?> x, final Map<String, Object?> y) =>
        x.length == y.length &&
            x.keys.every((k) => y.containsKey(k) && sameValue(x[k], y[k])),
      _ => a == b,
    };

void main() {
  late Map<String, TestKey> keys;
  late TrustedKeys trust;
  late Map<String, Object?> fixture;

  setUpAll(() {
    keys = loadTestKeys();
    trust = trusted(keys);
    fixture = jsonDecode(
      File('$configFixtures/config.test.json').readAsStringSync(),
    ) as Map<String, Object?>;
  });

  Future<String> signed(Map<String, Object?> doc) =>
      sign(doc, keys['test-main']!.seed, keyId: 'test-main');

  Map<String, Object?> copy() =>
      jsonDecode(jsonEncode(fixture)) as Map<String, Object?>;

  group('built-in values match docs/tz 12.4', () {
    test('every parameter of the spec tables, with its value', () {
      final tables = specTables();
      expect(tables.keys, configSchema.keys);
      for (final MapEntry(key: section, value: specs) in configSchema.entries) {
        final table = tables[section]!;
        expect(
          table.keys.toSet(),
          {for (final s in specs) s.name},
          reason: 'section $section',
        );
        for (final s in specs) {
          expect(
            sameValue(specValue(table[s.name]!, s.kind), s.defaultValue),
            isTrue,
            reason: '$section.${s.name}: spec "${table[s.name]}", '
                'built in ${s.defaultValue}',
          );
        }
      }
    });

    test('model thresholds are not in config (РС-02)', () {
      final names = {
        for (final specs in configSchema.values)
          for (final s in specs) s.name,
      };
      for (final model in [
        'beamSize',
        'simFloor',
        'strongMatch',
        'jumpMinWords',
      ]) {
        expect(names, isNot(contains(model)));
      }
    });

    test('the typed defaults are the schema defaults', () {
      final parsed = ok(parseConfigValues(const {}));
      expect(parsed.audio.quietDbfs, -42);
      expect(parsed.plan.recentLadderDays, [1, 2, 4, 7]);
      expect(parsed.plan.diagnosticSize, (min: 3, max: 5));
      expect(parsed.plan.stepMultipliers, [1.3, 3.0, 8.0]);
      expect(parsed.other.uploadWifiOnly, isTrue);
      expect(AppConfig.defaults.other.manifestCheckHours, 24);
    });
  });

  group('signed config file', () {
    test('the file signed by tools/content_build is accepted', () async {
      final v = ok(
        await verifyConfig(
          File('$configFixtures/config.test.json').readAsStringSync(),
          trust,
        ),
      );
      expect(v.version, const PackageVersion(1, 0, 0));
      expect(v.signature.keyId, 'test-main');
      expect(v.config.plan.newShare, 0.2);
      expect(v.config.recognition.asrThreads, 2);
    });

    ConfigException refused(Result<VerifiedConfig> r) =>
        (r as Error<VerifiedConfig>).error as ConfigException;

    test('a changed file is refused: bad signature', () async {
      final doc = copy();
      (doc['other']! as Map<String, Object?>)['freeVoiceMinutesPerDay'] = 999;
      final r = await verifyConfig(jsonEncode(doc), trust);
      expect(refused(r).problem, ManifestProblem.badSignature);
    });

    test('garbage is refused', () async {
      expect(
        refused(await verifyConfig('{', trust)).problem,
        ManifestProblem.malformed,
      );
    });

    Future<ConfigException> withValue(
      String section,
      String name,
      Object? value,
    ) async {
      final doc = copy();
      (doc[section]! as Map<String, Object?>)[name] = value;
      return refused(await verifyConfig(await signed(doc), trust));
    }

    test('values out of bounds or of a wrong kind: refused with the name',
        () async {
      for (final (section, name, value) in [
        ('audio', 'ringBufferSec', 0),
        ('audio', 'clippingRatio', 1.5),
        ('audio', 'quietDbfs', 'loud'),
        ('recognition', 'asrThreads', 2.5),
        ('plan', 'recentLadderDays', [4, 2]),
        ('plan', 'recentLadderDays', <int>[]),
        ('plan', 'stepMultipliers', [1.3, 3.0]),
        ('plan', 'diagnosticSize', {'min': 5, 'max': 3}),
        ('other', 'uploadWifiOnly', 'yes'),
        ('other', 'quizPassPercent', 101),
      ]) {
        final e = await withValue(section, name, value);
        expect(e.problem, ManifestProblem.malformed);
        expect(e.message, contains('$section.$name'), reason: '$value');
      }
    });

    test('unknown parameters and sections are refused', () async {
      expect(
        (await withValue('audio', 'volumeBoost', 2)).message,
        contains('unknown parameter audio.volumeBoost'),
      );
      final doc = copy()..['follow'] = {'beamSize': 5};
      expect(
        refused(await verifyConfig(await signed(doc), trust)).message,
        contains('unknown field "follow"'),
      );
    });

    test('rules between values', () async {
      final shares = copy();
      (shares['plan']! as Map<String, Object?>)['newShare'] = 0.5;
      expect(
        refused(await verifyConfig(await signed(shares), trust)).message,
        contains('add up to 1'),
      );
      final levels = copy();
      (levels['audio']! as Map<String, Object?>)['quietDbfs'] = -30;
      expect(
        refused(await verifyConfig(await signed(levels), trust)).message,
        contains('quietDbfs'),
      );
    });

    test('a newer config format is refused as unsupported', () async {
      final doc = copy()..['configVersion'] = 2;
      expect(
        refused(await verifyConfig(await signed(doc), trust)).problem,
        ManifestProblem.unsupportedVersion,
      );
    });

    test('a missing parameter keeps its built-in value', () async {
      final doc = copy();
      (doc['other']! as Map<String, Object?>)
        ..remove('trialDays')
        ..['freeVoiceMinutesPerDay'] = 15;
      final v = ok(await verifyConfig(await signed(doc), trust));
      expect(v.config.other.trialDays, 7);
      expect(v.config.other.freeVoiceMinutesPerDay, 15);
    });
  });

  group('file store', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('config'));
    tearDown(() => dir.deleteSync(recursive: true));

    String path() => '${dir.path}/config/config.json';

    test('nothing stored: null; then writes and reads back', () async {
      final store = FileConfigStore(path());
      expect(ok(await store.read()), isNull);
      ok(await store.write('first'));
      expect(ok(await store.read()), 'first');
      ok(await store.write('second'));
      expect(ok(await store.read()), 'second');
      expect(File('${path()}.tmp').existsSync(), isFalse);
    });

    test('a failed write leaves the stored copy whole', () async {
      final store = FileConfigStore(path());
      ok(await store.write('first'));
      // The temporary file cannot be created: a folder stands in its way.
      Directory('${path()}.tmp').createSync();
      expect(await store.write('second'), isA<Error<void>>());
      expect(ok(await store.read()), 'first');
    });

    test('an unreadable store is an error result, not an exception', () async {
      Directory(path()).createSync(recursive: true); // A folder, not a file.
      expect(await FileConfigStore(path()).read(), isA<Error<String?>>());
    });

    test('the loader on a real file: taken, kept across restarts', () async {
      final store = FileConfigStore(path());
      final doc = copy()..['issuedAt'] = '2026-11-19T00:00:00Z';
      final taken = await ConfigLoader(keys: trust, store: store)
          .accept(await signed(doc));
      expect(taken.source, ConfigSource.received);
      final restarted = await ConfigLoader(keys: trust, store: store).current();
      expect(restarted.source, ConfigSource.stored);
    });
  });

  group('the loader keeps the last verified copy', () {
    late MemoryConfigStore store;
    late ConfigLoader loader;
    setUp(() {
      store = MemoryConfigStore();
      loader = ConfigLoader(keys: trust, store: store);
    });

    Future<String> withMinutes(int minutes, String issuedAt) {
      final doc = copy()..['issuedAt'] = issuedAt;
      (doc['other']! as Map<String, Object?>)['freeVoiceMinutesPerDay'] =
          minutes;
      return signed(doc);
    }

    test('nothing stored: built-in values', () async {
      final s = await loader.current();
      expect(s.source, ConfigSource.builtIn);
      expect(s.config.other.freeVoiceMinutesPerDay, 10);
    });

    test('a valid file is taken and stored; a broken one rolls back', () async {
      final good = await withMinutes(20, '2026-11-19T00:00:00Z');
      final taken = await loader.accept(good);
      expect(taken.source, ConfigSource.received);
      expect(taken.config.other.freeVoiceMinutesPerDay, 20);
      expect(store.stored, good);

      final broken = good.replaceFirst(
        '"freeVoiceMinutesPerDay":20',
        '"freeVoiceMinutesPerDay":99',
      );
      final kept = await loader.accept(broken);
      expect(kept.refused?.problem, ManifestProblem.badSignature);
      expect(kept.source, ConfigSource.stored);
      expect(kept.config.other.freeVoiceMinutesPerDay, 20);
      expect(store.stored, good);

      // After a restart the stored copy is used again.
      final restarted = await ConfigLoader(keys: trust, store: store).current();
      expect(restarted.source, ConfigSource.stored);
      expect(restarted.config.other.freeVoiceMinutesPerDay, 20);
    });

    test('an older file than the stored one is refused', () async {
      await loader.accept(await withMinutes(20, '2026-11-19T00:00:00Z'));
      final old =
          await loader.accept(await withMinutes(5, '2026-11-18T00:00:00Z'));
      expect(old.refused?.problem, ManifestProblem.outdated);
      expect(old.config.other.freeVoiceMinutesPerDay, 20);
    });

    test('the store cannot be read: built-in values, no crash (review #24)',
        () async {
      store
        ..stored = await withMinutes(20, '2026-11-19T00:00:00Z')
        ..failRead = true;
      final s = await loader.current();
      expect(s.source, ConfigSource.builtIn);
      expect(s.storeError, isA<FileSystemException>());
      expect(s.config.other.freeVoiceMinutesPerDay, 10);
    });

    test(
        'the store cannot be written: the previous verified copy stays '
        '(review #24)', () async {
      await loader.accept(await withMinutes(20, '2026-11-19T00:00:00Z'));
      store.failWrite = true;
      final s =
          await loader.accept(await withMinutes(30, '2026-11-20T00:00:00Z'));
      expect(s.storeError, isA<FileSystemException>());
      expect(s.source, ConfigSource.stored);
      expect(s.config.other.freeVoiceMinutesPerDay, 20);
      // Nothing changed on disk: after a restart the same copy applies.
      expect((await loader.current()).config.other.freeVoiceMinutesPerDay, 20);
      // Storing works again: the new file is taken.
      store.failWrite = false;
      final again =
          await loader.accept(await withMinutes(30, '2026-11-20T00:00:00Z'));
      expect(again.storeError, isNull);
      expect(again.source, ConfigSource.received);
      expect(again.config.other.freeVoiceMinutesPerDay, 30);
    });

    test(
        'nothing stored yet and the store cannot be written: built-in '
        'values', () async {
      store.failWrite = true;
      final s =
          await loader.accept(await withMinutes(30, '2026-11-20T00:00:00Z'));
      expect(s.source, ConfigSource.builtIn);
      expect(s.config.other.freeVoiceMinutesPerDay, 10);
      expect(s.storeError, isNotNull);
    });

    test('a store that throws IOException does not break the loader', () async {
      final throwing = ConfigLoader(keys: trust, store: ThrowingConfigStore());
      final s = await throwing.current();
      expect(s.source, ConfigSource.builtIn);
      expect(s.storeError, isA<FileSystemException>());
      final a =
          await throwing.accept(await withMinutes(30, '2026-11-20T00:00:00Z'));
      expect(a.source, ConfigSource.builtIn);
      expect(a.storeError, isA<FileSystemException>());
    });

    test('a damaged stored copy: built-in values', () async {
      store.stored = '{"broken": true}';
      final s = await loader.current();
      expect(s.source, ConfigSource.builtIn);
      expect(s.refused, isNotNull);
      expect(s.config.other.freeVoiceMinutesPerDay, 10);
    });
  });
}

/// A store that breaks its contract and throws.
final class ThrowingConfigStore implements ConfigStore {
  @override
  Future<Result<String?>> read() =>
      throw const FileSystemException('device error');

  @override
  Future<Result<void>> write(String source) =>
      throw const FileSystemException('device error');
}

final class MemoryConfigStore implements ConfigStore {
  String? stored;
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<Result<String?>> read() async => failRead
      ? const Result.error(FileSystemException('storage is unavailable'))
      : Result.ok(stored);

  @override
  Future<Result<void>> write(String source) async {
    if (failWrite) {
      return const Result.error(FileSystemException('disk is full'));
    }
    stored = source;
    return const Result.ok(null);
  }
}
