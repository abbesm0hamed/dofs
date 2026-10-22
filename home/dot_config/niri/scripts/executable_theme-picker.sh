#!/bin/bash
# Theme picker for the dofs Quickshell launcher (was a rofi dmenu).
# Provider: one JSON item per theme; activation rewrites the live theme.
set -euo pipefail

THEMES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/themes"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/themes"
STATE_FILE="$STATE_DIR/current_theme"
LEGACY_STATE_FILE="$THEMES_DIR/current_theme"

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/menu-lib.sh"

CURRENT_THEME="$(cat "$STATE_FILE" 2>/dev/null || echo "")"
if [ -z "$CURRENT_THEME" ] && [ -f "$LEGACY_STATE_FILE" ]; then
    CURRENT_THEME="$(cat "$LEGACY_STATE_FILE" 2>/dev/null || echo "")"
fi

count=0
if [ -d "$THEMES_DIR" ]; then
    for theme_path in "$THEMES_DIR"/*; do
        if [ -d "$theme_path" ]; then
            name=$(basename "$theme_path")
            count=$((count + 1))
            if [ "$name" == "$CURRENT_THEME" ]; then
                menu_item "$name" "Currently active" "preferences-desktop-display" \
                    -- bash "$HOME/.config/niri/scripts/set-theme.sh" --from-picker "$name"
            else
                menu_item "$name" "Switch to this theme" "preferences-desktop-display" \
                    -- bash "$HOME/.config/niri/scripts/set-theme.sh" --from-picker "$name"
            fi
        fi
    done
fi

[[ $count -gt 0 ]] || { echo "no themes in $THEMES_DIR" >&2; exit 1; }
