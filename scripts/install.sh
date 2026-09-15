#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/build.sh"

APP="/Applications/LinkRouter.app"
rm -rf "$APP"
cp -R "$ROOT/.build/LinkRouter.app" "$APP"

pkill -x LinkRouter 2>/dev/null || true

"$APP/Contents/MacOS/LinkRouter" --set-default

open "$APP"
echo "installed $APP and set it as the default browser for http/https"
echo
echo "Click any link (Slack, Terminal, Mail, ...) to route it."
echo "Edit rules in ~/.config/link-router/config.json"