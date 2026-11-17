// `SearchKey` moved to `contracts` (ADR 0003): the alignment path carries
// it. Re-exported here so `quran_text` users keep one import.
export 'package:contracts/contracts.dart' show SearchKey;

/// Identifier of a normalizer, as in `normalizer.json` of a model package.
extension type const NormalizerId(String value) {}
