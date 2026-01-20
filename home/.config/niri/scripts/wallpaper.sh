#!/bin/bash
set -euo pipefail

# Prevent race conditions with flock using a separate lock file
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper.lock"
exec 200>"$LOCK_FILE"
flock -n 200 || { echo "Another instance is running"; exit 0; }

WALL_DIR="${HOME}/.config/backgrounds"
FG_LINK="${WALL_DIR}/current.jpg"
BG_LINK="${WALL_DIR}/current-blurry.jpg"

# Parse arguments
SILENT=false
FILES=()
for arg in "$@"; do
    if [ "$arg" == "--silent" ]; then
        SILENT=true
    else
        FILES+=("$arg")
    fi
done
set -- "${FILES[@]}"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <wallpaper_path> [backdrop_path] [--silent]"
    exit 1
fi

FG_WALL="$(readlink -f "$1")"
BG_WALL="${2:-}"

# Background resolution logic
if [ -z "$BG_WALL" ]; then
    POTENTIAL_BG="$(dirname "$FG_WALL")/blurry-$(basename "$FG_WALL")"
    [ -f "$POTENTIAL_BG" ] && BG_WALL="$POTENTIAL_BG"
fi
[ -n "$BG_WALL" ] && [ -f "$BG_WALL" ] && BG_WALL="$(readlink -f "$BG_WALL")"

# Update symlinks early (so initial startup sees correct files)
[ -f "$FG_WALL" ] && ln -nsf "$FG_WALL" "$FG_LINK"
[ -n "$BG_WALL" ] && [ -f "$BG_WALL" ] && ln -nsf "$BG_WALL" "$BG_LINK"

# Foreground manager (hyprpaper)
apply_foreground() {
    if [ ! -f "$FG_WALL" ]; then return; fi

    # hyprpaper socket location
    local HYPR_SOCK="${XDG_RUNTIME_DIR}/hypr/.hyprpaper.sock"

    if ! pgrep -x hyprpaper >/dev/null; then
        echo "  → Starting hyprpaper..."
        hyprpaper &
        # Wait for socket to appear
        for i in {1..30}; do
            [ -S "$HYPR_SOCK" ] && break
            sleep 0.1
        done
    fi

    if [ -S "$HYPR_SOCK" ]; then
        echo "IPC: preload $FG_WALL"
        echo "preload $FG_WALL" | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
        sleep 0.1
        echo "IPC: wallpaper ,$FG_WALL"
        echo "wallpaper ,$FG_WALL" | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
        sleep 0.1
        echo "unload unused" | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
    else
        echo "Error: hyprpaper socket not found at $HYPR_SOCK" >&2
        if [ "$SILENT" = false ]; then
            notify-send -u critical "Wallpaper Error" "hyprpaper socket not found" || true
        fi
    fi
}

# Backdrop manager (swaybg)
apply_backdrop() {
    if [ -z "$BG_WALL" ] || [ ! -f "$BG_WALL" ]; then return; fi

    # Start new instance first for smoother transition
    swaybg -i "$BG_WALL" -m fill &
    local NEW_PID=$!

    # Clean up old instances after a brief transition period
    (
        sleep 1
        pgrep -x swaybg | grep -v "$NEW_PID" | xargs kill 2>/dev/null || true
    ) &
}

# Run foreground and backdrop in parallel
apply_foreground &
apply_backdrop &

wait
echo "Wallpapers updated successfully."
if [ "$SILENT" = false ]; then
    notify-send -a "Wallpaper" -i "$FG_WALL" "Wallpaper Applied" "$(basename "$FG_WALL")" || true
fi