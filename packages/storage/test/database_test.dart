import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/src/database.dart';
import 'package:storage/storage.dart';

void main() {
  test('schema-v1 snapshot matches the database created from scratch',
      () async {
    final database = SudurDatabase.memory();
    addTearDown(database.close);

    final snapshot = await _schemaSnapshot().readAsString();
    final decoded = jsonDecode(snapshot);
    if (decoded is! Map<String, Object?>) {
      fail('Schema snapshot must be a JSON object.');
    }
    final entities = decoded['entities'];
    if (entities is! List<Object?>) {
      fail('Schema snapshot must contain entities.');
    }
    final snapshotNames = <String>{};
    for (final entity in entities) {
      if (entity is! Map<String, Object?>) {
        fail('Schema entity must be an object.');
      }
      final type = entity['type'];
      if (type != 'table' && type != 'index') {
        continue;
      }
      final data = entity['data'];
      if (data is! Map<String, Object?>) {
        fail('Schema entity must have a name.');
      }
      final name = data['name'];
      if (name is! String) {
        fail('Schema entity must have a name.');
      }
      snapshotNames.add(name);
    }

    final liveRows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type IN ('table', 'index') "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    final liveNames = liveRows.map((row) => row.read<String>('name')).toSet();

    expect(database.schemaVersion, 1);
    expect(snapshotNames, liveNames);
    expect(
      snapshotNames.intersection(schemaV1TableNames.toSet()),
      hasLength(17),
    );
    expect(await database.select(database.outboxEntries).get(), isEmpty);
  });

  test('file database is opened through the background executor', () async {
    final directory = await Directory.systemTemp.createTemp('sudur-storage-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/user.sqlite');
    final storage = StorageService.openFile(file.path);

    expect(await storage.profiles.list(), isA<Ok<List<ProfileData>>>());
    await storage.close();

    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

File _schemaSnapshot() {
  final fromRoot = File(
    'packages/storage/drift_schemas/drift_schema_v1.json',
  );
  return fromRoot.existsSync()
      ? fromRoot
      : File('drift_schemas/drift_schema_v1.json');
}
