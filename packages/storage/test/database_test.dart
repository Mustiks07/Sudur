import 'dart:convert';
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:storage/src/database.dart';
import 'package:storage/storage.dart';

void main() {
  test('schema-v2 snapshot fully matches a database created from scratch',
      () async {
    final database = SudurDatabase.memory();
    addTearDown(database.close);

    final snapshot = _decodeSnapshot(await _schemaSnapshot(2).readAsString());
    final tables = _tables(snapshot);
    final indexes = _indexes(snapshot, tables);
    final liveObjects = await database.customSelect(
      '''
SELECT type, name, tbl_name, sql FROM sqlite_master
WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name
''',
    ).get();

    expect(
      liveObjects.map((row) => row.read<String>('type')).toSet(),
      {'table', 'index'},
    );
    expect(
      liveObjects
          .where((row) => row.read<String>('type') == 'table')
          .map((row) => row.read<String>('name'))
          .toSet(),
      tables.values.map((table) => table.name).toSet(),
    );
    expect(
      liveObjects
          .where((row) => row.read<String>('type') == 'index')
          .map((row) => row.read<String>('name'))
          .toSet(),
      indexes.map((index) => index.name).toSet(),
    );

    for (final table in tables.values) {
      final liveColumns = await database
          .customSelect('PRAGMA table_info("${table.name}")')
          .get();
      expect(
        [for (final row in liveColumns) _liveColumn(row.data)],
        table.columns,
        reason: 'full column definition of ${table.name}',
      );
      final sql = liveObjects
          .singleWhere(
            (row) =>
                row.read<String>('type') == 'table' &&
                row.read<String>('name') == table.name,
          )
          .read<String>('sql');
      for (final constraint in table.columnConstraints) {
        expect(_normalizedSql(sql), contains(_normalizedSql(constraint)));
      }
      expect(
        await database
            .customSelect('PRAGMA foreign_key_list("${table.name}")')
            .get(),
        isEmpty,
        reason: '${table.name} has no references in schema v1 snapshot',
      );
    }

    for (final index in indexes) {
      final live = liveObjects.singleWhere(
        (row) =>
            row.read<String>('type') == 'index' &&
            row.read<String>('name') == index.name,
      );
      expect(live.read<String>('tbl_name'), index.table);
      final columns = await database
          .customSelect('PRAGMA index_info("${index.name}")')
          .get();
      expect(
        columns.map((row) => row.read<String>('name')).toList(),
        index.columns,
        reason: 'indexed columns of ${index.name}',
      );
      final list = await database
          .customSelect('PRAGMA index_list("${index.table}")')
          .get();
      final definition = list.singleWhere(
        (row) => row.read<String>('name') == index.name,
      );
      expect(definition.read<int>('unique') == 1, index.unique);
      expect(live.read<String>('sql').contains(' WHERE '), isFalse);
    }

    final version =
        await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), database.schemaVersion);
    expect(database.schemaVersion, 2);
    expect(tables.values.map((table) => table.name), schemaV1TableNames);
    expect(await database.select(database.outboxEntries).get(), isEmpty);
  });

  test('v1 migration changes pending downloads to queued and preserves data',
      () async {
    final snapshot = _decodeSnapshot(await _schemaSnapshot(1).readAsString());
    final executor = NativeDatabase.memory(
      setup: (database) {
        _schemaSql(snapshot).forEach(database.execute);
        database
          ..execute(
            '''
INSERT INTO download (
  package_id, kind, active_version, pending_version, state,
  bytes_total, bytes_done, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''',
            <Object?>[
              'model-1',
              'model',
              '1.0.0',
              '1.1.0',
              'pending',
              100,
              25,
              2000,
            ],
          )
          ..execute('PRAGMA user_version = 1');
      },
    );

    final database = SudurDatabase(executor);
    addTearDown(database.close);
    final migrated = await database.select(database.downloads).getSingle();

    expect(migrated.packageId, 'model-1');
    expect(migrated.kind, DownloadKind.model);
    expect(migrated.activeVersion, '1.0.0');
    expect(migrated.pendingVersion, '1.1.0');
    expect(migrated.state, DownloadState.queued);
    expect(migrated.bytesTotal, 100);
    expect(migrated.bytesDone, 25);
    expect(migrated.updatedAt, 2000);
    final version =
        await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 2);
  });

  test('download stores only the lifecycle states from section 11.4', () {
    expect(
      DownloadState.values.map((state) => state.name),
      <String>[
        'queued',
        'downloading',
        'verifying',
        'installing',
        'installed',
        'failed',
      ],
    );
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

Map<String, Object?> _decodeSnapshot(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, Object?>) {
    fail('Schema snapshot must be a JSON object.');
  }
  return decoded;
}

Map<int, _SnapshotTable> _tables(Map<String, Object?> snapshot) => {
      for (final entity in _entities(snapshot))
        if (entity['type'] == 'table')
          _required<int>(entity, 'id'): _snapshotTable(
            _requiredMap(entity, 'data'),
          ),
    };

List<_SnapshotIndex> _indexes(
  Map<String, Object?> snapshot,
  Map<int, _SnapshotTable> tables,
) =>
    [
      for (final entity in _entities(snapshot))
        if (entity['type'] == 'index')
          _snapshotIndex(_requiredMap(entity, 'data'), tables),
    ];

List<Map<String, Object?>> _entities(Map<String, Object?> snapshot) {
  final entities = snapshot['entities'];
  if (entities is! List<Object?>) {
    fail('Schema snapshot must contain entities.');
  }
  return [
    for (final entity in entities)
      if (entity is Map<String, Object?>)
        entity
      else
        fail('Schema entity must be an object.'),
  ];
}

_SnapshotTable _snapshotTable(Map<String, Object?> data) {
  final primaryKey = _stringList(data['explicit_pk']);
  final rawColumns = data['columns'];
  if (rawColumns is! List<Object?>) fail('Table columns must be a list.');
  final constraints = <String>[];
  final columns = <_SnapshotColumn>[];
  for (final (position, raw) in rawColumns.indexed) {
    if (raw is! Map<String, Object?>) fail('Column must be an object.');
    final name = _required<String>(raw, 'name');
    final defaultConstraint = raw['defaultConstraints'];
    if (defaultConstraint is String) constraints.add(defaultConstraint);
    final customConstraint = raw['customConstraints'];
    if (customConstraint is String) constraints.add(customConstraint);
    columns.add(
      _SnapshotColumn(
        cid: position,
        name: name,
        type: _sqliteType(_required<String>(raw, 'moor_type')),
        notNull: !_required<bool>(raw, 'nullable'),
        defaultValue: null,
        primaryKeyPosition: primaryKey.indexOf(name) + 1,
      ),
    );
  }
  return _SnapshotTable(
    name: _required<String>(data, 'name'),
    columns: columns,
    columnConstraints: constraints,
  );
}

_SnapshotIndex _snapshotIndex(
  Map<String, Object?> data,
  Map<int, _SnapshotTable> tables,
) {
  final rawColumns = data['columns'];
  if (rawColumns is! List<Object?>) fail('Index columns must be a list.');
  final tableId = _required<int>(data, 'on');
  final table = tables[tableId];
  if (table == null) fail('Index refers to an unknown table.');
  return _SnapshotIndex(
    name: _required<String>(data, 'name'),
    table: table.name,
    unique: _required<bool>(data, 'unique'),
    columns: [
      for (final raw in rawColumns)
        if (raw is Map<String, Object?>)
          _required<String>(raw, 'column')
        else
          fail('Index column must be an object.'),
    ],
  );
}

_SnapshotColumn _liveColumn(Map<String, Object?> row) => _SnapshotColumn(
      cid: _required<int>(row, 'cid'),
      name: _required<String>(row, 'name'),
      type: _required<String>(row, 'type'),
      notNull: _required<int>(row, 'notnull') == 1,
      defaultValue: row['dflt_value'],
      primaryKeyPosition: _required<int>(row, 'pk'),
    );

String _sqliteType(String driftType) => switch (driftType) {
      'bool' || 'int' => 'INTEGER',
      'double' => 'REAL',
      'string' => 'TEXT',
      final value => fail('Unsupported drift type in snapshot: $value'),
    };

List<String> _stringList(Object? value) {
  if (value is! List<Object?>) fail('Expected a string list.');
  return [
    for (final item in value)
      if (item is String) item else fail('Expected a string list.'),
  ];
}

Map<String, Object?> _requiredMap(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! Map<String, Object?>) fail('$key must be an object.');
  return field;
}

