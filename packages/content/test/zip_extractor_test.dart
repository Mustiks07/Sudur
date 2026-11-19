import 'dart:io';

import 'package:content/content.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('zip'));
  tearDown(() => dir.deleteSync(recursive: true));

  String target() => p.join(dir.path, 'out');

  test('entry paths that leave the folder are refused', () {
    final t = target();
    for (final bad in [
      '../x',
      'a/../../x',
      '/etc/passwd',
      r'a\..\x',
      r'C:\x',
      'c:x',
      '',
    ]) {
      expect(safeEntryPath(bad, t), isNull, reason: bad);
    }
    expect(safeEntryPath('a/b/c.txt', t), p.join(t, 'a', 'b', 'c.txt'));
    expect(safeEntryPath('./a.txt', t), p.join(t, 'a.txt'));
  });

  ExtractProblem? extract(List<int> bytes) {
    final file = File(p.join(dir.path, 'a.zip'))..writeAsBytesSync(bytes);
    return extractZipSync(file.path, target());
  }

  test('a good archive is unpacked', () {
    expect(extract(zip({'a.txt': 'x', 'b/c.txt': 'y'})), isNull);
    expect(File(p.join(target(), 'b', 'c.txt')).readAsStringSync(), 'y');
  });

  test('one bad entry: nothing at all is written', () {
    expect(
      extract(zip({'a.txt': 'x', '../evil.txt': 'y'})),
      ExtractProblem.unsafePath,
    );
    expect(Directory(target()).existsSync(), isFalse);
    expect(File(p.join(dir.path, 'evil.txt')).existsSync(), isFalse);
  });

  test('not a zip, or cut in half: bad archive', () {
    expect(extract(List.filled(100, 7)), ExtractProblem.badArchive);
    final good = zip({'a.txt': 'x' * 100});
    expect(
      extract(good.sublist(0, good.length ~/ 2)),
      ExtractProblem.badArchive,
    );
  });

  test('the isolate extractor gives the same result', () async {
    final file = File(p.join(dir.path, 'a.zip'))
      ..writeAsBytesSync(zip({'a.txt': 'x'}));
    expect(await const ZipExtractor().extract(file.path, target()), isNull);
    expect(File(p.join(target(), 'a.txt')).readAsStringSync(), 'x');
  });
}
