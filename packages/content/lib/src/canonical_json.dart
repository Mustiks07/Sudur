import 'dart:convert';

/// The canonical form of a JSON value that a manifest signature covers
/// (docs/tz 12.3): object keys sorted, no whitespace.
///
/// Only integers are allowed as numbers: a fractional number has no single
/// spelling across languages, and the manifest needs none.
///
/// Throws [FormatException] for a value that is not plain JSON.
String canonicalJson(Object? value) {
  final out = StringBuffer();
  void write(Object? v) {
    switch (v) {
      case null || bool() || String() || int():
        out.write(jsonEncode(v));
      case final Map<String, Object?> map:
        final keys = map.keys.toList()..sort();
        out.write('{');
        for (final (i, k) in keys.indexed) {
          if (i > 0) out.write(',');
          out
            ..write(jsonEncode(k))
            ..write(':');
          write(map[k]);
        }
        out.write('}');
      case final List<Object?> list:
        out.write('[');
        for (final (i, e) in list.indexed) {
          if (i > 0) out.write(',');
          write(e);
        }
        out.write(']');
      case double():
        throw FormatException('A manifest number must be an integer', v);
      default:
        throw FormatException('Not a JSON value', v);
    }
  }

  write(value);
  return out.toString();
}
