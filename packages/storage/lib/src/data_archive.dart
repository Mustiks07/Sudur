import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:contracts/contracts.dart';
import 'package:drift/drift.dart';
import 'package:storage/src/database.dart';
import 'package:storage/src/json_types.dart';
import 'package:storage/src/storage_exception.dart';

const _archiveFormat = 'sudur-user-data';
const _manifestName = 'manifest.json';

/// Resource limits applied before an imported archive is decoded.
final class StorageArchiveLimits {
  /// Creates archive limits.
  const StorageArchiveLimits({
    this.maxArchiveBytes = 64 * 1024 * 1024,
    this.maxEntryBytes = 32 * 1024 * 1024,
  });

  /// Maximum compressed archive size.
  final int maxArchiveBytes;

  /// Maximum uncompressed size of one entry.
  final int maxEntryBytes;
}

/// Exports and atomically imports every user-database table.
final class UserDataArchiveService {
  /// Creates the service.
  const UserDataArchiveService(
    this._database, {
    StorageArchiveLimits limits = const StorageArchiveLimits(),
  }) : _limits = limits;

  final SudurDatabase _database;
  final StorageArchiveLimits _limits;

  /// Exports schema metadata and every table as JSON files in a zip archive.
  Future<Result<Uint8List>> exportData() => _guard(() async {
        final archive = Archive()
          ..addFile(
            ArchiveFile.string(
              _manifestName,
              jsonEncode(<String, Object?>{
                'format': _archiveFormat,
                'schemaVersion': _database.schemaVersion,
              }),
            ),
          );
        for (final table in _tables) {
          final rows = await _database
              .customSelect('SELECT * FROM "${table.name}"')
              .get();
          final jsonRows = rows
              .map(
                (row) => <String, Object?>{
                  for (final column in table.columns)
                    column.name: column.exportValue(row),
                },
              )
              .toList(growable: false);
          archive.addFile(
            ArchiveFile.string('${table.name}.json', jsonEncode(jsonRows)),
          );
        }
        return ZipEncoder().encodeBytes(archive);
      });

  /// Validates [bytes], then replaces all database rows in one transaction.
  Future<Result<void>> importData(Uint8List bytes) => _guard(() async {
        if (bytes.length > _limits.maxArchiveBytes) {
          throw const FormatException('User-data archive is too large.');
        }
        final archive = ZipDecoder().decodeBytes(bytes, verify: true);
        final expectedNames = <String>{
          _manifestName,
          for (final table in _tables) '${table.name}.json',
        };
        final entries = <String, ArchiveFile>{};
        for (final entry in archive) {
          _validateEntry(entry, expectedNames);
          if (entry.size > _limits.maxEntryBytes) {
            throw FormatException('${entry.name} is too large.');
          }
          if (entries.containsKey(entry.name)) {
            throw FormatException('Duplicate archive entry: ${entry.name}.');
          }
          entries[entry.name] = entry;
        }
        if (entries.keys.toSet().difference(expectedNames).isNotEmpty ||
            expectedNames.difference(entries.keys.toSet()).isNotEmpty) {
          throw const FormatException(
            'User-data archive entries are incomplete.',
          );
        }

        final manifest = _decodeObject(entries[_manifestName], _manifestName);
        if (manifest['format'] != _archiveFormat ||
            manifest['schemaVersion'] != _database.schemaVersion) {
          throw const FormatException('Unsupported user-data archive version.');
        }

        final decoded = <_TableSpec, List<Map<String, Object?>>>{};
        for (final table in _tables) {
          final name = '${table.name}.json';
          decoded[table] = _decodeRows(entries[name], table);
        }

        await _database.transaction(() async {
          for (final table in _tables.reversed) {
            await _database.customStatement('DELETE FROM "${table.name}"');
          }
          for (final table in _tables) {
            for (final row
                in decoded[table] ?? const <Map<String, Object?>>[]) {
              await _insertRow(table, row);
            }
          }
        });
      });

