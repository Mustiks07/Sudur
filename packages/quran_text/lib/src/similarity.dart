/// Levenshtein distance between [a] and [b], counted in Unicode code points.
int levenshtein(String a, String b) {
  final x = a.runes.toList();
  final y = b.runes.toList();
  if (x.isEmpty) return y.length;
  if (y.isEmpty) return x.length;
  var previous = List<int>.generate(y.length + 1, (j) => j);
  var current = List<int>.filled(y.length + 1, 0);
  for (var i = 1; i <= x.length; i++) {
    current[0] = i;
    for (var j = 1; j <= y.length; j++) {
      final substitution = previous[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1);
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      current[j] = [
        substitution,
        deletion,
        insertion,
      ].reduce((m, v) => v < m ? v : m);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[y.length];
}

/// `1 − levenshtein(a, b) / max(len(a), len(b))` (docs/tz section 10.1):
/// 1 for equal strings, 0 for nothing in common. Two empty strings are
/// equal, so their similarity is 1.
double similarity(String a, String b) {
  final longest =
      a.runes.length > b.runes.length ? a.runes.length : b.runes.length;
  if (longest == 0) return 1;
  return 1 - levenshtein(a, b) / longest;
}

/// Levenshtein distance between code point lists [a] and [b] if it is at
/// most [maxDistance], else `null`. Stops as soon as every cell of a row
/// exceeds the bound, so dissimilar words cost little.
int? boundedLevenshtein(List<int> a, List<int> b, int maxDistance) {
  if ((a.length - b.length).abs() > maxDistance) return null;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (j) => j);
  var current = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    var rowMin = current[0];
    for (var j = 1; j <= b.length; j++) {
      final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      var best = substitution < deletion ? substitution : deletion;
      if (insertion < best) best = insertion;
      current[j] = best;
      if (best < rowMin) rowMin = best;
    }
    if (rowMin > maxDistance) return null;
    final swap = previous;
    previous = current;
    current = swap;
  }
  final d = previous[b.length];
  return d <= maxDistance ? d : null;
}
