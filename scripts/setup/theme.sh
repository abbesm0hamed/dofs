#!/bin/bash
set -e

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
CURRENT_THEME_LINK="$HOME/.config/theme-current"
CONFIG_DIR="$HOME/.config"

# Calculate REPO_ROOT if not set
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
REPO_ROOT="${REPO_ROOT:-$(dirname "$(dirname "$SCRIPT_DIR")")}"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}→${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
err() { echo -e "${RED}✗${NC} $1" >&2; }

# --- App Handlers ---

apply_mako() {
    local src="$1/mako.ini"
    if [ -f "$src" ]; then
        cp "$src" "$CONFIG_DIR/mako/config"
        makoctl reload 2>/dev/null || true
        ok "Mako"
    fi
}

apply_ghostty() {
    local src="$1/ghostty"
    if [ -f "$src" ]; then
        cp "$src" "$CONFIG_DIR/ghostty/theme"
        ok "Ghostty"
    fi
}

apply_waybar() {
    if pgrep -x waybar >/dev/null; then
        pkill -x waybar
        waybar &>/dev/null &
        ok "Waybar (reloaded)"
    fi
}

apply_fuzzel() {
    local theme_src="$1/fuzzel.ini"
    local template_src="$REPO_ROOT/templates/fuzzel/fuzzel.ini"
    local target="$CONFIG_DIR/fuzzel/fuzzel.ini"
    
    if [ ! -f "$template_src" ]; then
        err "Fuzzel template not found at $template_src"
        return 1
    fi

    mkdir -p "$(dirname "$target")"
    
    # Copy template to target (removing symlink if it exists)
    rm -f "$target"
    cp "$template_src" "$target"

    if [ -f "$theme_src" ]; then
        # Inject [colors] section from theme into target
        awk -v theme_file="$theme_src" '
            BEGIN {
                while ((getline line < theme_file) > 0) theme[++n] = line
                close(theme_file)
            }
            /^\[colors\]$/ {
                if (!inserted) {
                    for (i=1; i<=n; i++) print theme[i]
                    inserted=1
                }
                in_colors=1
                next
            }
            /^\[.*\]$/ && in_colors { in_colors=0 }
            !in_colors { print }
            END {
                if (!inserted) {
                    print ""
                    for (i=1; i<=n; i++) print theme[i]
                }
            }
        ' "$target" > "${target}.tmp" && mv "${target}.tmp" "$target" && ok "Fuzzel"
    else
        ok "Fuzzel (reset to template)"
    fi
}

apply_kitty() {
    local src="$1/kitty.conf"
    if [ -f "$src" ]; then
        cp "$src" "$CONFIG_DIR/kitty/theme.conf"
        ok "Kitty"
    fi
}

apply_btop() {
    local src="$1/btop.theme"
    local btop_dir="$CONFIG_DIR/btop"
    local theme_name="dofs"
    
    if [ -f "$src" ]; then
        mkdir -p "$btop_dir/themes"
        cp "$src" "$btop_dir/themes/${theme_name}.theme"
        
        # Update config if it exists, or create minimal
        if [ ! -f "$btop_dir/btop.conf" ]; then
            echo "color_theme = \"$theme_name\"" > "$btop_dir/btop.conf"
            echo "theme_background = False" >> "$btop_dir/btop.conf"
            echo "true_color = True" >> "$btop_dir/btop.conf"
        else
            if grep -q "color_theme" "$btop_dir/btop.conf"; then
                 sed -i "s|^color_theme = .*|color_theme = \"$theme_name\"|" "$btop_dir/btop.conf"
            else
                 echo "color_theme = \"$theme_name\"" >> "$btop_dir/btop.conf"
            fi
        fi
        ok "Btop (theme set to $theme_name)"
    fi
}

apply_swaylock() {
    local theme_src="$1/swaylock/theme.conf"
    local target="$CONFIG_DIR/swaylock/theme.conf"
    mkdir -p "$(dirname "$target")"
    if [ -f "$theme_src" ]; then
        rm -f "$target"
        cp "$theme_src" "$target"
        ok "Swaylock"
    fi
}

apply_yazi() {
    local theme_src="$1/yazi/theme.toml"
    local target="$CONFIG_DIR/yazi/theme.toml"
    mkdir -p "$(dirname "$target")"
    if [ -f "$theme_src" ]; then
        rm -f "$target"
        cp "$theme_src" "$target"
        ok "Yazi"
    fi
}

apply_cava() {
    local theme_src="$1/cava/config"
    local template_src="$REPO_ROOT/templates/cava/config"
    local target="$CONFIG_DIR/cava/config"
    
    mkdir -p "$(dirname "$target")"
    if [ ! -f "$template_src" ]; then err "Cava template missing"; return 1; fi
    
    rm -f "$target"
    cp "$template_src" "$target"
    if [ -f "$theme_src" ]; then
        cat "$theme_src" >> "$target"
        ok "Cava"
    else
        ok "Cava (template only)"
    fi
}

apply_lazygit() {
    local theme_src="$1/lazygit/theme.yml"
    local template_src="$REPO_ROOT/templates/lazygit/config.yml"
    local target="$CONFIG_DIR/lazygit/config.yml"
    
    mkdir -p "$(dirname "$target")"
    if [ ! -f "$template_src" ]; then err "Lazygit template missing"; return 1; fi
    
    rm -f "$target"
    if [ -f "$theme_src" ]; then
        awk -v theme_file="$theme_src" '
            BEGIN { while ((getline line < theme_file) > 0) theme[++n] = line }
            /# THEME_INJECTION_POINT/ {
                for (i=1; i<=n; i++) print theme[i]
                next
            }
            { print }
        ' "$template_src" > "$target" && ok "Lazygit"
    else
        cp "$template_src" "$target"
        ok "Lazygit (template only)"
    fi
}

