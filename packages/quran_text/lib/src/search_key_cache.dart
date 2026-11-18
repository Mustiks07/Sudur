import 'package:contracts/contracts.dart';
import 'package:quran_text/src/search_key.dart';

/// Where search keys built for a normalizer are kept between app starts —
/// the user database table `search_key_cache (normalizer_id, word_index,
/// key)` (docs/tz 12.1, made by `storage`, task O04).
///
/// Keys depend on the normalizer of the installed model and on the content
/// text, so a cache entry is valid only for the same [NormalizerId] and the
/// same text version. Building keys for the whole Quran takes about 0.2 s
/// on a computer and an estimated 1–2 s on a budget phone (README), so they
/// are built once when a model is installed, in a separate isolate, and
/// read from here afterwards. The n-gram index is rebuilt from cached keys
/// in memory: that is the cheaper half (README), so `ngram_cache` stays
/// optional.
abstract interface class SearchKeyCache {
  /// Keys of every word in reading order, or `null` if none are cached for
  /// [normalizer] and [textVersion].
  Result<List<SearchKey>?> read(NormalizerId normalizer, String textVersion);

  /// Stores [keys] (one per word, in reading order).
  Result<void> write(
    NormalizerId normalizer,
    String textVersion,
    List<SearchKey> keys,
  );
}
