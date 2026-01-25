#!/bin/bash
set -euo pipefail

WALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/backgrounds"
REPO_WALL_DIR="$HOME/dofs/home/.config/backgrounds"
SETTER="${HOME}/.config/niri/scripts/wallpaper.sh"

if ! command -v rofi >/dev/null 2>&1; then
    msg="rofi not found; install it to pick wallpapers."
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Wallpaper" "$msg"
    fi
    echo "$msg"
    exit 1
fi

WALLPAPERS=""
for DIR in "$WALL_DIR" "$REPO_WALL_DIR"; do
    [ -d "$DIR" ] || continue
    WALLPAPERS=$(find "$DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        ! -iname 'blurry-*' ! -iname 'current*' ! -iname 'generated-*' \
        -printf '%f\n' | sort || true)
    if [ -n "$WALLPAPERS" ]; then
        WALL_DIR="$DIR"
        break
    fi
done

if [ -z "$WALLPAPERS" ]; then
    notify-send "Wallpaper" "No images found in $WALL_DIR or fallback"
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