apply_niri() {
    local theme_src="$1/niri/colors.kdl"
    local template_src="$REPO_ROOT/templates/niri/config.kdl"
    local target="$CONFIG_DIR/niri/config.kdl"

    mkdir -p "$(dirname "$target")"
    if [ ! -f "$template_src" ]; then err "Niri template missing"; return 1; fi

    if [ -f "$theme_src" ]; then
        awk -v theme_file="$theme_src" '
            BEGIN { while ((getline line < theme_file) > 0) theme[++n] = line }
            /\/\/ THEME_INJECTION_POINT: niri_colors/ {
                print $0
                for (i=1; i<=n; i++) print theme[i]
                found=1
                next
            }
            found && /active-color|inactive-color|urgent-color/ { next }
            found && !(/active-color|inactive-color|urgent-color/) { found=0 }
            { print }
        ' "$template_src" > "$target" && ok "Niri"
        niri msg action do-reload 2>/dev/null || true
    else
        cp "$template_src" "$target"
        ok "Niri (template only)"
    fi
}

# --- Main Logic ---

set_theme() {
    local name="$1"
    local path="$THEME_DIR/$name"

    [ ! -d "$path" ] && err "Theme not found: $name" && return 1

    log "Applying theme: $name"
    ln -nsf "$path" "$CURRENT_THEME_LINK"
    apply_mako "$path"
    apply_ghostty "$path"
    apply_fuzzel "$path"
    apply_kitty "$path"
    apply_btop "$path"
    apply_swaylock "$path"
    apply_yazi "$path"
    apply_cava "$path"
    apply_lazygit "$path"
    apply_niri "$path"
    apply_waybar
}

case "${1:-}" in
    list) ls -1 "$THEME_DIR" ;;
    set) set_theme "${2:-default}" ;;
    current) [ -L "$CURRENT_THEME_LINK" ] && basename "$(readlink "$CURRENT_THEME_LINK")" || echo "none" ;;
    *) set_theme "default" ;;
esac
