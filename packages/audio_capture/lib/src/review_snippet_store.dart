import 'dart:collection';

import 'package:audio_capture/src/audio_snippet.dart';

/// Bounded, in-memory-only snippets associated with check event identifiers.
///
/// The rolling capture ring remains transient. Only snippets explicitly
/// retained for review live here, and [closeReview] releases all of them.
final class ReviewSnippetStore {
  /// Creates an empty store capped at [maxBytes].
  ReviewSnippetStore({required this.maxBytes})
      : assert(maxBytes > 0, 'maxBytes must be positive.');

  /// Maximum retained sample memory.
  final int maxBytes;

  final LinkedHashMap<String, AudioSnippet> _snippets =
      LinkedHashMap<String, AudioSnippet>();
  var _retainedBytes = 0;

  /// Bytes currently held by snippet sample buffers.
  int get retainedBytes => _retainedBytes;

  /// Number of review events with retained audio.
  int get length => _snippets.length;

  /// Stores [snippet] for [eventId], evicting oldest events if needed.
  ///
  /// Returns false when this single snippet exceeds the entire budget.
  bool retain(String eventId, AudioSnippet snippet) {
    final bytes = snippet.samples.lengthInBytes;
    if (bytes > maxBytes) return false;
    release(eventId);
    while (_retainedBytes + bytes > maxBytes && _snippets.isNotEmpty) {
      release(_snippets.keys.first);
    }
    _snippets[eventId] = snippet;
    _retainedBytes += bytes;
    return true;
  }

  /// Returns the snippet retained for [eventId], if it is still available.
  AudioSnippet? operator [](String eventId) => _snippets[eventId];

  /// Releases one event's snippet.
  void release(String eventId) {
    final removed = _snippets.remove(eventId);
    if (removed != null) _retainedBytes -= removed.samples.lengthInBytes;
  }

  /// Releases every snippet when the review screen is closed.
  void closeReview() {
    _snippets.clear();
    _retainedBytes = 0;
  }
}
