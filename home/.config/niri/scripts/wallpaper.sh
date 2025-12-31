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

# Apply Foreground (hyprpaper)
if [ -f "$FG_WALL" ]; then
    ln -nsf "$FG_WALL" "$FG_LINK"
    
    # IPC components
    HYPR_SOCK_DIR="${XDG_RUNTIME_DIR}/hypr"
    HYPR_SOCK="${HYPR_SOCK_DIR}/.hyprpaper.sock"

    # Initialize hyprpaper if not running
    if ! pgrep -x hyprpaper >/dev/null; then
        mkdir -p "$HYPR_SOCK_DIR"
        hyprpaper &
        # Wait for socket
        for i in {1..20}; do
            [ -S "$HYPR_SOCK" ] && break
            sleep 0.1
        done
    fi
    
    # IPC commands for hyprpaper
    if [ -S "$HYPR_SOCK" ]; then
        # Unload all, preload new, and set wallpaper
        echo "preload $FG_WALL" | socat - UNIX-CONNECT:"$HYPR_SOCK"
        echo "wallpaper ,$FG_WALL" | socat - UNIX-CONNECT:"$HYPR_SOCK"
        # Optional: unload unused to save RAM
        echo "unload unused" | socat - UNIX-CONNECT:"$HYPR_SOCK"
    else
         echo "Error: hyprpaper socket not found at $HYPR_SOCK" >&2
    fi
fi

# Apply Backdrop (swaybg)
if [ -f "$BG_WALL" ]; then
    ln -nsf "$BG_WALL" "$BG_LINK"
    pkill swaybg || true
    swaybg -i "$BG_WALL" -m fill &
fi
