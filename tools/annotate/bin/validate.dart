import 'dart:io';

import 'package:annotate/annotate.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Использование: dart run tools/annotate/bin/validate.dart <папка>',
    );
    exitCode = 64;
    return;
  }

  final report = validateAnnotationDirectory(Directory(arguments.single));
  if (report.filesChecked == 0 && report.issues.isEmpty) {
    stderr.writeln('В папке нет файлов *.ann.json.');
    exitCode = 1;
    return;
  }
  if (!report.isValid) {
    stderr.writeln(
      'Проверено файлов: ${report.filesChecked}. Найдены ошибки:',
    );
    for (final issue in report.issues) {
      stderr.writeln('  - $issue');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Разметка верна. Проверено файлов: ${report.filesChecked}.',
  );
}
