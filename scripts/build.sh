#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c release

BUNDLE="$ROOT/.build/LinkRouter.app"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$ROOT/.build/release/LinkRouter" "$BUNDLE/Contents/MacOS/LinkRouter"
strip "$BUNDLE/Contents/MacOS/LinkRouter"
cp "$ROOT/Resources/Info.plist" "$BUNDLE/Contents/Info.plist"
if [ -f "$ROOT/Resources/AppIcon.icns" ]; then
    cp "$ROOT/Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/"
fi
printf 'APPL????' > "$BUNDLE/Contents/PkgInfo"
codesign --force --sign - "$BUNDLE"
echo "built $BUNDLE"