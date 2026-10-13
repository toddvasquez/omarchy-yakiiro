#!/usr/bin/env bash
# Render the README plates. The palette is generated from colors.toml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p docs

python3 scripts/render_palette.py

FONT="/tmp/yakiiro-fonts/NotoSerifJP-500.ttf"
if [[ ! -s $FONT ]]; then
  mkdir -p /tmp/yakiiro-fonts
  curl -fsSL -o "$FONT" \
    "https://fonts.gstatic.com/s/notoserifjp/v34/xn71YHs72GKoTvER4Gn3b5eMRtWGkp6o7MjQ2bwDOubA.ttf"
fi

shot() {
  local html="$1"
  local out="$2"
  local width="$3"
  local height="$4"
  local profile
  profile="$(mktemp -d)"
  if ! chromium \
    --headless \
    --disable-gpu \
    --no-sandbox \
    --hide-scrollbars \
    --force-device-scale-factor=1 \
    --allow-file-access-from-files \
    --window-size="${width},${height}" \
    --user-data-dir="$profile" \
    --screenshot="$out" \
    "file://$html" \
    >/tmp/yakiiro-chromium.log 2>&1; then
    echo "chromium failed while rendering $out" >&2
    cat /tmp/yakiiro-chromium.log >&2
    rm -rf "$profile"
    exit 1
  fi
  rm -rf "$profile"
}

banner_html="$(mktemp --suffix=.html)"
# The shot is a temp file, so the blade has to be an absolute file URL.
blade="file://${ROOT}/backgrounds/2-yakiiro-blade.jpg"
sed \
  -e "s|__YAKIIRO_JP__|file://${FONT}|g" \
  -e "s|url(\"../../backgrounds/2-yakiiro-blade.jpg\")|url(\"${blade}\")|" \
  docs/src/banner.html >"$banner_html"

shot "$banner_html" "$ROOT/docs/banner.png" 1600 680
rm -f "$banner_html"

shot "$ROOT/docs/src/strike.html" "$ROOT/docs/strike.png" 1500 440

profile="$(mktemp -d)"
shot_ok=0
if chromium \
  --headless \
  --disable-gpu \
  --no-sandbox \
  --hide-scrollbars \
  --force-device-scale-factor=1 \
  --allow-file-access-from-files \
  --window-size=1280,2200 \
  --user-data-dir="$profile" \
  --screenshot="/tmp/yakiiro-palette-tall.png" \
  "file://$ROOT/docs/src/palette.html" \
  >/tmp/yakiiro-chromium.log 2>&1; then
  shot_ok=1
fi
rm -rf "$profile"
if (( shot_ok != 1 )); then
  echo "chromium failed while measuring the palette" >&2
  cat /tmp/yakiiro-chromium.log >&2
  exit 1
fi

palette_height="$(python3 - <<'PY'
import subprocess
from pathlib import Path

ident = subprocess.check_output(
    ["magick", "identify", "-format", "%w %h", "/tmp/yakiiro-palette-tall.png"],
    text=True,
)
width, height = (int(part) for part in ident.split())
raw = subprocess.check_output(
    ["magick", "/tmp/yakiiro-palette-tall.png", "-depth", "8", "rgb:-"]
)
background = bytes((0x14, 0x13, 0x1A))
last = 0
for y in range(height):
    row = raw[y * width * 3 : (y + 1) * width * 3]
    if row != background * width:
        last = y
if width != 1280:
    raise SystemExit(f"palette width {width}, expected 1280")
print(last + 1)
PY
)"

if (( palette_height < 400 || palette_height > 2100 )); then
  echo "palette height looks wrong: $palette_height" >&2
  exit 1
fi

magick /tmp/yakiiro-palette-tall.png -crop "1280x${palette_height}+0+0" +repage "$ROOT/docs/palette.png"
echo "docs/banner.png $(magick identify -format '%wx%h' docs/banner.png)"
echo "docs/strike.png $(magick identify -format '%wx%h' docs/strike.png)"
echo "docs/palette.png $(magick identify -format '%wx%h' docs/palette.png)"
