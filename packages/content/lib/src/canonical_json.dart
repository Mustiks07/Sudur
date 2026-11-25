import 'dart:convert';

/// The canonical form of a JSON value that a manifest signature covers
/// (docs/tz 12.3): object keys sorted, no whitespace.
///
/// Numbers are written as Dart writes them (`jsonEncode`): the shortest
/// spelling that reads back to the same value. The signer
/// (`tools/content_build`) is Dart too, so both sides agree; NaN and
/// infinity are not JSON and are refused.
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
      case final double d when d.isFinite:
        out.write(jsonEncode(d));
      case double():
        throw FormatException('Not a finite number', v);
      default:
        throw FormatException('Not a JSON value', v);
    }
  }

  write(value);
  return out.toString();
}
