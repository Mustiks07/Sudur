#!/usr/bin/env sh
set -eu

mode=${1:---check}
if [ "$mode" != "--check" ] && [ "$mode" != "--write" ]; then
  echo 'usage: generate.sh [--check|--write]' >&2
  exit 64
fi

generator_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
storage_dir=$(CDPATH= cd -- "$generator_dir/../.." && pwd)
contracts_dir=$(CDPATH= cd -- "$storage_dir/../contracts" && pwd)
work_dir=$(mktemp -d /tmp/sudur-storage-codegen.XXXXXX)
trap 'rm -rf -- "$work_dir"' EXIT HUP INT TERM

mkdir -p \
  "$work_dir/packages/contracts" \
  "$work_dir/packages/storage/lib/src" \
  "$work_dir/packages/storage/drift_schemas"
cp "$generator_dir/pubspec.yaml" "$generator_dir/pubspec.lock" "$work_dir/"
cp "$generator_dir/packages/contracts/pubspec.yaml" \
  "$work_dir/packages/contracts/pubspec.yaml"
cp "$generator_dir/packages/storage/pubspec.yaml" \
  "$work_dir/packages/storage/pubspec.yaml"
cp -R "$contracts_dir/lib" "$work_dir/packages/contracts/"
cp "$storage_dir/lib/src/database.dart" "$storage_dir/lib/src/json_types.dart" \
  "$work_dir/packages/storage/lib/src/"

(
  cd "$work_dir"
  dart pub get --enforce-lockfile
)
(
  cd "$work_dir/packages/storage"
  dart run build_runner build --delete-conflicting-outputs
  dart run drift_dev schema dump lib/src/database.dart drift_schemas/
)

generated_database="$work_dir/packages/storage/lib/src/database.g.dart"
generated_schema="$work_dir/packages/storage/drift_schemas/drift_schema_v2.json"

if [ "$mode" = "--write" ]; then
  cp "$generated_database" "$storage_dir/lib/src/database.g.dart"
  cp "$generated_schema" "$storage_dir/drift_schemas/drift_schema_v2.json"
  exit 0
fi

cmp "$generated_database" "$storage_dir/lib/src/database.g.dart"
cmp "$generated_schema" "$storage_dir/drift_schemas/drift_schema_v2.json"
