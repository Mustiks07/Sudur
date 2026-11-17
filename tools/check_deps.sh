#!/usr/bin/env bash

set -euo pipefail

readonly required_commands=(
  awk
  dirname
  find
  grep
)

missing_command=0
for command_name in "${required_commands[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Required program is not available: %s\n' "$command_name" >&2
    missing_command=1
  fi
done

if ((missing_command != 0)); then
  exit 127
fi

readonly project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

readonly pure_dart_packages=(
  contracts
  quran_text
  follow
  check
  session
  planner
  lessons
  testing
)

readonly service_packages=(
  audio_capture
  asr_sherpa
  storage
  content
  entitlements
  sync
)

readonly project_packages=(
  contracts
  quran_text
  follow
  check
  session
  planner
  lessons
  testing
  audio_capture
  asr_sherpa
  storage
  content
  mushaf_view
  entitlements
  sync
)

failed=0

report_error() {
  printf 'Dependency rule violation: %s\n' "$*" >&2
  failed=1
}

dependency_names() {
  local pubspec="$1"
  awk '
    /^dependencies:/ { in_dependencies = 1; next }
    in_dependencies && /^[^[:space:]]/ { exit }
    in_dependencies && /^  [a-zA-Z0-9_]+:/ {
      name = $1
      sub(/:$/, "", name)
      print name
    }
  ' "$pubspec"
}

is_project_package() {
  local candidate="$1"
  local package
  for package in "${project_packages[@]}"; do
    [[ "$candidate" == "$package" ]] && return 0
  done
  return 1
}

dependency_is_allowed() {
  local package="$1"
  local dependency="$2"
  case "$package" in
    contracts)
      return 1
      ;;
    quran_text|planner|lessons|testing|audio_capture|asr_sherpa|storage|content|entitlements|sync)
      [[ "$dependency" == contracts ]]
      ;;
    follow|check)
      [[ "$dependency" == contracts || "$dependency" == quran_text ]]
      ;;
    session)
      [[ "$dependency" == contracts || "$dependency" == follow || "$dependency" == check || "$dependency" == quran_text ]]
      ;;
    mushaf_view)
      [[ "$dependency" == contracts || "$dependency" == quran_text ]]
      ;;
    *)
      return 1
      ;;
  esac
}

for package in "${pure_dart_packages[@]}"; do
  pubspec="packages/$package/pubspec.yaml"
  if grep -q '^  flutter:$' "$pubspec"; then
    report_error "$package is a pure-Dart package but depends on Flutter"
  fi
  if grep -R -q --include='*.dart' 'package:flutter/' "packages/$package"; then
    report_error "$package is a pure-Dart package but imports Flutter"
  fi
done

for package in "${project_packages[@]}"; do
  while IFS= read -r dependency; do
    is_project_package "$dependency" || continue
    if ! dependency_is_allowed "$package" "$dependency"; then
      report_error "$package must not depend on $dependency"
    fi
  done < <(dependency_names "packages/$package/pubspec.yaml")
done

for service in "${service_packages[@]}"; do
  while IFS= read -r pubspec; do
    if grep -q "^  $service:" "$pubspec"; then
      report_error "only app may depend on service package $service"
      break
    fi
  done < <(
    find packages tools -type f -name pubspec.yaml \
      ! -path "packages/$service/pubspec.yaml"
  )
done

while IFS=: read -r file line import_line; do
  imported_package="${import_line#*package:}"
  imported_package="${imported_package%%/src/*}"

  case "$file" in
    app/*)
      owning_package=sudur
      ;;
    packages/*)
      owning_package="${file#packages/}"
      owning_package="${owning_package%%/*}"
      ;;
    tools/*)
      owning_package="${file#tools/}"
      owning_package="${owning_package%%/*}"
      ;;
    *)
      owning_package=
      ;;
  esac

  if [[ "$imported_package" != "$owning_package" ]]; then
    report_error "$file:$line imports another package's src/ directory ($imported_package)"
  fi
done < <(
  grep -R -n -E --include='*.dart' \
    'package:[a-zA-Z0-9_]+/src/' app packages tools || true
)

if ((failed != 0)); then
  exit 1
fi

printf 'Dependency rules passed.\n'