T _required<T>(Map<String, Object?> value, String key) {
  final field = value[key];
  if (field is! T) fail('$key has an invalid type.');
  return field;
}

String _normalizedSql(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

List<String> _schemaSql(Map<String, Object?> snapshot) {
  final schema = snapshot['fixed_sql'];
  if (schema is! List<Object?>) fail('Schema snapshot must contain SQL.');
  return [
    for (final entity in schema)
      if (entity is Map<String, Object?>)
        for (final dialect in _required<List<Object?>>(entity, 'sql'))
          if (dialect is Map<String, Object?>)
            _required<String>(dialect, 'sql')
          else
            fail('Schema SQL dialect must be an object.')
      else
        fail('Schema SQL entity must be an object.'),
  ];
}

File _schemaSnapshot(int version) {
  final fromRoot = File(
    'packages/storage/drift_schemas/drift_schema_v$version.json',
  );
  return fromRoot.existsSync()
      ? fromRoot
      : File('drift_schemas/drift_schema_v$version.json');
}

final class _SnapshotTable {
  const _SnapshotTable({
    required this.name,
    required this.columns,
    required this.columnConstraints,
  });

  final String name;
  final List<_SnapshotColumn> columns;
  final List<String> columnConstraints;
}

final class _SnapshotIndex {
  const _SnapshotIndex({
    required this.name,
    required this.table,
    required this.unique,
    required this.columns,
  });

  final String name;
  final String table;
  final bool unique;
  final List<String> columns;
}

@immutable
final class _SnapshotColumn {
  const _SnapshotColumn({
    required this.cid,
    required this.name,
    required this.type,
    required this.notNull,
    required this.defaultValue,
    required this.primaryKeyPosition,
  });

  final int cid;
  final String name;
  final String type;
  final bool notNull;
  final Object? defaultValue;
  final int primaryKeyPosition;

  @override
  bool operator ==(Object other) =>
      other is _SnapshotColumn &&
      other.cid == cid &&
      other.name == name &&
      other.type == type &&
      other.notNull == notNull &&
      other.defaultValue == defaultValue &&
      other.primaryKeyPosition == primaryKeyPosition;

  @override
  int get hashCode => Object.hash(
        cid,
        name,
        type,
        notNull,
        defaultValue,
        primaryKeyPosition,
      );

  @override
  String toString() =>
      '$cid:$name $type notNull=$notNull default=$defaultValue '
      'pk=$primaryKeyPosition';
}
