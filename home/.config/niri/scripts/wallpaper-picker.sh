#!/bin/bash
set -euo pipefail

WALL_DIR="${HOME}/.config/backgrounds"
SETTER="${HOME}/.config/niri/scripts/wallpaper.sh"

# Find all images but exclude those starting with blurry or current
WALLPAPERS=$(ls "$WALL_DIR" | grep -E '\.(jpg|png|webp)$' | grep -vE '^(blurry-|current|generated-)' || true)

if [ -z "$WALLPAPERS" ]; then
    notify-send "Wallpaper" "No images found in $WALL_DIR"
    exit 1
fi

CHOICE=$(echo "$WALLPAPERS" | rofi -dmenu -i -p "󰸉 Wallpaper: ")

if [ -n "$CHOICE" ]; then
    FULL_PATH="${WALL_DIR}/${CHOICE}"
    notify-send -a "Wallpaper" -i "$FULL_PATH" "Applying Wallpaper" "$CHOICE"
    # Clear any stale lock
    rm -f "${XDG_RUNTIME_DIR:-/tmp}/wallpaper.lock"
    bash "$SETTER" "$(realpath "$FULL_PATH")"
fi
