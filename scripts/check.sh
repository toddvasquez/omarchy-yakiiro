#!/usr/bin/env bash
# Validate the theme palette, plates, sound, and Neovim forge.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 scripts/check_palette.py

required=(
  colors.toml
  icons.theme
  preview.png
  sounds/anvil.ogg
  nvim/lua/yakiiro_forge.lua
  nvim/plugin/yakiiro-forge.lua
  backgrounds/1-omarchy-stamped.jpg
  backgrounds/2-yakiiro-blade.jpg
  backgrounds/3-showa-workshop.jpg
  backgrounds/4-heisei-press.jpg
  backgrounds/5-coupon-bench.jpg
  docs/banner.png
  docs/palette.png
  docs/strike.png
  README.md
  LICENSE
)
for path in "${required[@]}"; do
  if [[ ! -s $path ]]; then
    echo "missing $path" >&2
    exit 1
  fi
done

if [[ "$(tr -d '[:space:]' < icons.theme)" != "Yaru-prussiangreen" ]]; then
  echo "icons.theme should name Yaru-prussiangreen" >&2
  exit 1
fi

magic="$(dd if=sounds/anvil.ogg bs=4 count=1 status=none)"
if [[ "$magic" != "OggS" ]]; then
  echo "sounds/anvil.ogg is not an Ogg file" >&2
  exit 1
fi

expect_size() {
  local path="$1"
  local want="$2"
  local got
  got="$(magick identify -format '%wx%h' "$path")"
  if [[ "$got" != "$want" ]]; then
    echo "$path is $got, expected $want" >&2
    exit 1
  fi
}

expect_size docs/banner.png 1600x680
expect_size docs/strike.png 1500x440
expect_size preview.png 1168x784

palette_size="$(magick identify -format '%wx%h' docs/palette.png)"
if [[ "$palette_size" != 1280x* ]]; then
  echo "docs/palette.png is $palette_size, expected width 1280" >&2
  exit 1
fi

for image in preview.png docs/banner.png docs/palette.png docs/strike.png backgrounds/*.jpg; do
  magick identify "$image" >/dev/null
done

tmp="$(mktemp -d)"
mkdir -p "$tmp/.local/state/omarchy/current"
printf '%s\n' yakiiro >"$tmp/.local/state/omarchy/current/theme.name"

set +e
nvim --headless -u NONE -i NONE -n \
  --cmd "let \$HOME='$tmp'" \
  --cmd "set rtp+=${ROOT}/nvim" \
  -c "runtime plugin/yakiiro-forge.lua" \
  -c "luafile ${ROOT}/scripts/check_nvim.lua" \
  -c "qa"
status=$?
set -e
rm -rf "$tmp"

if (( status != 0 )); then
  echo "neovim forge check failed ($status)" >&2
  exit "$status"
fi

echo "yakiiro check ok"
