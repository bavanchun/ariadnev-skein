#!/bin/bash
# Build a distributable disk image from an already-signed Skein.app.
#
# The DMG is for the website download button. Sparkle keeps updating from the
# ZIP: it does not have to mount a volume that way, which is faster and is why
# the appcast enclosure is left alone by this script.
#
# Usage: scripts/make-dmg.sh <path-to-Skein.app> [output-dir]
set -euo pipefail

APP="${1:?usage: make-dmg.sh <path-to-Skein.app> [output-dir]}"
OUT_DIR="${2:-.release-output}"

[[ -d "$APP" ]] || { echo "error: no app bundle at $APP" >&2; exit 1; }

VERSION=$(defaults read "$(cd "$APP" && pwd)/Contents/Info.plist" CFBundleShortVersionString)
VOL_NAME="Skein $VERSION"
DMG="$OUT_DIR/Skein-$VERSION.dmg"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$OUT_DIR"
rm -f "$DMG"

# Stage exactly what the user should see when the volume opens: the app, and a
# shortcut to drag it into. ditto (not cp) preserves the signature.
ditto "$APP" "$STAGE/Skein.app"
ln -s /Applications "$STAGE/Applications"

# UDZO = zlib-compressed, read-only: the standard format for a shipped DMG.
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "$DMG" >/dev/null

# Sign the image itself when a codesigning identity exists, so the download
# carries the same authority as the app inside it. Unsigned is not fatal.
CERT=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | awk -F'"' '{print $2}' || true)
if [[ -n "$CERT" ]]; then
  codesign --force --sign "$CERT" "$DMG"
  codesign --verify --verbose=2 "$DMG" 2>&1 | sed 's/^/  /'
else
  echo "  note: no codesigning identity found; DMG left unsigned"
fi

echo "$DMG"
ls -lh "$DMG" | awk '{print "  size: "$5}'
shasum -a 256 "$DMG" | awk '{print "  sha256: "$1}'
