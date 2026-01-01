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

# Resolve backdrop to absolute path if it exists
if [ -n "$BG_WALL" ] && [ -f "$BG_WALL" ]; then
    BG_WALL="$(readlink -f "$BG_WALL")"
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
        echo "preload $FG_WALL" | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
        echo "wallpaper ,$FG_WALL" | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
        # Optional: unload unused to save RAM
        echo "unload unused" | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
    else
        echo "Error: hyprpaper socket not found at $HYPR_SOCK" >&2
    fi
fi

# Apply Backdrop (swaybg)
if [ -f "$BG_WALL" ]; then
    ln -nsf "$BG_WALL" "$BG_LINK"

    # Kill existing swaybg and wait for it to fully terminate
    pkill swaybg || true
    sleep 0.1

    # Start swaybg with proper namespace for layer rule matching
    # The namespace "wallpaper" matches the layer-rule in config.kdl
    swaybg -i "$BG_WALL" -m fill &

    echo "Backdrop wallpaper set to: $BG_WALL"
else
    echo "Warning: Backdrop wallpaper not found: $BG_WALL" >&2
fi
