#!/bin/bash
# Build ban Release, ky bang chung chi tu ky, dong goi .dmg va in ra doan cask.
#
# Vi sao ky tu ky thay vi ad-hoc: macOS gan quyen Tro nang vao Designated
# Requirement cua app. Ad-hoc ("-") khong co leaf certificate nen DR roi ve
# cdhash -> moi ban build la mot app la -> user phai cap lai quyen. Chung chi
# tu ky cho DR on dinh qua moi lan build -> quyen Tro nang song qua update.
#
# Chung chi khong duoc Apple cong nhan nen Gatekeeper van chan file .dmg tai
# thu cong; duong Homebrew khong bi anh huong vi brew tu go quarantine.
#
# Tao chung chi mot lan duy nhat - xem tools/README.md.
set -euo pipefail

IDENTITY="${MVK_SIGN_IDENTITY:-MacViKey Self Signed}"
PROJECT_DIR="$(cd "$(dirname "$0")/../Sources/MacViKey/macOS" && pwd)"
OUT_DIR="${MVK_OUT_DIR:-$HOME/Desktop}"

if ! security find-certificate -c "$IDENTITY" >/dev/null 2>&1; then
    echo "Khong tim thay chung chi \"$IDENTITY\" trong Keychain." >&2
    echo "Xem huong dan tao chung chi trong tools/README.md." >&2
    exit 1
fi

cd "$PROJECT_DIR"
BUILD_DIR="$(mktemp -d)"
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR" "$STAGE_DIR"' EXIT

xcodebuild -project MacViKey.xcodeproj -scheme MacViKey -configuration Release \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
    CODE_SIGN_IDENTITY="" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" \
    CODE_SIGNING_ALLOWED=NO \
    build

APP="$BUILD_DIR/MacViKey.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"

# Ky tu trong ra ngoai: helper truoc, bundle ngoai sau.
find "$APP/Contents" -name '*.app' -not -path "$APP" -print0 |
    xargs -0 -I{} codesign --force --timestamp --options=runtime --sign "$IDENTITY" {}
codesign --force --timestamp --options=runtime --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"

echo ""
echo "Designated Requirement (phai giong het giua cac lan build):"
codesign -d -r- "$APP" 2>&1 | sed -n 's/^designated => /  /p'

# Dong goi .dmg: thu muc co san symlink /Applications de user keo tha.
cp -R "$APP" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

DMG="$OUT_DIR/MacViKey-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "MacViKey" -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG" >/dev/null

SHA="$(shasum -a 256 "$DMG" | cut -d' ' -f1)"

echo ""
echo "Da dong goi: $DMG"
echo "sha256: $SHA"
echo ""
echo "Cap nhat Casks/macvikey.rb trong repo homebrew-tap:"
echo "  version \"$VERSION\""
echo "  sha256 \"$SHA\""
