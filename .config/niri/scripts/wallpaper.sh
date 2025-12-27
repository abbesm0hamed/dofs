#!/bin/bash
set -euo pipefail

WALL_DIR="${HOME}/.config/backgrounds"
FG_LINK="${WALL_DIR}/current.jpg"
BG_LINK="${WALL_DIR}/current-blurry.jpg"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <wallpaper_path> [backdrop_path]"
    exit 1
fi

FG_WALL="$(readlink -f "$1")"
BG_WALL="${2:-}"

# If no backdrop provided, look for blurry-* in the same dir
if [ -z "$BG_WALL" ]; then
    POTENTIAL_BG="$(dirname "$FG_WALL")/blurry-$(basename "$FG_WALL")"
    [ -f "$POTENTIAL_BG" ] && BG_WALL="$POTENTIAL_BG"
fi

# Apply Foreground (swww)
if [ -f "$FG_WALL" ]; then
    ln -nsf "$FG_WALL" "$FG_LINK"
    if pgrep -x swww-daemon >/dev/null; then
        swww img "$FG_WALL" --transition-type center
    fi
fi

# Apply Backdrop (swaybg)
if [ -f "$BG_WALL" ]; then
    ln -nsf "$BG_WALL" "$BG_LINK"
    pkill swaybg || true
    swaybg -i "$BG_WALL" -m fill &
fi
