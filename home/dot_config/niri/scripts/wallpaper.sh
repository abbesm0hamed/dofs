#!/bin/bash
set -euo pipefail

# Prevent race conditions with flock using a separate lock file
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper.lock"
exec 200>"$LOCK_FILE"
flock -n 200 || {
    echo "Another instance is running"
    exit 0
}

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

FG_WALL=""
BG_WALL=""

# Resolve Wallpaper
if [ "${1:-}" == "--restore" ]; then
    [ -L "$FG_LINK" ] && FG_WALL=$(readlink -f "$FG_LINK")
    [ -L "$BG_LINK" ] && BG_WALL=$(readlink -f "$BG_LINK")
    [ -z "$FG_WALL" ] && echo "Nothing to restore." && exit 0
else
    if [ -d "$1" ]; then
        DIR_PATH="$(readlink -f "$1")"
        shopt -s nullglob
        for f in "$DIR_PATH"/default-workspace.{jpg,png,webp,jpeg,JPG,PNG,WEBP,JPEG} "$DIR_PATH"/workspace.{jpg,png,webp,jpeg,JPG,PNG,WEBP,JPEG}; do
            [ -f "$f" ] && FG_WALL="$f" && break
        done
        for f in "$DIR_PATH"/default-backdrop.{jpg,png,webp,jpeg,JPG,PNG,WEBP,JPEG} "$DIR_PATH"/backdrop.{jpg,png,webp,jpeg,JPG,PNG,WEBP,JPEG} "$DIR_PATH"/blurry-workspace.{jpg,png,webp,jpeg,JPG,PNG,WEBP,JPEG}; do
            [ -f "$f" ] && BG_WALL="$f" && break
        done
        shopt -u nullglob
        [ -z "$FG_WALL" ] && echo "No workspace image found in $DIR_PATH" && exit 1
        [ -n "$FG_WALL" ] && FG_WALL="$(readlink -f "$FG_WALL")"
        [ -n "$BG_WALL" ] && BG_WALL="$(readlink -f "$BG_WALL")"
    else
        FG_WALL="$(readlink -f "$1")"
        BG_WALL="${2:-}"
        
        # Background resolution logic
        if [ -z "$BG_WALL" ]; then
            POTENTIAL_BG="$(dirname "$FG_WALL")/blurry-$(basename "$FG_WALL")"
            [ -f "$POTENTIAL_BG" ] && BG_WALL="$POTENTIAL_BG"
        fi
        [ -n "$BG_WALL" ] && [ -f "$BG_WALL" ] && BG_WALL="$(readlink -f "$BG_WALL")"
    fi

    # Update symlinks
    mkdir -p "$WALL_DIR"
    [ -f "$FG_WALL" ] && ln -nsf "$FG_WALL" "$FG_LINK"
    [ -n "$BG_WALL" ] && [ -f "$BG_WALL" ] && ln -nsf "$BG_WALL" "$BG_LINK"
fi

# Foreground manager (hyprpaper)
apply_foreground() {
    [ ! -f "$FG_WALL" ] && return
    if ! command -v hyprpaper >/dev/null; then
        echo "hyprpaper not found; skipping foreground wallpaper"
        return
    fi
    if ! command -v socat >/dev/null; then
        echo "socat not found; cannot control hyprpaper"
        return
    fi
    local HYPR_SOCK="${XDG_RUNTIME_DIR}/hypr/.hyprpaper.sock"

    if ! pgrep -x hyprpaper >/dev/null; then
        hyprpaper &
        for i in {1..30}; do [ -S "$HYPR_SOCK" ] && break; sleep 0.1; done
    fi

    if [ -S "$HYPR_SOCK" ]; then
        echo "preload $FG_WALL" | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
        echo "wallpaper ,$FG_WALL" | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
        echo "unload unused" | socat - UNIX-CONNECT:"$HYPR_SOCK" || true
    fi
}

# Backdrop manager (swaybg)
apply_backdrop() {
    [ -z "$BG_WALL" ] || [ ! -f "$BG_WALL" ] && return
    if ! command -v swaybg >/dev/null; then
        echo "swaybg not found; skipping backdrop wallpaper"
        return
    fi
    pkill -x swaybg || true
    swaybg -i "$BG_WALL" -m fill &
}

# Run
apply_foreground &
apply_backdrop &
wait

if [ "$SILENT" = false ]; then
    notify-send -a "Wallpaper" -i "$FG_WALL" "Wallpaper Applied" "$(basename "$FG_WALL")" || true
fi
