import 'dart:io';

import 'package:content_build/src/content_build_exception.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Gets source files, downloading them once into a local cache.
abstract interface class SourceFetcher {
  /// Returns the bytes of [url], stored in the cache as [cacheName].
  Future<List<int>> fetch(Uri url, String cacheName);
}

/// Downloads over HTTPS into [cacheDirectory] (`third_party_cache/`, ignored
/// by git) and reuses cached files unless [refresh] is set.
final class HttpSourceFetcher implements SourceFetcher {
  /// Creates a fetcher.
  HttpSourceFetcher({
    required this.cacheDirectory,
    required this.refresh,
    required Logger logger,
  }) : _logger = logger;

  /// Folder for downloaded files.
  final String cacheDirectory;

  /// Whether to download again even if a cached copy exists.
  final bool refresh;

  final Logger _logger;

  @override
  Future<List<int>> fetch(Uri url, String cacheName) async {
    if (url.scheme != 'https') {
      throw ContentBuildException('Only HTTPS sources are allowed: $url');
    }
    final file = File(p.join(cacheDirectory, cacheName));
    if (!p.isWithin(cacheDirectory, file.path)) {
      throw ContentBuildException('Cache name leaves the cache: $cacheName');
    }
    if (!refresh && file.existsSync()) {
      _logger.fine('cached $cacheName');
      return file.readAsBytesSync();
    }
    _logger.info('download $url');
    final client = HttpClient()
      ..findProxy = HttpClient.findProxyFromEnvironment
      ..userAgent = 'sudur-content-build';
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      final bytes = <int>[];
      await response.forEach(bytes.addAll);
      if (response.statusCode != HttpStatus.ok) {
        throw ContentBuildException(
          'HTTP ${response.statusCode} for $url',
        );
      }
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      return bytes;
    } on IOException catch (e) {
      throw ContentBuildException('Download failed for $url: $e');
    } finally {
      client.close();
    }
  }
}
