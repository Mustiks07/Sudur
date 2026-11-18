"use strict";

(function exposeAnnotationValidation(target) {
  function hasOwn(value, key) {
    return Object.prototype.hasOwnProperty.call(value, key);
  }

  function optionalNonNegativeInteger(rawValue) {
    const text = String(rawValue ?? "").trim();
    if (text === "") return null;
    const value = Number(text);
    return Number.isInteger(value) && value >= 0 ? value : Number.NaN;
  }

  function validSpan(start, end) {
    return Number.isInteger(start) && Number.isInteger(end) && start >= 0 && end >= start;
  }

  function annotationValueErrors(annotation) {
    const errors = [];
    const words = Array.isArray(annotation?.words) ? annotation.words : [];
    words.forEach((word, index) => {
      const label = `Слово ${word.wordKey || index + 1}`;
      const hasStart = hasOwn(word, "startMs");
      const hasEnd = hasOwn(word, "endMs");
      if (hasStart !== hasEnd) {
        errors.push(`${label}: начало и конец задаются вместе`);
      }
      if (hasStart && (!Number.isInteger(word.startMs) || word.startMs < 0)) {
        errors.push(`${label}: начало должно быть целым числом ≥ 0`);
      }
      if (hasEnd && (!Number.isInteger(word.endMs) || word.endMs < 0)) {
        errors.push(`${label}: конец должен быть целым числом ≥ 0`);
      }
      if (Number.isInteger(word.startMs) && Number.isInteger(word.endMs) && word.endMs < word.startMs) {
        errors.push(`${label}: конец не может быть раньше начала`);
      }
      if (word.status === "omitted" && (hasStart || hasEnd)) {
        errors.push(`${label}: у пропущенного слова не должно быть времени`);
      }
      const correction = word.correction;
      if (correction && hasOwn(correction, "afterMs") &&
          (!Number.isInteger(correction.afterMs) || correction.afterMs < 0)) {
        errors.push(`${label}: correction.afterMs должно быть целым числом ≥ 0`);
      }
      if (correction && hasOwn(correction, "afterWords") &&
          (!Number.isInteger(correction.afterWords) || correction.afterWords < 0)) {
        errors.push(`${label}: correction.afterWords должно быть целым числом ≥ 0`);
      }
    });

    for (const collection of ["insertions", "jumps"]) {
      const spans = Array.isArray(annotation?.[collection]) ? annotation[collection] : [];
      spans.forEach((span, index) => {
        if (!validSpan(span.startMs, span.endMs)) {
          errors.push(`${collection}[${index}]: нужен диапазон целых чисел ≥ 0`);
        }
      });
    }
    return errors;
  }

  target.AnnotationValidation = Object.freeze({
    annotationValueErrors,
    optionalNonNegativeInteger,
    validSpan,
  });
})(globalThis);
