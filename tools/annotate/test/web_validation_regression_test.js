"use strict";

const assert = require("node:assert/strict");

require("../web/validation.js");

const {
  annotationValueErrors,
  optionalNonNegativeInteger,
  validSpan,
} = globalThis.AnnotationValidation;

assert.equal(optionalNonNegativeInteger(""), null);
assert.equal(optionalNonNegativeInteger("0"), 0);
assert.equal(optionalNonNegativeInteger("12"), 12);
assert.equal(Number.isNaN(optionalNonNegativeInteger("-1")), true);
assert.equal(Number.isNaN(optionalNonNegativeInteger("1.5")), true);
assert.equal(validSpan(0, 100), true);
assert.equal(validSpan(-1, 100), false);

const errors = annotationValueErrors({
  words: [
    {
      wordKey: "78:1:1",
      status: "selfCorrected",
      startMs: -2,
      endMs: -1,
      correction: { afterMs: -1, afterWords: -3 },
    },
  ],
  insertions: [{ startMs: -1, endMs: 10 }],
  jumps: [{ startMs: 20, endMs: -1 }],
});
const message = errors.join("\n");

assert.match(message, /начало должно быть/);
assert.match(message, /конец должен быть/);
assert.match(message, /correction\.afterMs/);
assert.match(message, /correction\.afterWords/);
assert.match(message, /insertions/);
assert.match(message, /jumps/);
assert.deepEqual(annotationValueErrors({ words: [], insertions: [], jumps: [] }), []);
