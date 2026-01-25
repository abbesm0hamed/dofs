#!/bin/bash
set -euo pipefail

# set-theme.sh [theme_name] [--from-picker] [--silent]

THEMES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/themes"
STATE_FILE="$THEMES_DIR/current_theme"

# Paths to generated output files
WAYBAR_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/theme.css"
ROFI_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/colors.rasi"
NIRI_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/niri/colors.kdl"
FOOT_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/foot/theme.ini"
WEZTERM_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/colors.lua"
MAKO_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/mako/config"
HYPRLOCK_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock.conf"
KITTY_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/theme.conf"
ALACRITTY_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/theme.toml"
RANGER_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/ranger/rc.conf"
YAZI_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/yazi/yazi.toml"
ZED_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/zed/settings.json"

# Parse flags
FROM_PICKER=false
SKIP_WALLPAPER=false
SILENT=false
POSITIONAL_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --from-picker) FROM_PICKER=true ;;
        --skip-wallpaper) SKIP_WALLPAPER=true ;;
        --silent) SILENT=true ;;
        *) POSITIONAL_ARGS+=("$arg") ;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}"

# Ensure themes directory exists
mkdir -p "$THEMES_DIR"

# Get theme (default to stored or first found)
PREV_THEME="$(cat "$STATE_FILE" 2>/dev/null || echo "")"
THEME="${1:-$PREV_THEME}"

if [ -z "$THEME" ]; then
    echo "No theme specified and no previous theme found."
    exit 1
fi

apply_theme() {
    local name="$1"
    local path="$THEMES_DIR/$name"
    
    [ ! -d "$path" ] && echo "Error: Theme '$name' not found" && exit 1
    echo "Applying Theme: $name"
    
    # Sync files
    sync_file() {
        local src="$1" dest="$2"
        if [ -f "$path/$src" ]; then
            mkdir -p "$(dirname "$dest")"
            cp "$path/$src" "$dest"
            echo "  → Synced $src"
        fi
    }

    sync_file "theme.css" "$WAYBAR_OUT"
    sync_file "colors.rasi" "$ROFI_OUT"
    sync_file "colors.kdl" "$NIRI_OUT"
    sync_file "theme.ini" "$FOOT_OUT"
    sync_file "colors.lua" "$WEZTERM_OUT"
    sync_file "mako.conf" "$MAKO_OUT"
    sync_file "hyprlock.conf" "$HYPRLOCK_OUT"
    sync_file "kitty.conf" "$KITTY_OUT"
    sync_file "alacritty.toml" "$ALACRITTY_OUT"
    sync_file "ranger.conf" "$RANGER_OUT"
    sync_file "yazi.toml" "$YAZI_OUT"
    sync_file "zed-settings.json" "$ZED_OUT"

    # Save state early
    echo "$name" > "$STATE_FILE"

    # Live-reload terminals if running
    if command -v kitty &>/dev/null && pgrep -x kitty &>/dev/null; then
        kitty @ set-colors --all "$KITTY_OUT" || true
    fi

    if pgrep -x alacritty &>/dev/null; then
        pkill -USR1 alacritty || true
    fi

    # Resolve theme-specific wallpaper
    local wall=""
    local backdrop=""
    
    # Absolute path to theme dir
    local full_path
    full_path=$(realpath "$path")

    # Look for workspace wall
    for f in "$full_path/backgrounds/default-workspace".{jpg,png,webp,jpeg,JPG,PNG} \
             "$full_path/backgrounds/workspace".{jpg,png,webp,jpeg,JPG,PNG} \
             "$full_path/workspace".{jpg,png,webp,jpeg,JPG,PNG}; do
        [ -f "$f" ] && wall="$f" && break
    done
    # Look for backdrop wall
    for f in "$full_path/backgrounds"/{default-backdrop,backdrop,blurry-workspace}.{jpg,png,webp,jpeg,JPG,PNG} \
             "$full_path"/{default-backdrop,backdrop,blurry-workspace}.{jpg,png,webp,jpeg,JPG,PNG}; do
        [ -f "$f" ] && backdrop="$f" && break
    done

    # Apply wallpaper if found and not skipped
    if [ "$SKIP_WALLPAPER" = false ] && [ -n "$wall" ]; then
        echo "  → Applying theme wallpapers..."
        # Clear any stale lock just in case
        rm -f "${XDG_RUNTIME_DIR:-/tmp}/wallpaper.lock"
        bash "$HOME/.config/niri/scripts/wallpaper.sh" "$wall" "$backdrop" --silent || true
    fi
}

# Apply
apply_theme "$THEME"

# Reload & Notify
pkill -USR2 waybar || true
command -v makoctl >/dev/null && makoctl reload || true

if [ "$FROM_PICKER" = true ]; then
    notify-send -a "Theme" "Applied: $THEME"
fi
echo "Theme '$THEME' applied successfully."
