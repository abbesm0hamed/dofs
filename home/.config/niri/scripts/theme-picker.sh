#!/bin/bash
set -euo pipefail

THEMES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/themes"
CURRENT_THEME=$(cat "$THEMES_DIR/current_theme" 2>/dev/null || echo "")

themes=()
if [ -d "$THEMES_DIR" ]; then
    for theme_path in "$THEMES_DIR"/*; do
        if [ -d "$theme_path" ]; then
            name=$(basename "$theme_path")
            if [ "$name" == "$CURRENT_THEME" ]; then
                themes+=("✓ $name")
            else
                themes+=("  $name")
            fi
        fi
    done
fi

# Show rofi menu
choice=$(printf "%s\n" "${themes[@]}" | rofi -dmenu -i -p "󰄹 Theme: ")

if [ -n "$choice" ]; then
    # Use fixed offset to strip the 2-character prefix ("✓ " or "  ")
    theme_to_set="${choice:2}"
    bash "$HOME/.config/niri/scripts/set-theme.sh" --from-picker "$theme_to_set"
fi
