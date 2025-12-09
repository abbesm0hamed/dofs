#!/usr/bin/env bash

# Theme Manager for dofs
# Manages unified Catppuccin Mocha theme across all components
# Similar to Omarchy's theme system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOFS_DIR="$(dirname "$SCRIPT_DIR")"
THEME_DIR="$DOFS_DIR/.config/theme"
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
        log_error "Theme not found: $theme_name"
        return 1
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
    apply_walker_theme "$theme_path"
    
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
    
    # Create a symlink or copy the niri theme file
    mkdir -p "$CONFIG_DIR/niri"
    cp "$niri_conf" "$CONFIG_DIR/niri/theme.conf"
    
    # Reload Niri if running
    if command -v niri >/dev/null && pgrep -x niri >/dev/null; then
        niri msg action reload-config 2>/dev/null || true
        log_success "Niri reloaded"
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
    cp "$waybar_css" "$CONFIG_DIR/waybar/theme.css"
    
    # Reload Waybar
    if command -v waybar >/dev/null; then
        pkill -f waybar || true
        sleep 0.5
        waybar &
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
        makoctl reload
        log_success "Mako reloaded"
    fi
}

# Apply Walker theme
apply_walker_theme() {
    local theme_path="$1"
    local walker_toml="$theme_path/walker.toml"
    
    if [ ! -f "$walker_toml" ]; then
        log_warning "Walker theme file not found: $walker_toml"
        return 0
    fi
    
    log_step "Applying Walker theme..."
    
    mkdir -p "$CONFIG_DIR/walker"
    cp "$walker_toml" "$CONFIG_DIR/walker/theme.toml"
    
    log_success "Walker theme applied"
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
        cat << EOF
Theme Manager - Unified theme system for dofs

Usage: $(basename "$0") <command> [args]

Commands:
  list              List available themes
  set <theme>       Set a theme
  current           Show current theme
  
Examples:
  $(basename "$0") list
  $(basename "$0") set catppuccin-mocha
  $(basename "$0") current

EOF
        ;;
esac
