#!/usr/bin/env bash
set -euo pipefail

wall_dir="${XDG_CONFIG_HOME:-$HOME/.config}/backgrounds"
workspace_link="$wall_dir/current.jpg"
backdrop_link="$wall_dir/current-blurry.jpg"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"

silent=false
restore=false
args=()
for arg in "$@"; do
    case "$arg" in
        --silent) silent=true ;;
        --restore) restore=true ;;
        *) args+=("$arg") ;;
    esac
done

if $restore; then
    workspace="$(readlink -f "$workspace_link" 2>/dev/null || true)"
    if [[ ! -f "$workspace" ]]; then
        workspace="$wall_dir/liftoff.png"
    fi
else
    if ((${#args[@]} == 0)); then
        echo "Usage: $0 <image> [backdrop] [--restore] [--silent]" >&2
        exit 2
    fi
    workspace="${args[0]}"
    backdrop="${args[1]:-}"
fi

if [[ ! -f "$workspace" ]]; then
    echo "Wallpaper not found: $workspace" >&2
    exit 1
fi
workspace="$(realpath "$workspace")"
mkdir -p "$wall_dir" "$cache_dir"

# Use an explicitly supplied backdrop when available; otherwise blur the
# selected workspace image once and reuse the cached result.
if [[ -n "${backdrop:-}" && -f "$backdrop" ]]; then
    backdrop="$(realpath "$backdrop")"
else
    command -v magick >/dev/null || { echo "ImageMagick (magick) is required" >&2; exit 1; }
    backdrop="$cache_dir/$(basename "${workspace%.*}")-blurred.jpg"
    if [[ ! -f "$backdrop" || "$workspace" -nt "$backdrop" ]]; then
        magick "$workspace" -resize 50% -blur 0x32 -resize 200% -quality 88 "$backdrop"
    fi
fi

ln -sfn "$workspace" "$workspace_link"
ln -sfn "$backdrop" "$backdrop_link"

# Niri uses separate wallpaper processes: swww for the workspace image and
# swaybg for the blurred backdrop. hyprpaper's socket protocol is Hyprland-
# specific; talking to it here silently left the workspace image unchanged.
if command -v swww >/dev/null; then
    if ! pgrep -x swww-daemon >/dev/null; then
        (swww-daemon >/dev/null 2>&1 &)
        for _ in {1..30}; do
            pgrep -x swww-daemon >/dev/null && break
            sleep 0.1
        done
    fi
    swww img "$workspace" --transition-type none
else
    echo "swww not found; cannot set Niri workspace wallpaper" >&2
fi

if command -v swaybg >/dev/null; then
    pkill -x swaybg 2>/dev/null || true
    swaybg -i "$backdrop" -m fill >/dev/null 2>&1 &
else
    echo "swaybg not found; cannot set Niri backdrop" >&2
fi

if ! $silent && command -v notify-send >/dev/null; then
    notify-send -a Wallpaper -i "$workspace" "Wallpaper applied" "$(basename "$workspace")"
fi
