#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/build.sh"

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ROOT/Resources/Info.plist")"
DIST="$ROOT/dist"
rm -rf "$DIST"
mkdir -p "$DIST"
cd "$ROOT/.build"
ditto -c -k --keepParent LinkRouter.app "$DIST/LinkRouter-$VERSION.zip"
cd "$DIST"
shasum -a 256 "LinkRouter-$VERSION.zip" > "LinkRouter-$VERSION.zip.sha256"
echo "built $DIST/LinkRouter-$VERSION.zip"
