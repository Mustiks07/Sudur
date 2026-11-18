import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:eval/eval.dart';

/// One problem found in an annotation file.
final class ValidationIssue {
  /// Creates a validation issue.
  const ValidationIssue({required this.file, required this.message});

  /// File that contains the problem.
  final String file;

  /// Human-readable problem description.
  final String message;

  @override
  String toString() => '$file: $message';
}

/// Result of validating every annotation in a directory.
final class ValidationReport {
  /// Creates a validation report.
  const ValidationReport({required this.filesChecked, required this.issues});

  /// Number of `.ann.json` files that were inspected.
  final int filesChecked;

  /// Problems found in those files.
  final List<ValidationIssue> issues;

  /// Whether every file is valid.
  bool get isValid => issues.isEmpty;
}

/// Validates every top-level `<id>.ann.json` in [directory].
///
/// Parsing deliberately goes through the public `eval` API, so this command
/// and `tools/eval` always agree on the wire format.
ValidationReport validateAnnotationDirectory(Directory directory) {
  if (!directory.existsSync()) {
    return ValidationReport(
      filesChecked: 0,
      issues: [
        ValidationIssue(
          file: directory.path,
          message: 'Папка не существует.',
        ),
      ],
    );
  }

  final files = directory
      .listSync(followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.ann.json'))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));

  final issues = <ValidationIssue>[];
  for (final file in files) {
    issues.addAll(validateAnnotationFile(file));
  }
  return ValidationReport(
    filesChecked: files.length,
    issues: List.unmodifiable(issues),
  );
}

/// Validates one annotation using [Annotation.parse] from `tools/eval`.
List<ValidationIssue> validateAnnotationFile(File file) {
  final name = _baseName(file.path);
  Annotation annotation;
  try {
    final result = Annotation.parse(file.readAsStringSync());
    switch (result) {
      case Ok(:final value):
        annotation = value;
      case Error(:final error):
        return [ValidationIssue(file: name, message: '$error')];
    }
  } on FileSystemException catch (error) {
    return [ValidationIssue(file: name, message: '${error.message}.')];
  } on Object catch (error) {
    // `Annotation.parse` normally returns Result.error. This final boundary
    // keeps a single damaged file from aborting validation of the directory.
    return [ValidationIssue(file: name, message: 'Ошибка чтения: $error')];
  }

  return _semanticIssues(name, annotation);
}

List<ValidationIssue> _semanticIssues(String file, Annotation annotation) {
  final messages = <String>[];
  const suffix = '.ann.json';
  final expectedId = file.substring(0, file.length - suffix.length);
  if (annotation.recordingId != expectedId) {
    messages.add(
      'recordingId должен быть "$expectedId", как имя файла.',
    );
  }
  if (annotation.speaker.gender != 'm' && annotation.speaker.gender != 'f') {
    messages.add('speaker.gender должен быть "m" или "f".');
  }
  if (annotation.from.compareTo(annotation.to) > 0) {
    messages.add('expected.from должен быть не позже expected.to.');
  }
  if (annotation.words.isEmpty) {
    messages.add('words не должен быть пустым.');
  } else {
    if (annotation.words.first.key != annotation.from) {
      messages.add('Первое слово должно совпадать с expected.from.');
    }
    if (annotation.words.last.key != annotation.to) {
      messages.add('Последнее слово должно совпадать с expected.to.');
    }
  }

  WordKey? previous;
  final seen = <WordKey>{};
  for (final word in annotation.words) {
    final label = 'words[${word.key}]';
    if (!seen.add(word.key)) {
      messages.add('$label повторяется.');
    }
    if (previous != null && previous.compareTo(word.key) >= 0) {
      messages.add('$label нарушает порядок слов.');
    }
    previous = word.key;
    if (word.key.compareTo(annotation.from) < 0 ||
        word.key.compareTo(annotation.to) > 0) {
      messages.add('$label находится вне expected.from–to.');
    }

    final hasStart = word.startMs != null;
    final hasEnd = word.endMs != null;
    if (hasStart != hasEnd) {
      messages.add('$label: startMs и endMs задаются вместе.');
    }
    if (word.startMs case final start?) {
      if (start < 0) {
        messages.add('$label.startMs не может быть отрицательным.');
      }
    }
    if (word.endMs case final end?) {
      if (end < 0) messages.add('$label.endMs не может быть отрицательным.');
      final start = word.startMs;
      if (start != null && end < start) {
        messages.add('$label.endMs должен быть не раньше startMs.');
      }
    }
    if (word.status == WordStatus.omitted && (hasStart || hasEnd)) {
      messages.add('$label: у пропущенного слова не должно быть времени.');
    }
    if (word.status == WordStatus.substituted &&
        (word.heard == null || word.heard!.trim().isEmpty)) {
      messages.add('$label: для substituted нужно поле heard.');
    }
    if (word.status == WordStatus.selfCorrected) {
      final correctionMs = word.correctionAfterMs;
      if (correctionMs == null || correctionMs < 0) {
        messages.add(
          '$label: correction.afterMs должен быть целым числом ≥ 0.',
        );
      }
      final correctionWords = word.correctionAfterWords;
      if (correctionWords != null && correctionWords < 0) {
        messages.add(
          '$label: correction.afterWords не может быть отрицательным.',
        );
      }
    }
  }

  for (final entry in <(String, List<AnnotatedSpan>)>[
    ('insertions', annotation.insertions),
    ('jumps', annotation.jumps),
  ]) {
    for (var index = 0; index < entry.$2.length; index++) {
      final span = entry.$2[index];
      final label = '${entry.$1}[$index]';
      if (span.startMs < 0) {
        messages.add('$label.startMs не может быть отрицательным.');
      }
      if (span.endMs < span.startMs) {
        messages.add('$label.endMs должен быть не раньше startMs.');
      }
      if (entry.$1 == 'insertions' && span.afterWordKey == null) {
        messages.add('$label: нужно поле afterWordKey.');
      }
      if (entry.$1 == 'jumps' && span.to == null) {
        messages.add('$label: нужно поле to.');
      }
    }
  }

  return [
    for (final message in messages)
      ValidationIssue(file: file, message: message),
  ];
}

String _baseName(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.substring(normalized.lastIndexOf('/') + 1);
}
