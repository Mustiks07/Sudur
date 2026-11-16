/// Technical comparison key of a word, produced by a `Normalizer`.
///
/// A distinct type so that a key can never be passed where Quran text for
/// display is expected (docs/tz section 10.1: keys are never shown).
extension type const SearchKey(String value) {
  /// Whether the key has no characters.
  bool get isEmpty => value.isEmpty;
}

/// Identifier of a normalizer, as in `normalizer.json` of a model package.
extension type const NormalizerId(String value) {}
