#!/bin/bash
#
# theme-switcher.sh: A script to switch themes using fuzzel.
#

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
THEME_SCRIPT="${REPO_ROOT:-$HOME/dofs}/scripts/setup/theme.sh"

# Check if the theme directory exists
if [ ! -d "$THEME_DIR" ]; then
    notify-send -u critical "Theme Switcher" "Theme directory not found at $THEME_DIR"
    exit 1
fi

# Get the list of themes and let the user choose with fuzzel
CHOSEN_THEME=$(ls "$THEME_DIR" | fuzzel --dmenu --prompt '󰸘 Theme: ')

# If a theme was chosen, apply it
if [ -n "$CHOSEN_THEME" ]; then
    # Call the main theme script to apply the chosen theme
    if [ -x "$THEME_SCRIPT" ]; then
        bash "$THEME_SCRIPT" set "$CHOSEN_THEME"
        notify-send "Theme Switcher" "Applied theme: $CHOSEN_THEME"
    else
        notify-send -u critical "Theme Switcher" "Theme script not found or not executable."
    fi
fi
