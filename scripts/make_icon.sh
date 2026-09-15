#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/AppIcon.png}"

if [ ! -f "$SRC" ]; then
    echo "source icon not found: $SRC (supply a 1024x1024 PNG or pass a path)" >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SET="$TMP/AppIcon.iconset"
mkdir -p "$SET"

if [ "$(sips -g hasAlpha "$SRC" | awk '/hasAlpha/ {print $2}')" = "no" ]; then
    if ! command -v magick > /dev/null; then
        echo "opaque icon needs rounded-corner masking: brew install imagemagick, or supply a PNG with transparent corners" >&2
        exit 1
    fi
    W="$(magick identify -format "%w" "$SRC")"
    H="$(magick identify -format "%h" "$SRC")"
    R="$((W * 225 / 1000))"
    MASKED="$TMP/masked.png"
    magick "$SRC" \
        \( -size "${W}x${H}" xc:black -fill white -draw "roundrectangle 0,0 $((W - 1)),$((H - 1)) $R,$R" \) \
        -alpha off -compose CopyOpacity -composite "$MASKED"
    SRC="$MASKED"
fi

sips -z 16 16 "$SRC" --out "$SET/icon_16x16.png" > /dev/null
sips -z 32 32 "$SRC" --out "$SET/icon_16x16@2x.png" > /dev/null
sips -z 32 32 "$SRC" --out "$SET/icon_32x32.png" > /dev/null
sips -z 64 64 "$SRC" --out "$SET/icon_32x32@2x.png" > /dev/null
sips -z 128 128 "$SRC" --out "$SET/icon_128x128.png" > /dev/null
sips -z 256 256 "$SRC" --out "$SET/icon_128x128@2x.png" > /dev/null
sips -z 256 256 "$SRC" --out "$SET/icon_256x256.png" > /dev/null
sips -z 512 512 "$SRC" --out "$SET/icon_256x256@2x.png" > /dev/null
sips -z 512 512 "$SRC" --out "$SET/icon_512x512.png" > /dev/null
cp "$SRC" "$SET/icon_512x512@2x.png"

if command -v pngquant > /dev/null; then
    for png in "$SET"/*.png; do
        pngquant --ext .png --force "$png" || true
    done
else
    echo "pngquant not found; icon will be larger (brew install pngquant)" >&2
fi

iconutil -c icns "$SET" -o "$ROOT/Resources/AppIcon.icns"
echo "wrote $ROOT/Resources/AppIcon.icns"