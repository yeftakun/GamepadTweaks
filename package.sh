#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

MANIFEST_FX="extension/lua/joypad-assist/gamepad_tweaks/manifest.ini"
MANIFEST_UI="apps/lua/gamepad_tweaks/manifest.ini"

command -v zip >/dev/null || { echo "ERROR: zip not found. Install it: sudo apt install zip"; exit 1; }

# Baca versi dari manifest script dan app
ver() { grep -m1 '^VERSION' "$1" | cut -d= -f2 | tr -d ' \r' || true; }
VER_FX=$(ver "$MANIFEST_FX")
VER_UI=$(ver "$MANIFEST_UI")

[ -n "$VER_FX" ] && [ -n "$VER_UI" ] || { echo "ERROR: VERSION not found in manifest"; exit 1; }
[ "$VER_FX" = "$VER_UI" ] || { echo "ERROR: version mismatch - script $VER_FX vs app $VER_UI"; exit 1; }

# Build zip
ZIP="dist/gamepad-tweaks-v$VER_FX.zip"
mkdir -p dist
rm -f "$ZIP"
zip -r -X -q "$ZIP" README.md assets apps extension

echo "Created $ZIP"
echo
unzip -l "$ZIP"