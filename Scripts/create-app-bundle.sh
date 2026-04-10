#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Markdown Reader"
EXECUTABLE_NAME="MarkdownReader"
OUTPUT_DIR="${ROOT_DIR}/dist/${APP_NAME}.app"

echo "Building release executable..."
swift build -c release --package-path "$ROOT_DIR" >/dev/null
BIN_PATH="$(swift build -c release --show-bin-path --package-path "$ROOT_DIR")"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/Contents/MacOS" "$OUTPUT_DIR/Contents/Resources"

cp "$BIN_PATH/$EXECUTABLE_NAME" "$OUTPUT_DIR/Contents/MacOS/$APP_NAME"

for bundle in "$BIN_PATH"/*.bundle(N); do
    cp -R "$bundle" "$OUTPUT_DIR/Contents/Resources/"
done

cat > "$OUTPUT_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Markdown Reader</string>
    <key>CFBundleExecutable</key>
    <string>Markdown Reader</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.MarkdownReader</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Markdown Reader</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
                <string>public.plain-text</string>
            </array>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>md</string>
                <string>markdown</string>
                <string>mdown</string>
                <string>mkd</string>
                <string>mkdn</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$OUTPUT_DIR" >/dev/null 2>&1 || true
fi

echo "Created app bundle at:"
echo "$OUTPUT_DIR"
