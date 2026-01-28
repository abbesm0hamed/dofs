#!/bin/bash
set -euo pipefail

THEMES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/themes"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/themes"
STATE_FILE="$STATE_DIR/current_theme"
LEGACY_STATE_FILE="$THEMES_DIR/current_theme"

CURRENT_THEME="$(cat "$STATE_FILE" 2>/dev/null || echo "")"
if [ -z "$CURRENT_THEME" ] && [ -f "$LEGACY_STATE_FILE" ]; then
    CURRENT_THEME="$(cat "$LEGACY_STATE_FILE" 2>/dev/null || echo "")"
fi

if ! command -v rofi >/dev/null 2>&1; then
    msg="rofi not found; install it to pick themes."
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Theme" "$msg"
    fi
    echo "$msg"
    exit 1
fi

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
