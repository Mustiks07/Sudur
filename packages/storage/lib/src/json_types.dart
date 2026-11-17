import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:contracts/contracts.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

const _deepEquality = DeepCollectionEquality();
final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Any validated immutable JSON value.
@immutable
final class JsonValueData {
  /// Validates and freezes [value].
  JsonValueData.fromJson(Object? value) : value = _freezeJson(value);

  /// Decodes, validates and freezes a JSON value.
  factory JsonValueData.decode(String source) {
    return JsonValueData.fromJson(jsonDecode(source));
  }

  /// The immutable JSON value.
  final Object? value;

  /// Returns a JSON-compatible value.
  Object? toJson() => value;

  /// Encodes this value as JSON.
  String encode() => jsonEncode(value);

  @override
  bool operator ==(Object other) =>
      other is JsonValueData && _deepEquality.equals(value, other.value);

  @override
  int get hashCode => _deepEquality.hash(value);
}

/// A validated immutable JSON object.
@immutable
final class JsonObjectData {
  /// Validates and freezes [value].
  JsonObjectData.fromJson(Object? value) : value = _jsonObject(value);

  /// Decodes, validates and freezes a JSON object.
  factory JsonObjectData.decode(String source) {
    return JsonObjectData.fromJson(jsonDecode(source));
  }

  /// The immutable JSON value.
  final Map<String, Object?> value;

  /// Returns a JSON-compatible value.
  Map<String, Object?> toJson() => value;

  /// Encodes this value as JSON.
  String encode() => jsonEncode(value);

  @override
  bool operator ==(Object other) =>
      other is JsonObjectData && _deepEquality.equals(value, other.value);

  @override
  int get hashCode => _deepEquality.hash(value);
}

/// A validated immutable JSON array.
@immutable
final class JsonArrayData {
  /// Validates and freezes [value].
  JsonArrayData.fromJson(Object? value) : value = _jsonArray(value);

  /// Decodes, validates and freezes a JSON array.
  factory JsonArrayData.decode(String source) {
    return JsonArrayData.fromJson(jsonDecode(source));
  }

  /// The immutable JSON value.
  final List<Object?> value;

  /// Returns a JSON-compatible value.
  List<Object?> toJson() => value;

  /// Encodes this value as JSON.
  String encode() => jsonEncode(value);

  @override
  bool operator ==(Object other) =>
      other is JsonArrayData && _deepEquality.equals(value, other.value);

  @override
  int get hashCode => _deepEquality.hash(value);
}

/// Hint counts keyed by hint kind.
@immutable
final class HintCounts {
  /// Validates and freezes [value].
  HintCounts.fromJson(Object? value) : value = _intMap(value, 'hints');

  /// Hint count by kind.
  final Map<String, int> value;

  /// Returns a JSON-compatible value.
  Map<String, int> toJson() => value;

  @override
  bool operator ==(Object other) =>
      other is HintCounts && _deepEquality.equals(value, other.value);

  @override
  int get hashCode => _deepEquality.hash(value);
}

/// Check-event identifiers attached to an attempt.
@immutable
final class ErrorEventIds {
  /// Validates and freezes [value].
  ErrorEventIds.fromJson(Object? value)
      : value = _stringList(value, 'error_event_ids');

  /// Event identifiers.
  final List<String> value;

  /// Returns a JSON-compatible value.
  List<String> toJson() => value;

  @override
  bool operator ==(Object other) =>
      other is ErrorEventIds && _deepEquality.equals(value, other.value);

  @override
  int get hashCode => _deepEquality.hash(value);
}

/// Word indexes attached to a check event or search n-gram.
@immutable
final class WordIndexes {
  /// Validates and freezes [value].
  WordIndexes.fromJson(Object? value) : value = _intList(value, 'word_indexes');

  /// Quran-wide word indexes.
  final List<int> value;

  /// Returns a JSON-compatible value.
  List<int> toJson() => value;

  @override
  bool operator ==(Object other) =>
      other is WordIndexes && _deepEquality.equals(value, other.value);

  @override
  int get hashCode => _deepEquality.hash(value);
}

/// Typed session summary JSON.
@immutable
final class SessionSummary {
  /// Validates and freezes [value].
  SessionSummary.fromJson(Object? value)
      : data = JsonObjectData.fromJson(value);

  /// Summary fields.
  final JsonObjectData data;

  /// Returns a JSON-compatible value.
  Map<String, Object?> toJson() => data.toJson();

