#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOSITORY_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CACHE_ROOT="$REPOSITORY_ROOT/third_party_cache/asr_sherpa"
MODEL_CHOICE="${1:-all}"
EVAL_ROOT="${SUDUR_ASR_EVAL_DIR:-}"

if [[ -z "$EVAL_ROOT" ]]; then
  echo "Set SUDUR_ASR_EVAL_DIR to reviewed small.json and tiny.json reports." >&2
  exit 64
fi

mkdir -p "$CACHE_ROOT"

download_model() {
  local name="$1"
  local revision="$2"
  local min_ram_mb="$3"
  local repository="Abdou/quran-asr-$name"
  local evaluation="$EVAL_ROOT/$name.json"
  local target="$CACHE_ROOT/quran-asr-$name"
  local temporary

  if [[ -e "$target" ]]; then
    echo "Target already exists: $target" >&2
    echo "Remove it explicitly before downloading a different revision." >&2
    return 1
  fi
  if [[ ! -f "$evaluation" ]]; then
    echo "Evaluation report is missing: $evaluation" >&2
    return 1
  fi

  temporary="$(mktemp -d "$CACHE_ROOT/.quran-asr-$name.XXXXXX")"
  trap 'rm -rf "$temporary"' RETURN

  for file in model.int8.onnx tokens.txt spelling.json LICENSE; do
    curl --fail --location --retry 3 --silent --show-error "https://huggingface.co/$repository/resolve/$revision/$file" --output "$temporary/$file"
  done
  cp "$evaluation" "$temporary/eval.json"

  local model_sha256
  local tokens_sha256
  model_sha256="$(sha256sum "$temporary/model.int8.onnx" | cut -d' ' -f1)"
  tokens_sha256="$(sha256sum "$temporary/tokens.txt" | cut -d' ' -f1)"

  python3 - "$temporary" "$repository" "$revision" "$min_ram_mb" "$model_sha256" "$tokens_sha256" <<'PY'
import json
import pathlib
import sys

target = pathlib.Path(sys.argv[1])
repository = sys.argv[2]
revision = sys.argv[3]
min_ram_mb = int(sys.argv[4])
model_sha256 = sys.argv[5]
tokens_sha256 = sys.argv[6]

with (target / "spelling.json").open(encoding="utf-8") as source:
    spelling = json.load(source)

model = {
    "modelId": repository,
    "version": f"hf-{revision[:12]}",
    "output": "uthmaniLettersNoDiacritics",
    "isStreaming": False,
    "hasTokenTimes": True,
    "sampleRate": 16000,
    "minRamMb": min_ram_mb,
    "license": "MIT",
    "normalizerId": f"{repository.lower().replace('/', '-')}-spelling-{revision[:12]}",
    "modelSizeBytes": (target / "model.int8.onnx").stat().st_size,
    "tokensSizeBytes": (target / "tokens.txt").stat().st_size,
    "modelSha256": model_sha256,
    "tokensSha256": tokens_sha256,
}
normalizer = {
    "id": model["normalizerId"],
    "nfc": True,
    "removeRanges": [],
    "replace": [
        {"from": source, "to": replacement}
        for source, replacement in spelling.items()
    ],
    "wordSeparator": " ",
}
thresholds = {
    "beamSize": 5,
    "maxSkip": 4,
    "maxBack": 8,
    "costSkip": 1.0,
    "costBack": 0.3,
    "costInsert": 1.0,
    "simFloor": 0.4,
    "openThreshold": 0.70,
    "lostCostThreshold": 0.6,
    "ambiguityMargin": 0.15,
    "ngramSize": 3,
    "stableConfirmations": 2,
    "openDelayWords": 2,
    "lostWindowWords": 4,
    "strongMatch": 0.85,
    "substitutionMax": 0.60,
    "confirmContextWords": 2,
    "jumpMinWords": 3,
    "selfCorrectionMs": 2500,
    "selfCorrectionWords": 2,
    "hesitationPauseMs": 2500,
    "hesitationTempoFactor": 3,
    "strictMaxFails": 3,
    "strictMaxWaitMs": 15000,
    "stuckWordTries": 3,
}

for filename, value in (
    ("model.json", model),
    ("normalizer.json", normalizer),
    ("thresholds.json", thresholds),
):
    with (target / filename).open("w", encoding="utf-8", newline="\n") as output:
        json.dump(value, output, ensure_ascii=False, indent=2)
        output.write("\n")

(target / "spelling.json").unlink()
PY

  mv "$temporary" "$target"
  trap - RETURN
  echo "Built $target"
}

case "$MODEL_CHOICE" in
  small)
    download_model small 0c2744b9d70aaf45ba574c30c5d318c575258e66 384
    ;;
  tiny)
    download_model tiny a291b33fd5a31cc4f212363ee1ba2d56d9710b49 256
    ;;
  all)
    download_model small 0c2744b9d70aaf45ba574c30c5d318c575258e66 384
    download_model tiny a291b33fd5a31cc4f212363ee1ba2d56d9710b49 256
    ;;
  *)
    echo "Usage: $0 [small|tiny|all]" >&2
    exit 64
    ;;
esac
