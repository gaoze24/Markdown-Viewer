#!/bin/zsh

# Regenerates Design/AppIcon.icns from Design/AppIcon.svg.
#
# The generated .icns is committed, so building the app does not require this
# script (or Chrome) — only run it after editing the SVG.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESIGN_DIR="${ROOT_DIR}/Design"
SVG="${DESIGN_DIR}/AppIcon.svg"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [[ ! -x "$CHROME" ]]; then
    echo "Google Chrome is required to rasterize the SVG, but was not found at:" >&2
    echo "  $CHROME" >&2
    exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

cat > "$WORK_DIR/icon.html" <<HTML
<html><head><style>html,body{margin:0;padding:0;background:transparent}</style></head>
<body><img src="file://${SVG}" width="1024" height="1024"></body></html>
HTML

echo "Rasterizing ${SVG##*/}..."
"$CHROME" --headless --disable-gpu --hide-scrollbars \
    --screenshot="$WORK_DIR/icon_1024.png" \
    --window-size=1024,1024 \
    --default-background-color=00000000 \
    "file://$WORK_DIR/icon.html" >/dev/null 2>&1

ICONSET="$WORK_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"

# name:pixel-size pairs required by iconutil
for entry in \
    icon_16x16:16 \
    icon_16x16@2x:32 \
    icon_32x32:32 \
    icon_32x32@2x:64 \
    icon_128x128:128 \
    icon_128x128@2x:256 \
    icon_256x256:256 \
    icon_256x256@2x:512 \
    icon_512x512:512 \
    icon_512x512@2x:1024
do
    name="${entry%%:*}"
    size="${entry##*:}"
    sips -Z "$size" "$WORK_DIR/icon_1024.png" --out "$ICONSET/$name.png" >/dev/null 2>&1
done

mkdir -p "$DESIGN_DIR"
iconutil --convert icns "$ICONSET" --output "${DESIGN_DIR}/AppIcon.icns"

echo "Wrote ${DESIGN_DIR}/AppIcon.icns"
