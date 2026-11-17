/// Technical comparison key of a word, produced by a normalizer
/// (docs/tz 10.1).
///
/// A distinct type so that a key can never be passed where Quran text for
/// display is expected: keys are never shown. Lives in `contracts` because
/// the alignment path carries it (ADR 0003); `quran_text` re-exports it.
extension type const SearchKey(String value) {
  /// Whether the key has no characters.
  bool get isEmpty => value.isEmpty;
}
