#!/bin/bash
set -euo pipefail

# set-theme.sh [theme_name] [--from-picker] [--silent]

THEMES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/themes"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/themes"
STATE_FILE="$STATE_DIR/current_theme"

LEGACY_STATE_FILE="$THEMES_DIR/current_theme"
if [ -f "$LEGACY_STATE_FILE" ] && [ ! -f "$STATE_FILE" ]; then
    mkdir -p "$STATE_DIR"
    mv "$LEGACY_STATE_FILE" "$STATE_FILE"
fi

# Paths to generated output files
WAYBAR_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/theme.css"
ROFI_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/colors.rasi"
NIRI_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/niri/colors.kdl"
FOOT_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/foot/theme.ini"
WEZTERM_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/colors.lua"
MAKO_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/mako/config"
KITTY_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/theme.conf"
ALACRITTY_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/theme.toml"
RANGER_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/ranger/rc.conf"
YAZI_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/yazi/yazi.toml"
ZED_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/zed/settings.json"
WINDSURF_OUT="${XDG_CONFIG_HOME:-$HOME/.config}/Windsurf/User/settings.json"

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

# Ensure directories exist
mkdir -p "$THEMES_DIR"
mkdir -p "$STATE_DIR"

# Get theme (default to stored or first found)
PREV_THEME="$(cat "$STATE_FILE" 2>/dev/null || echo "")"
if [ -z "$PREV_THEME" ] && [ -f "$LEGACY_STATE_FILE" ]; then
    PREV_THEME="$(cat "$LEGACY_STATE_FILE" 2>/dev/null || echo "")"
fi
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

    sync_file "waybar-theme.css" "$WAYBAR_OUT"
    sync_file "rofi-colors.rasi" "$ROFI_OUT"
    sync_file "niri-colors.kdl" "$NIRI_OUT"
    sync_file "foot-theme.ini" "$FOOT_OUT"
    sync_file "wezterm-colors.lua" "$WEZTERM_OUT"
    sync_file "mako-theme.conf" "$MAKO_OUT"
    sync_file "kitty-theme.conf" "$KITTY_OUT"
    sync_file "alacritty-theme.toml" "$ALACRITTY_OUT"
    sync_file "ranger-theme.conf" "$RANGER_OUT"
    sync_file "yazi-theme.toml" "$YAZI_OUT"
    sync_file "zed-theme.json" "$ZED_OUT"
    sync_file "windsurf-theme.json" "$WINDSURF_OUT"

    # Apply GTK theme if specified
    if [ -f "$path/gtk-theme.txt" ]; then
        local gtk_theme
        gtk_theme=$(cat "$path/gtk-theme.txt")
        echo "  → Applying GTK theme: $gtk_theme"
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
        
        # Set color-scheme based on theme name suffix or content
        if [[ "$gtk_theme" == *"-dark"* ]] || [[ "$gtk_theme" == *"-Dark"* ]]; then
            gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
        else
            gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
        fi
    fi

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
    local wall_conf="$path/wallpapers.conf"
    local wall_dir="${HOME}/.config/backgrounds"
    
    # Absolute path to theme dir
    local full_path
    full_path=$(realpath "$path")

    # Declarative wallpapers.conf
    if [ -f "$wall_conf" ]; then
        echo "  → Reading declarative wallpapers from wallpapers.conf"
        local ws_name
        local bd_name
        ws_name=$(grep "^workspace=" "$wall_conf" | cut -d'=' -f2)
        bd_name=$(grep "^backdrop=" "$wall_conf" | cut -d'=' -f2)
        
        [ -n "$ws_name" ] && [ -f "$wall_dir/$ws_name" ] && wall="$wall_dir/$ws_name"
        [ -n "$bd_name" ] && [ -f "$wall_dir/$bd_name" ] && backdrop="$wall_dir/$bd_name"
    fi

    # Fallback to legacy backgrounds/ directory or root of theme
    if [ -z "$wall" ]; then
        for f in "$full_path/backgrounds/default-workspace".{jpg,png,webp,jpeg,JPG,PNG} \
                 "$full_path/backgrounds/workspace".{jpg,png,webp,jpeg,JPG,PNG} \
                 "$full_path/workspace".{jpg,png,webp,jpeg,JPG,PNG}; do
            [ -f "$f" ] && wall="$f" && break
        done
    fi
    if [ -z "$backdrop" ]; then
        for f in "$full_path/backgrounds"/{default-backdrop,backdrop,blurry-workspace}.{jpg,png,webp,jpeg,JPG,PNG} \
                 "$full_path"/{default-backdrop,backdrop,blurry-workspace}.{jpg,png,webp,jpeg,JPG,PNG}; do
            [ -f "$f" ] && backdrop="$f" && break
        done
    fi

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
if pgrep -x waybar >/dev/null 2>&1; then
    WAYBAR_STATE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.current-variant"
    WAYBAR_SWITCHER="$HOME/.config/niri/scripts/waybar-switcher.sh"
    if [ -x "$WAYBAR_SWITCHER" ]; then
        variant="$(cat "$WAYBAR_STATE" 2>/dev/null || echo "default")"
        "$WAYBAR_SWITCHER" "$variant" >/dev/null 2>&1 || true
    else
        pkill -USR2 waybar || true
    fi
else
    pkill -USR2 waybar || true
fi
command -v makoctl >/dev/null && makoctl reload || true

if [ "$FROM_PICKER" = true ]; then
    notify-send -a "Theme" "Applied: $THEME"
fi
echo "Theme '$THEME' applied successfully."
