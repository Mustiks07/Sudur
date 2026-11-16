import 'package:meta/meta.dart';

/// Search parameters (docs/tz section 12.4, group «Следование»).
@immutable
final class SearchParams {
  /// Creates search parameters.
  const SearchParams({required this.ngramSize});

  /// Built-in values of docs/tz section 12.4, used until a model package
  /// provides `thresholds.json`.
  static const SearchParams defaults = SearchParams(ngramSize: 3);

  /// Number of consecutive words in one index entry (`ngramSize`).
  final int ngramSize;
}