  @override
  bool operator ==(Object other) =>
      other is SessionSummary && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Typed list of daily-plan items.
@immutable
final class DailyPlanItems {
  /// Validates and freezes [value].
  DailyPlanItems.fromJson(Object? value) : data = JsonArrayData.fromJson(value);

  /// Plan items.
  final JsonArrayData data;

  /// Returns a JSON-compatible value.
  List<Object?> toJson() => data.toJson();

  @override
  bool operator ==(Object other) =>
      other is DailyPlanItems && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Validated metadata for a consented recording upload (spec 12.5).
@immutable
final class UploadMetadata {
  /// Validates and freezes [value].
  UploadMetadata.fromJson(Object? value)
      : data = JsonObjectData.fromJson(value) {
    _validateUploadMetadata(data.value);
  }

  /// Metadata fields.
  final JsonObjectData data;

  /// Returns a JSON-compatible value.
  Map<String, Object?> toJson() => data.toJson();

  @override
  bool operator ==(Object other) =>
      other is UploadMetadata && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Converts [JsonObjectData] to a SQLite JSON string.
final class JsonObjectConverter extends TypeConverter<JsonObjectData, String> {
  /// Creates the converter.
  const JsonObjectConverter();

  @override
  JsonObjectData fromSql(String fromDb) => JsonObjectData.decode(fromDb);

  @override
  String toSql(JsonObjectData value) => value.encode();
}

/// Converts [JsonValueData] to a SQLite JSON string.
final class JsonValueConverter extends TypeConverter<JsonValueData, String> {
  /// Creates the converter.
  const JsonValueConverter();

  @override
  JsonValueData fromSql(String fromDb) => JsonValueData.decode(fromDb);

  @override
  String toSql(JsonValueData value) => value.encode();
}

/// Converts [HintCounts] to a SQLite JSON string.
final class HintCountsConverter extends TypeConverter<HintCounts, String> {
  /// Creates the converter.
  const HintCountsConverter();

  @override
  HintCounts fromSql(String fromDb) => HintCounts.fromJson(jsonDecode(fromDb));

  @override
  String toSql(HintCounts value) => jsonEncode(value.toJson());
}

/// Converts [ErrorEventIds] to a SQLite JSON string.
final class ErrorEventIdsConverter
    extends TypeConverter<ErrorEventIds, String> {
  /// Creates the converter.
  const ErrorEventIdsConverter();

  @override
  ErrorEventIds fromSql(String fromDb) =>
      ErrorEventIds.fromJson(jsonDecode(fromDb));

  @override
  String toSql(ErrorEventIds value) => jsonEncode(value.toJson());
}

/// Converts [WordIndexes] to a SQLite JSON string.
final class WordIndexesConverter extends TypeConverter<WordIndexes, String> {
  /// Creates the converter.
  const WordIndexesConverter();

  @override
  WordIndexes fromSql(String fromDb) =>
      WordIndexes.fromJson(jsonDecode(fromDb));

