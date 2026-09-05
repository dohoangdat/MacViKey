#!/bin/bash
# Build MacViKey va dat ket qua len Desktop.
#
# Ky ad-hoc vi may build chua co certificate "Mac Development": build mac dinh
# se that bai ngay o buoc ky. Luu y chu ky ad-hoc doi hash moi lan build, nen
# macOS coi moi ban build la mot app la -> phai cap lai quyen Tro nang.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../Sources/MacViKey/macOS" && pwd)"
CONFIG="${1:-Debug}"
DEST="$HOME/Desktop/MacViKey.app"

cd "$PROJECT_DIR"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

xcodebuild -project MacViKey.xcodeproj -scheme MacViKey -configuration "$CONFIG" \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" \
    build

# App dang chay se khoa file -> tat truoc khi thay the.
pkill -f "MacViKey.app/Contents/MacOS/MacViKey" 2>/dev/null || true

rm -rf "$DEST"
cp -R "$BUILD_DIR/MacViKey.app" "$DEST"

echo ""
echo "Da build xong: $DEST"
