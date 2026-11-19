import 'dart:async';
import 'dart:io';

import 'package:content/src/ports.dart';
import 'package:contracts/contracts.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

/// [ContentFiles] on the real file system.
final class IoContentFiles implements ContentFiles {
  /// Creates the file access.
  const IoContentFiles();

  @override
  Future<int> length(String path) async {
    final f = File(path);
    return f.existsSync() ? await f.length() : 0;
  }

  @override
  Future<void> append(String path, Stream<List<int>> data) async {
    await Directory(p.dirname(path)).create(recursive: true);
    final file = await File(path).open(mode: FileMode.append);
    try {
      await for (final chunk in data) {
        await file.writeFrom(chunk);
      }
    } finally {
      await file.close();
    }
  }

  @override
  Future<void> truncate(String path) async {
    await Directory(p.dirname(path)).create(recursive: true);
    await File(path).writeAsBytes(const [], flush: true);
  }

  @override
  Future<String> sha256(String path) async =>
      (await crypto.sha256.bind(File(path).openRead()).first).toString();

  @override
  Future<bool> exists(String path) async =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  @override
  Future<void> createDirectory(String path) =>
      Directory(path).create(recursive: true);

  @override
  Future<void> rename(String from, String to) => Directory(from).rename(to);

  @override
  Future<void> delete(String path) async {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return;
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else {
      await File(path).delete();
    }
  }

  @override
  Future<List<String>> directories(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) return const [];
    return [
      await for (final e in dir.list(followLinks: false))
        if (e is Directory) p.basename(e.path),
    ];
  }
}

/// [ContentTransport] over HTTPS with `dart:io`.
final class HttpsContentTransport implements ContentTransport {
  /// Creates the transport over `client`.
  HttpsContentTransport(HttpClient client) : _client = client;

  final HttpClient _client;

  @override
  Future<Result<TransportResponse>> get(Uri url, {int from = 0}) async {
    if (url.scheme != 'https') {
      return Result.error(HttpException('only HTTPS is allowed', uri: url));
    }
    try {
      final request = await _client.getUrl(url);
      if (from > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$from-');
      }
      final response = await request.close();
      return Result.ok(
        TransportResponse(
          statusCode: response.statusCode,
          rangeStart: _rangeStart(response.headers.value('content-range')),
          body: response,
        ),
      );
    } on IOException catch (e) {
      return Result.error(e);
    }
  }

  static int? _rangeStart(String? header) {
    // "bytes 100-199/200"
    final match = RegExp(r'^bytes (\d+)-').firstMatch(header ?? '');
    return match == null ? null : int.tryParse(match[1] ?? '');
  }
}
