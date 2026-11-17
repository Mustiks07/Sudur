#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOSITORY_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CACHE_ROOT="$REPOSITORY_ROOT/third_party_cache/audio_capture"
TARGET="$CACHE_ROOT/silero_vad.onnx"
LICENSE_TARGET="$CACHE_ROOT/SILERO_LICENSE"
EXPECTED_SHA256="9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6"

mkdir -p "$CACHE_ROOT"
if [[ -e "$TARGET" || -e "$LICENSE_TARGET" ]]; then
  echo "Silero VAD cache already exists in $CACHE_ROOT" >&2
  echo "Remove it explicitly before downloading again." >&2
  exit 1
fi

TEMPORARY="$(mktemp -d "$CACHE_ROOT/.silero-vad.XXXXXX")"
trap 'rm -rf "$TEMPORARY"' EXIT

curl --fail --location --retry 3 --silent --show-error "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx" --output "$TEMPORARY/silero_vad.onnx"
curl --fail --location --retry 3 --silent --show-error "https://raw.githubusercontent.com/snakers4/silero-vad/master/LICENSE" --output "$TEMPORARY/SILERO_LICENSE"

ACTUAL_SHA256="$(sha256sum "$TEMPORARY/silero_vad.onnx" | cut -d' ' -f1)"
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
  echo "Silero VAD SHA-256 mismatch." >&2
  exit 1
fi

mv "$TEMPORARY/silero_vad.onnx" "$TARGET"
mv "$TEMPORARY/SILERO_LICENSE" "$LICENSE_TARGET"
echo "Downloaded verified Silero VAD to $TARGET"
