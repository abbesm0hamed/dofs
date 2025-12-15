#!/bin/bash

# Theme Manager for dofs
# Manages unified default theme across all components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOFS_DIR="$(dirname "$SCRIPT_DIR")"
THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
if [ ! -d "$THEME_DIR" ]; then
    THEME_DIR="$DOFS_DIR/.config/theme"
fi
CURRENT_THEME_LINK="$HOME/.config/theme-current"
CONFIG_DIR="$HOME/.config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_step() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# List available themes
list_themes() {
    log_step "Available themes:"
    if [ -d "$THEME_DIR" ]; then
        for theme in "$THEME_DIR"/*; do
            if [ -d "$theme" ]; then
                theme_name=$(basename "$theme")
                echo "  - $theme_name"
            fi
        done
    else
        log_error "Theme directory not found: $THEME_DIR"
        return 1
    fi
}

# Set a theme
set_theme() {
    local theme_name="$1"

    if [ -z "$theme_name" ]; then
        log_error "Theme name required"
        return 1
    fi

    local theme_path="$THEME_DIR/$theme_name"

    if [ ! -d "$theme_path" ]; then
        if [ "$theme_name" = "default" ]; then
            theme_name="default"
            theme_path="$THEME_DIR/$theme_name"
        else
            log_error "Theme not found: $theme_name"
            return 1
        fi
    fi

    log_step "Setting theme: $theme_name"

    # Create symlink to current theme
    mkdir -p "$(dirname "$CURRENT_THEME_LINK")"
    ln -nsf "$theme_path" "$CURRENT_THEME_LINK"
    log_success "Theme symlink created"

    # Apply theme to each component
    apply_niri_theme "$theme_path"
    apply_waybar_theme "$theme_path"
    apply_mako_theme "$theme_path"
    apply_fuzzel_theme "$theme_path"
    apply_ghostty_theme "$theme_path"

    log_success "Theme '$theme_name' applied successfully"
}

# Apply Niri theme
apply_niri_theme() {
    local theme_path="$1"
    local niri_conf="$theme_path/niri.conf"

    if [ ! -f "$niri_conf" ]; then
        log_warning "Niri theme file not found: $niri_conf"
        return 0
    fi

    log_step "Applying Niri theme..."

    # Create niri config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR/niri"

    # Copy the niri theme file
    cp "$niri_conf" "$CONFIG_DIR/niri/theme.conf"

    if [ -f "$CONFIG_DIR/niri/config.kdl" ]; then
        local blue surface1 red bar_bg
        blue="$(awk -F'= ' '/^\$blue[[:space:]]*=/{print $2}' "$niri_conf" 2>/dev/null | head -n1)"
        surface1="$(awk -F'= ' '/^\$surface1[[:space:]]*=/{print $2}' "$niri_conf" 2>/dev/null | head -n1)"
        red="$(awk -F'= ' '/^\$red[[:space:]]*=/{print $2}' "$niri_conf" 2>/dev/null | head -n1)"

        if [ -f "$theme_path/waybar.css" ]; then
            bar_bg="$(awk '/^@define-color[[:space:]]+bar_bg[[:space:]]+/{print $3}' "$theme_path/waybar.css" 2>/dev/null | head -n1 | tr -d ';')"
        fi

        if [ -n "$blue" ]; then
            sed -i -E "s/(active-color[[:space:]]+)\"#[0-9a-fA-F]{6}\"/\1\"$blue\"/" "$CONFIG_DIR/niri/config.kdl" || true
        fi
        if [ -n "$surface1" ]; then
            sed -i -E "s/(inactive-color[[:space:]]+)\"#[0-9a-fA-F]{6}\"/\1\"$surface1\"/" "$CONFIG_DIR/niri/config.kdl" || true
        fi
        if [ -n "$red" ]; then
            sed -i -E "s/(urgent-color[[:space:]]+)\"#[0-9a-fA-F]{6}\"/\1\"$red\"/" "$CONFIG_DIR/niri/config.kdl" || true
        fi

        if [ -n "$bar_bg" ]; then
            sed -i -E "s/(background-color[[:space:]]+)\"[^\"]*\"/\1\"$bar_bg\"/" "$CONFIG_DIR/niri/config.kdl" || true
            sed -i -E "s/(backdrop-color[[:space:]]+)\"[^\"]*\"/\1\"$bar_bg\"/" "$CONFIG_DIR/niri/config.kdl" || true
        fi
    fi
}

# Apply Waybar theme
apply_waybar_theme() {
    local theme_path="$1"
    local waybar_css="$theme_path/waybar.css"

    if [ ! -f "$waybar_css" ]; then
        log_warning "Waybar theme file not found: $waybar_css"
        return 0
    fi

    log_step "Applying Waybar theme..."

    mkdir -p "$CONFIG_DIR/waybar"

    # Reload Waybar
    if command -v waybar >/dev/null; then
        if pgrep -x waybar >/dev/null; then
             pkill -x waybar || true
             sleep 0.5
        fi
        waybar &> /dev/null &
        log_success "Waybar reloaded"
    fi
}

# Apply Mako theme
apply_mako_theme() {
    local theme_path="$1"
    local mako_ini="$theme_path/mako.ini"

    if [ ! -f "$mako_ini" ]; then
        log_warning "Mako theme file not found: $mako_ini"
        return 0
    fi

    log_step "Applying Mako theme..."

    mkdir -p "$CONFIG_DIR/mako"
    cp "$mako_ini" "$CONFIG_DIR/mako/config"

    # Reload Mako
    if command -v makoctl >/dev/null; then
        if pgrep -x mako >/dev/null 2>&1; then
            if makoctl reload 2>/dev/null; then
                log_success "Mako reloaded"
            else
                log_warning "Could not reload mako"
            fi
        else
            log_success "Mako theme applied (mako not running)"
        fi
    fi
}

# Apply fuzzel theme
apply_fuzzel_theme() {
    local theme_path="$1"
    local fuzzel_ini="$theme_path/fuzzel.ini"

    if [ ! -f "$fuzzel_ini" ]; then
        log_warning "fuzzel theme file not found: $fuzzel_ini"
        return 0
    fi

    log_step "Applying fuzzel theme..."

    mkdir -p "$CONFIG_DIR/fuzzel"

    local target_ini="$CONFIG_DIR/fuzzel/fuzzel.ini"
    if [ ! -f "$target_ini" ]; then
        log_warning "fuzzel config not found: $target_ini"
        log_warning "Theme not applied to fuzzel (create $target_ini first)"
        return 0
    fi

    local target_real
    target_real="$(readlink -f "$target_ini" 2>/dev/null || true)"
    if [ -z "$target_real" ]; then
        target_real="$target_ini"
    fi

    # Replace (or append) the [colors] section in the main fuzzel.ini.
    # fuzzel does not support an include directive.
    awk -v theme_file="$fuzzel_ini" '
        BEGIN {
            in_colors = 0
            inserted = 0
            while ((getline line < theme_file) > 0) {
                theme[++n] = line
            }
            close(theme_file)
        }
        /^\[colors\]$/ {
            if (!inserted) {
                for (i = 1; i <= n; i++) print theme[i]
                inserted = 1
            }
            in_colors = 1
            next
        }
        in_colors && /^\[.*\]$/ {
            in_colors = 0
        }
        !in_colors {
            print
        }
        END {
            if (!inserted) {
                print ""
                for (i = 1; i <= n; i++) print theme[i]
            }
        }
    ' "$target_real" > "$target_real.tmp" && mv "$target_real.tmp" "$target_real"

    log_success "fuzzel theme applied"
}

# Apply Ghostty theme
apply_ghostty_theme() {
    local theme_path="$1"
    local ghostty_conf="$theme_path/ghostty"

    if [ ! -f "$ghostty_conf" ]; then
        log_warning "Ghostty theme file not found: $ghostty_conf"
        return 0
    fi

    log_step "Applying Ghostty theme..."

    mkdir -p "$CONFIG_DIR/ghostty"
    cp "$ghostty_conf" "$CONFIG_DIR/ghostty/theme"

    # Ghostty reloads automatically when config changes
    log_success "Ghostty theme applied"
}

# Get current theme
get_current_theme() {
    if [ -L "$CURRENT_THEME_LINK" ]; then
        basename "$(readlink "$CURRENT_THEME_LINK")"
    else
        echo "none"
    fi
}

# Main command handling
case "${1:-}" in
    list)
        list_themes
        ;;
    set)
        set_theme "$2"
        ;;
    current)
        echo "Current theme: $(get_current_theme)"
        ;;
    *)
        cat <<EOF
Theme Manager - Unified theme system for dofs

Usage: $(basename "$0") <command> [args]

Commands:
  list              List available themes
  set <theme>       Set a theme
  current           Show current theme
  
Examples:
  $(basename "$0") list
  $(basename "$0") set default
  $(basename "$0") current

EOF
        ;;
esac