  @override
  String toSql(WordIndexes value) => jsonEncode(value.toJson());
}

/// Converts [ReadingVersions] to a validated SQLite JSON string.
final class ReadingVersionsConverter
    extends TypeConverter<ReadingVersions, String> {
  /// Creates the converter.
  const ReadingVersionsConverter();

  @override
  ReadingVersions fromSql(String fromDb) {
    final object = _jsonObject(jsonDecode(fromDb));
    final model = _requiredString(object, 'model');
    final separator = model.lastIndexOf('@');
    if (separator <= 0 || separator == model.length - 1) {
      throw const FormatException('versions.model must contain id@version.');
    }
    return ReadingVersions(
      modelId: model.substring(0, separator),
      modelVersion: model.substring(separator + 1),
      rulesVersion: _requiredString(object, 'rules'),
      textVersion: _requiredString(object, 'text'),
    );
  }

  @override
  String toSql(ReadingVersions value) => jsonEncode(value.toJson());
}

/// Converts [SessionSummary] to a SQLite JSON string.
final class SessionSummaryConverter
    extends TypeConverter<SessionSummary, String> {
  /// Creates the converter.
  const SessionSummaryConverter();

  @override
  SessionSummary fromSql(String fromDb) =>
      SessionSummary.fromJson(jsonDecode(fromDb));

  @override
  String toSql(SessionSummary value) => jsonEncode(value.toJson());
}

/// Converts [DailyPlanItems] to a SQLite JSON string.
final class DailyPlanItemsConverter
    extends TypeConverter<DailyPlanItems, String> {
  /// Creates the converter.
  const DailyPlanItemsConverter();

  @override
  DailyPlanItems fromSql(String fromDb) =>
      DailyPlanItems.fromJson(jsonDecode(fromDb));

  @override
  String toSql(DailyPlanItems value) => jsonEncode(value.toJson());
}

/// Converts [UploadMetadata] to a SQLite JSON string.
final class UploadMetadataConverter
    extends TypeConverter<UploadMetadata, String> {
  /// Creates the converter.
  const UploadMetadataConverter();

  @override
  UploadMetadata fromSql(String fromDb) =>
      UploadMetadata.fromJson(jsonDecode(fromDb));

  @override
  String toSql(UploadMetadata value) => jsonEncode(value.toJson());
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw const FormatException('JSON object keys must be strings.');
    }
    result[key] = _freezeJson(entry.value);
  }
  return Map<String, Object?>.unmodifiable(result);
}

List<Object?> _jsonArray(Object? value) {
  if (value is! List<Object?>) {
    throw const FormatException('Expected a JSON array.');
  }
  return List<Object?>.unmodifiable(value.map(_freezeJson));
}

Object? _freezeJson(Object? value) {
  if (value == null || value is String || value is bool || value is num) {
    return value;
  }
  if (value is Map<Object?, Object?>) {
    return _jsonObject(value);
  }
  if (value is List<Object?>) {
    return _jsonArray(value);
  }
  throw FormatException('Unsupported JSON value: ${value.runtimeType}.');
}

Map<String, int> _intMap(Object? value, String field) {
  final object = _jsonObject(value);
  final result = <String, int>{};
  for (final entry in object.entries) {
    final count = entry.value;
    if (count is! int || count < 0) {
      throw FormatException('$field values must be non-negative integers.');
    }
    result[entry.key] = count;
  }
  return Map<String, int>.unmodifiable(result);
}

List<String> _stringList(Object? value, String field) {
  final array = _jsonArray(value);
  if (array.any((item) => item is! String)) {
    throw FormatException('$field must contain strings.');
  }
  return List<String>.unmodifiable(array.cast<String>());
}

List<int> _intList(Object? value, String field) {
  final array = _jsonArray(value);
  if (array.any((item) => item is! int)) {
    throw FormatException('$field must contain integers.');
  }
  return List<int>.unmodifiable(array.cast<int>());
}

String _requiredString(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

Map<String, Object?> _requiredObject(
  Map<String, Object?> object,
  String key,
) {
  final value = object[key];
  if (value is! Map<String, Object?>) {
    throw FormatException('$key must be an object.');
  }
  return value;
}

List<Object?> _requiredArray(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! List<Object?>) {
    throw FormatException('$key must be an array.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! int) {
    throw FormatException('$key must be an integer.');
  }
  return value;
}

bool _requiredBool(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! bool) {
    throw FormatException('$key must be a boolean.');
  }
  return value;
}

void _validateUploadMetadata(Map<String, Object?> value) {
  if (_requiredInt(value, 'schema') != 1) {
    throw const FormatException('Unsupported upload metadata schema.');
  }
  final installId = _requiredString(value, 'installId');
  if (!_uuidV4.hasMatch(installId)) {
    throw const FormatException('installId must be a UUID v4.');
  }
  _requiredString(value, 'consentVersion');
  final recordedAt = DateTime.tryParse(_requiredString(value, 'recordedAt'));
  if (recordedAt == null || !recordedAt.isUtc) {
    throw const FormatException('recordedAt must be an ISO-8601 UTC time.');
  }
  final range = _requiredObject(value, 'range');
  _requiredString(range, 'from');
  _requiredString(range, 'to');
  _requiredString(value, 'mode');
  final device = _requiredObject(value, 'device');
  _requiredString(device, 'model');
  _requiredString(device, 'os');
  final versions = _requiredObject(value, 'versions');
  for (final key in <String>['app', 'model', 'rules', 'text']) {
    _requiredString(versions, key);
  }
  for (final item in _requiredArray(value, 'asr')) {
    final object = _jsonObject(item);
    _requiredInt(object, 'segmentId');
    _requiredBool(object, 'isFinal');
    _requiredString(object, 'text');
    _requiredInt(object, 'startMs');
    _requiredInt(object, 'endMs');
  }
  for (final item in _requiredArray(value, 'events')) {
    final object = _jsonObject(item);
    _requiredString(object, 'kind');
    _requiredString(object, 'state');
    _requiredString(object, 'wordKey');
    _requiredString(object, 'heard');
  }
  final audio = _requiredObject(value, 'audio');
  _requiredString(audio, 'codec');
  _requiredInt(audio, 'bitrateKbps');
  _requiredInt(audio, 'durationMs');
  _requiredString(audio, 'sha256');
}
