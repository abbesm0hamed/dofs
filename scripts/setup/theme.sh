#!/bin/bash
set -e

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
CURRENT_THEME_LINK="$HOME/.config/theme-current"
CONFIG_DIR="$HOME/.config"

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
    killall -q waybar || true
    for i in {1..10}; do
        if ! pgrep -x waybar >/dev/null; then break; fi
        sleep 0.1
    done
    niri msg action spawn -- waybar
    ok "Waybar"
}

apply_fuzzel() {
    local theme_src="$1/fuzzel.ini"
    local target="$CONFIG_DIR/fuzzel/fuzzel.ini"
    
    if [ ! -f "$target" ]; then return 0; fi

    if [ -f "$theme_src" ]; then
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
        ok "Btop"
    fi
}

apply_swaylock() {
    local theme_src="$1/swaylock/theme.conf"
    local target="$CONFIG_DIR/swaylock/theme.conf"
    if [ -f "$theme_src" ]; then
        cp "$theme_src" "$target"
        ok "Swaylock"
    fi
}

apply_yazi() {
    local theme_src="$1/yazi/theme.toml"
    local target="$CONFIG_DIR/yazi/theme.toml"
    if [ -f "$theme_src" ]; then
        cp "$theme_src" "$target"
        ok "Yazi"
    fi
}

apply_cava() {
    local theme_src="$1/cava/config"
    local target="$CONFIG_DIR/cava/config"
    
    if grep -q "# THEME_INJECTION_POINT" "$target" 2>/dev/null; then
        awk -v theme_file="$theme_src" '
            BEGIN { while ((getline line < theme_file) > 0) theme[++n] = line }
            /# THEME_INJECTION_POINT/ {
                print $0
                for (i=1; i<=n; i++) print theme[i]
                skipping=1
                next
            }
            skipping && /^\[/ { skipping=0 }
            !skipping { print }
        ' "$target" > "${target}.tmp" && mv "${target}.tmp" "$target" && ok "Cava"
    else
        if [ -f "$theme_src" ]; then
            cat "$theme_src" >> "$target"
            ok "Cava (appended)"
        fi
    fi
}

apply_lazygit() {
    local theme_src="$1/lazygit/theme.yml"
    local target="$CONFIG_DIR/lazygit/config.yml"
    
    if grep -q "# THEME_INJECTION_POINT" "$target" 2>/dev/null; then
        awk -v theme_file="$theme_src" '
            BEGIN { while ((getline line < theme_file) > 0) theme[++n] = line }
            /# THEME_INJECTION_POINT/ {
                print $0
                for (i=1; i<=n; i++) print theme[i]
                skipping=1
                next
            }
            skipping && /^[a-zA-Z]/ && !/^theme:/ { skipping=0 }
            !skipping { print }
        ' "$target" > "${target}.tmp" && mv "${target}.tmp" "$target" && ok "Lazygit"
    else
        ok "Lazygit (no marker)"
    fi
}

apply_foot() {
    local theme_src="$1/foot/colors.ini"
    local target="$CONFIG_DIR/foot/foot.ini"
    
    if [ ! -f "$target" ]; then return 0; fi

    if [ -f "$theme_src" ]; then
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
        ' "$target" > "${target}.tmp" && mv "${target}.tmp" "$target" && ok "Foot"
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
    apply_foot "$path"
    apply_waybar
}

case "${1:-}" in
    list) ls -1 "$THEME_DIR" ;;
    set) set_theme "${2:-default}" ;;
    current) [ -L "$CURRENT_THEME_LINK" ] && basename "$(readlink "$CURRENT_THEME_LINK")" || echo "none" ;;
    *) set_theme "default" ;;
esac