  Future<void> _insertRow(
    _TableSpec table,
    Map<String, Object?> row,
  ) async {
    final names = table.columns.map((column) => '"${column.name}"').join(', ');
    final placeholders =
        List<String>.filled(table.columns.length, '?').join(', ');
    final variables = <Variable<Object>>[
      for (final column in table.columns) column.importValue(row[column.name]),
    ];
    await _database.customInsert(
      'INSERT INTO "${table.name}" ($names) VALUES ($placeholders)',
      variables: variables,
    );
  }

  void _validateEntry(ArchiveFile entry, Set<String> expectedNames) {
    final name = entry.name;
    if (!entry.isFile ||
        entry.isSymbolicLink ||
        name.contains('/') ||
        name.contains(r'\') ||
        name == '.' ||
        name == '..' ||
        !expectedNames.contains(name)) {
      throw FormatException('Unsafe or unexpected archive entry: $name.');
    }
  }
}

Map<String, Object?> _decodeObject(ArchiveFile? entry, String name) {
  final bytes = entry?.readBytes();
  if (bytes == null) {
    throw FormatException('$name has no content.');
  }
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map<Object?, Object?>) {
    throw FormatException('$name must contain a JSON object.');
  }
  final result = <String, Object?>{};
  for (final item in decoded.entries) {
    final key = item.key;
    if (key is! String) {
      throw FormatException('$name has a non-string key.');
    }
    result[key] = item.value;
  }
  return result;
}

List<Map<String, Object?>> _decodeRows(
  ArchiveFile? entry,
  _TableSpec table,
) {
  final bytes = entry?.readBytes();
  if (bytes == null) {
    throw FormatException('${table.name}.json has no content.');
  }
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! List<Object?>) {
    throw FormatException('${table.name}.json must contain a JSON array.');
  }
  return decoded.map((item) {
    if (item is! Map<Object?, Object?>) {
      throw FormatException('${table.name}.json rows must be objects.');
    }
    final row = <String, Object?>{};
    for (final pair in item.entries) {
      final key = pair.key;
      if (key is! String) {
        throw FormatException('${table.name}.json has a non-string key.');
      }
      row[key] = pair.value;
    }
    final expected = table.columns.map((column) => column.name).toSet();
    if (row.keys.toSet().difference(expected).isNotEmpty ||
        expected.difference(row.keys.toSet()).isNotEmpty) {
      throw FormatException('${table.name}.json has invalid columns.');
    }
    for (final column in table.columns) {
      column.validateJson(row[column.name]);
    }
    return Map<String, Object?>.unmodifiable(row);
  }).toList(growable: false);
}

Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
  try {
    return Result<T>.ok(await operation());
  } on Exception catch (error) {
    return Result<T>.error(error);
  } on Object catch (_) {
    return Result<T>.error(const StorageException('invalidArchive'));
  }
}

enum _ColumnType { text, integer, real, boolean, json }

final class _ColumnSpec {
  const _ColumnSpec(
    this.name,
    this.type, {
    this.nullable = false,
    this.validateJsonValue,
    this.allowedStrings,
  });

  final String name;
  final _ColumnType type;
  final bool nullable;
  final void Function(Object?)? validateJsonValue;
  final Set<String>? allowedStrings;

  Object? exportValue(QueryRow row) {
    final value = switch (type) {
      _ColumnType.text || _ColumnType.json => row.readNullable<String>(name),
      _ColumnType.integer => row.readNullable<int>(name),
      _ColumnType.real => row.readNullable<double>(name),
      _ColumnType.boolean => row.readNullable<bool>(name),
    };
    if (type == _ColumnType.json && value != null) {
      final decoded = jsonDecode(value as String);
      validateJsonValue?.call(decoded);
      return decoded;
    }
    return value;
  }

  void validateJson(Object? value) {
    if (value == null) {
      if (!nullable) {
        throw FormatException('$name may not be null.');
      }
      return;
    }
    final valid = switch (type) {
      _ColumnType.text => value is String,
      _ColumnType.integer => value is int,
      _ColumnType.real => value is num,
      _ColumnType.boolean => value is bool,
      _ColumnType.json => true,
    };
    if (!valid) {
      throw FormatException('$name has an invalid type.');
    }
    final allowed = allowedStrings;
    if (value is String && allowed != null && !allowed.contains(value)) {
      throw FormatException('$name has an unsupported value.');
    }
    validateJsonValue?.call(value);
  }

