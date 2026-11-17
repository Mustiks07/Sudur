#!/usr/bin/env bash
set -euo pipefail
# Explicit owner provisioning; external files never enter git.
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
for program in adb curl python3; do command -v "$program" >/dev/null || { echo "Missing $program" >&2; exit 1; }; done
CACHE="$ROOT/third_party_cache/prototype"
mkdir -p "$CACHE/fonts"
for page in 582 583; do
  curl --fail --location --proto '=https' "https://static-cdn.tarteel.ai/qul/fonts/quran_fonts/v2/ttf/p${page}.ttf?v=3.2" -o "$CACHE/fonts/p${page}.ttf"
done
DEST='/sdcard/Android/data/kz.sudur.sudur/files/prototype'
adb shell mkdir -p "$DEST"
adb push "$ROOT/packages/testing/fixtures/content_p582_583.json" "$DEST/content.json"
adb push "$CACHE/fonts" "$DEST/"
adb push "$ROOT/third_party_cache/audio_capture/silero_vad.onnx" "$DEST/silero_vad.onnx"
for model in quran-asr-small quran-asr-tiny; do
  adb push "$ROOT/third_party_cache/asr_sherpa/$model" "$DEST/"
done
if [[ $# -eq 1 ]]; then adb push "$1" "$DEST/input.wav"; fi
printf '%s\n' 'Provisioned. Open dev APK and tap Reload files.'
