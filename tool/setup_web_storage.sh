#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Match the sqlite3 Dart package version in pubspec.lock.
version=3.9.1
checksum=e7451780e78c56ff864fe9317a0fbcd6aeb2e8de3beba7f5efd963202f7ec3d9
download="$(mktemp)"
trap 'rm -f "$download"' EXIT
curl --fail --silent --show-error --location \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${version}/sqlite3.wasm" \
  --output "$download"
printf '%s  %s\n' "$checksum" "$download" | shasum -a 256 -c
cp "$download" web/sqlite3.wasm
dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.dart.js