  Variable<Object> importValue(Object? value) {
    if (value == null) {
      return const Variable<Object>(null);
    }
    return switch (type) {
      _ColumnType.text => Variable<String>(value as String),
      _ColumnType.integer => Variable<int>(value as int),
      _ColumnType.real => Variable<double>((value as num).toDouble()),
      _ColumnType.boolean => Variable<bool>(value as bool),
      _ColumnType.json => Variable<String>(jsonEncode(value)),
    };
  }
}

final class _TableSpec {
  const _TableSpec(this.name, this.columns);

  final String name;
  final List<_ColumnSpec> columns;
}

const _ColumnType _text = _ColumnType.text;
const _ColumnType _int = _ColumnType.integer;
const _ColumnType _real = _ColumnType.real;
const _ColumnType _bool = _ColumnType.boolean;
const _ColumnType _json = _ColumnType.json;

void _jsonObject(Object? value) => JsonObjectData.fromJson(value);
void _jsonValue(Object? value) => JsonValueData.fromJson(value);
void _hints(Object? value) => HintCounts.fromJson(value);
void _errorIds(Object? value) => ErrorEventIds.fromJson(value);
void _wordIndexes(Object? value) => WordIndexes.fromJson(value);
void _versions(Object? value) =>
    const ReadingVersionsConverter().fromSql(jsonEncode(value));
void _summary(Object? value) => SessionSummary.fromJson(value);
void _items(Object? value) => DailyPlanItems.fromJson(value);
void _uploadMeta(Object? value) => UploadMetadata.fromJson(value);
final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

void _uuid(Object? value) {
  if (value is! String || !_uuidV4.hasMatch(value)) {
    throw const FormatException('Identifier must be a UUID v4.');
  }
}

void _date(Object? value) {
  if (value is! String ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      DateTime.tryParse(value) == null) {
    throw const FormatException('Date must use YYYY-MM-DD.');
  }
}

const _languages = <String>{'ru', 'kk', 'uz'};
const _paths = <String>{'read', 'hifz', 'restore'};
const _behaviors = <String>{'gentle', 'strict'};
const _unitKinds = <String>{'passage', 'junction', 'hardSpot', 'skill'};
const _unitOrigins = <String>{'default', 'knownBefore', 'error', 'lesson'};
const _queues = <String>{'notStarted', 'learning', 'recent', 'old', 'closed'};
const _methods = <String>{'voice', 'self', 'listener'};
const _modes = <String>{'supported', 'recall', 'test', 'self'};
const _outcomes = <String>{
  'clean',
  'withHints',
  'corrected',
  'withErrors',
  'unverified',
  'disputed',
};
const _ratings = <String>{'again', 'hard', 'good', 'easy'};
const _checkKinds = <String>{
  'omission',
  'substitution',
  'insertion',
  'jump',
  'repetition',
  'hesitation',
};
const _checkStates = <String>{
  'preliminary',
  'confirmed',
  'corrected',
  'unverified',
  'disputed',
};
const _lessonStates = <String>{
  'locked',
  'available',
  'inProgress',
  'quiz',
  'passed',
  'failed',
};
const _downloadKinds = <String>{
  'text',
  'layout',
  'font',
  'audio',
  'model',
  'lessons',
  'translation',
  'config',
};
const _downloadStates = <String>{
  'pending',
  'downloading',
  'installed',
  'failed',
};
const _uploadStates = <String>{'queued', 'uploading', 'uploaded', 'failed'};
const _entitlementStates = <String>{
  'free',
  'trial',
  'active',
  'grace',
  'expiredOffline',
  'expired',
};

