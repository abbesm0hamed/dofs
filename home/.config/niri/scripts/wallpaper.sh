#!/bin/bash
set -euo pipefail

# Prevent race conditions with flock
[ "${FLOCKER:-}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :

WALL_DIR="${HOME}/.config/backgrounds"
FG_LINK="${WALL_DIR}/current.jpg"
BG_LINK="${WALL_DIR}/current-blurry.jpg"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <wallpaper_path> [backdrop_path]"
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

    local HYPR_SOCK="${XDG_RUNTIME_DIR}/hypr/.hyprpaper.sock"

    if ! pgrep -x hyprpaper >/dev/null; then
        # If not running, start it. It will read the symlink from its config.
        hyprpaper &
        return
    fi

    # Batch IPC commands into a single socat call
    if [ -S "$HYPR_SOCK" ]; then
        {
            echo "preload $FG_WALL"
            echo "wallpaper ,$FG_WALL"
            echo "unload unused"
        } | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
    else
        echo "Warning: hyprpaper socket not found" >&2
    fi
}

# Backdrop manager (swaybg)
apply_backdrop() {
    if [ -z "$BG_WALL" ] || [ ! -f "$BG_WALL" ]; then return; fi

    # Start new instance first for smoother transition
    swaybg -i "$BG_WALL" -m fill &
    local NEW_PID=$!

    # Wait a moment for the new one to map, then kill old ones
    (
        sleep 0.5
        pgrep -x swaybg | grep -v "$NEW_PID" | xargs kill 2>/dev/null || true
    ) &
}

# Run foreground and backdrop in parallel
apply_foreground &
apply_backdrop &

wait
echo "Wallpapers updated successfully."