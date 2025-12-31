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

CHOICE=$(echo "$WALLPAPERS" | fuzzel --dmenu --prompt="󰸉 Wallpaper: " "--width=40%" "--lines=5")

if [ -n "$CHOICE" ]; then
    bash "$SETTER" "${WALL_DIR}/${CHOICE}"
fi