const _tables = <_TableSpec>[
  _TableSpec('profile', <_ColumnSpec>[
    _ColumnSpec('id', _text, validateJsonValue: _uuid),
    _ColumnSpec('created_at', _int),
    _ColumnSpec('ui_language', _text, allowedStrings: _languages),
    _ColumnSpec('path', _text, allowedStrings: _paths),
    _ColumnSpec('daily_minutes', _int),
    _ColumnSpec('behavior', _text, allowedStrings: _behaviors),
    _ColumnSpec('show_first_word', _bool),
  ]),
  _TableSpec('unit', <_ColumnSpec>[
    _ColumnSpec('id', _text, validateJsonValue: _uuid),
    _ColumnSpec('profile_id', _text, validateJsonValue: _uuid),
    _ColumnSpec('kind', _text, allowedStrings: _unitKinds),
    _ColumnSpec('from_word_index', _int, nullable: true),
    _ColumnSpec('to_word_index', _int, nullable: true),
    _ColumnSpec('skill_id', _text, nullable: true),
    _ColumnSpec('surah', _int, nullable: true),
    _ColumnSpec('origin', _text, allowedStrings: _unitOrigins),
    _ColumnSpec(
      'parent_unit_id',
      _text,
      nullable: true,
      validateJsonValue: _uuid,
    ),
    _ColumnSpec('created_at', _int),
  ]),
  _TableSpec('unit_state', <_ColumnSpec>[
    _ColumnSpec('unit_id', _text, validateJsonValue: _uuid),
    _ColumnSpec('queue', _text, allowedStrings: _queues),
    _ColumnSpec(
      'memory_state',
      _json,
      nullable: true,
      validateJsonValue: _jsonObject,
    ),
    _ColumnSpec(
      'fsrs_card',
      _json,
      nullable: true,
      validateJsonValue: _jsonObject,
    ),
    _ColumnSpec('due_at', _int, nullable: true),
    _ColumnSpec('recent_since', _int, nullable: true),
    _ColumnSpec('last_attempt_at', _int, nullable: true),
    _ColumnSpec('last_method', _text, nullable: true, allowedStrings: _methods),
    _ColumnSpec('updated_at', _int),
  ]),
  _TableSpec('attempt', <_ColumnSpec>[
    _ColumnSpec('id', _text, validateJsonValue: _uuid),
    _ColumnSpec('unit_id', _text, validateJsonValue: _uuid),
    _ColumnSpec('session_id', _text, validateJsonValue: _uuid),
    _ColumnSpec('mode', _text, allowedStrings: _modes),
    _ColumnSpec('outcome', _text, allowedStrings: _outcomes),
    _ColumnSpec('hints', _json, validateJsonValue: _hints),
    _ColumnSpec('error_event_ids', _json, validateJsonValue: _errorIds),
    _ColumnSpec('rating', _text, nullable: true, allowedStrings: _ratings),
    _ColumnSpec('method', _text, allowedStrings: _methods),
    _ColumnSpec('duration_ms', _int),
    _ColumnSpec('words', _int),
    _ColumnSpec('model_id', _text),
    _ColumnSpec('model_version', _text),
    _ColumnSpec('rules_version', _text),
    _ColumnSpec('text_version', _text),
    _ColumnSpec('created_at', _int),
  ]),
  _TableSpec('check_event', <_ColumnSpec>[
    _ColumnSpec('id', _text, validateJsonValue: _uuid),
    _ColumnSpec('session_id', _text, validateJsonValue: _uuid),
    _ColumnSpec('kind', _text, allowedStrings: _checkKinds),
    _ColumnSpec('state', _text, allowedStrings: _checkStates),
    _ColumnSpec('word_indexes', _json, validateJsonValue: _wordIndexes),
    _ColumnSpec('expected_text', _text),
    _ColumnSpec('heard_text', _text),
    _ColumnSpec('jump_from_word_index', _int, nullable: true),
    _ColumnSpec('jump_to_word_index', _int, nullable: true),
    _ColumnSpec('audio_start_ms', _int),
    _ColumnSpec('audio_end_ms', _int),
    _ColumnSpec('versions', _json, validateJsonValue: _versions),
    _ColumnSpec('created_at', _int),
    _ColumnSpec('updated_at', _int),
  ]),
  _TableSpec('session', <_ColumnSpec>[
    _ColumnSpec('id', _text, validateJsonValue: _uuid),
    _ColumnSpec('profile_id', _text, validateJsonValue: _uuid),
    _ColumnSpec('from_word_index', _int),
    _ColumnSpec('to_word_index', _int),
    _ColumnSpec('mode', _text, allowedStrings: _modes),
    _ColumnSpec('behavior', _text, allowedStrings: _behaviors),
    _ColumnSpec('started_at', _int),
    _ColumnSpec('ended_at', _int, nullable: true),
    _ColumnSpec('listening_ms', _int),
    _ColumnSpec('signal_ok_ratio', _real, nullable: true),
    _ColumnSpec('summary', _json, nullable: true, validateJsonValue: _summary),
  ]),
  _TableSpec('daily_plan', <_ColumnSpec>[
    _ColumnSpec('date', _text, validateJsonValue: _date),
    _ColumnSpec('items', _json, validateJsonValue: _items),
    _ColumnSpec('created_at', _int),
  ]),
  _TableSpec('lesson_progress', <_ColumnSpec>[
    _ColumnSpec('lesson_id', _text),
    _ColumnSpec('state', _text, allowedStrings: _lessonStates),
    _ColumnSpec('step_index', _int),
    _ColumnSpec('quiz_percent', _int),
    _ColumnSpec('content_version', _text),
    _ColumnSpec('updated_at', _int),
  ]),
  _TableSpec('setting', <_ColumnSpec>[
    _ColumnSpec('key', _text),
    _ColumnSpec('value', _json, validateJsonValue: _jsonValue),
  ]),
  _TableSpec('download', <_ColumnSpec>[
    _ColumnSpec('package_id', _text),
    _ColumnSpec('kind', _text, allowedStrings: _downloadKinds),
    _ColumnSpec('active_version', _text, nullable: true),
    _ColumnSpec('pending_version', _text, nullable: true),
    _ColumnSpec('state', _text, allowedStrings: _downloadStates),
    _ColumnSpec('bytes_total', _int),
    _ColumnSpec('bytes_done', _int),
    _ColumnSpec('updated_at', _int),
  ]),
  _TableSpec('search_key_cache', <_ColumnSpec>[
    _ColumnSpec('normalizer_id', _text),
    _ColumnSpec('word_index', _int),
    _ColumnSpec('key', _text),
  ]),
  _TableSpec('ngram_cache', <_ColumnSpec>[
    _ColumnSpec('normalizer_id', _text),
    _ColumnSpec('ngram', _text),
    _ColumnSpec('word_indexes', _json, validateJsonValue: _wordIndexes),
  ]),
  _TableSpec('saved_recording', <_ColumnSpec>[
    _ColumnSpec('id', _text, validateJsonValue: _uuid),
    _ColumnSpec('session_id', _text, validateJsonValue: _uuid),
    _ColumnSpec('path', _text),
    _ColumnSpec('duration_ms', _int),
    _ColumnSpec('created_at', _int),
  ]),
  _TableSpec('upload_queue', <_ColumnSpec>[
    _ColumnSpec('id', _text, validateJsonValue: _uuid),
    _ColumnSpec('session_id', _text, validateJsonValue: _uuid),
    _ColumnSpec('file_path', _text),
    _ColumnSpec('meta', _json, validateJsonValue: _uploadMeta),
    _ColumnSpec('priority', _int),
    _ColumnSpec('bytes', _int),
    _ColumnSpec('state', _text, allowedStrings: _uploadStates),
    _ColumnSpec('tries', _int),
    _ColumnSpec('created_at', _int),
  ]),
  _TableSpec('entitlement_cache', <_ColumnSpec>[
    _ColumnSpec('id', _text),
    _ColumnSpec('state', _text, allowedStrings: _entitlementStates),
    _ColumnSpec('expires_at', _int, nullable: true),
    _ColumnSpec('last_verified_at', _int),
  ]),
  _TableSpec('free_usage', <_ColumnSpec>[
    _ColumnSpec('date', _text, validateJsonValue: _date),
    _ColumnSpec('listening_ms', _int),
  ]),
  _TableSpec('outbox', <_ColumnSpec>[
    _ColumnSpec('id', _text, validateJsonValue: _uuid),
    _ColumnSpec('event', _json, validateJsonValue: _jsonObject),
    _ColumnSpec('created_at', _int),
  ]),
];
