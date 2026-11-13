#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

tag="${1:?Pass the release tag (for example v0.2.0)}"
version="${tag#v}"
declared_version="$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' pubspec.yaml)"
if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ || "$version" != "$declared_version" ]]; then
  echo "Release tag must match the version in pubspec.yaml." >&2
  exit 1
fi

flutter build macos --release --no-pub --dart-define="WORKLOG_RELEASE_VERSION=$version"
app="build/macos/Build/Products/Release/logmydailytask.app"
codesign --verify --deep --strict "$app"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/LogMyDailyTask.app"
ln -s /Applications "$stage/Applications"
hdiutil create -ov -format UDZO -volname LogMyDailyTask \
  -srcfolder "$stage" build/LogMyDailyTask-macOS.dmg
hdiutil verify build/LogMyDailyTask-macOS.dmg
