import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:content/src/ports.dart';
import 'package:path/path.dart' as p;

/// Unpacks zip archives safely (AGENTS.md, «Security»). An archive without
/// files is refused as bad. Every entry is
/// checked before anything is written, and the whole archive is refused if
/// one entry is absolute, has `..`, a backslash or a drive letter, would
/// land outside the target after normalizing, or is a link (zip-slip).
///
/// Runs in a separate isolate: unpacking a model takes longer than a frame.
final class ZipExtractor implements ArchiveExtractor {
  /// Creates the extractor.
  const ZipExtractor();

  @override
  Future<ExtractProblem?> extract(String archivePath, String targetDirectory) =>
      Isolate.run(() => extractZipSync(archivePath, targetDirectory));
}

/// The work of [ZipExtractor], on the calling isolate (for tests and for
/// callers already off the UI isolate).
ExtractProblem? extractZipSync(String archivePath, String targetDirectory) {
  final input = InputFileStream(archivePath);
  try {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } on ArchiveException {
      return ExtractProblem.badArchive;
      // The decoder reads past the end of a truncated or garbled file and
      // throws RangeError; the archive is outside data, so it is refused.
      // ignore: avoid_catching_errors
    } on RangeError {
      return ExtractProblem.badArchive;
    }
    // The decoder reads garbage or a cut-off file as an empty archive; a
    // package always has files.
    if (archive.files.every((f) => f.isDirectory)) {
      return ExtractProblem.badArchive;
    }
    final target = p.normalize(p.absolute(targetDirectory));
    final planned = <(ArchiveFile, String)>[];
    for (final entry in archive.files) {
      final path = safeEntryPath(entry.name, target);
      if (path == null || entry.isSymbolicLink) {
        return ExtractProblem.unsafePath;
      }
      planned.add((entry, path));
    }
    for (final (entry, path) in planned) {
      if (entry.isDirectory) {
        Directory(path).createSync(recursive: true);
        continue;
      }
      Directory(p.dirname(path)).createSync(recursive: true);
      final output = OutputFileStream(path);
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
      }
    }
    return null;
  } on ArchiveException {
    return ExtractProblem.badArchive;
  } finally {
    input.closeSync();
  }
}

/// Where archive entry [name] goes inside [target], or `null` if it would
/// not stay inside.
String? safeEntryPath(String name, String target) {
  if (name.isEmpty ||
      name.startsWith('/') ||
      name.contains(r'\') ||
      name.contains(':') ||
      name.split('/').contains('..')) {
    return null;
  }
  final path = p.normalize(p.join(target, name));
  return p.isWithin(target, path) ? path : null;
}
