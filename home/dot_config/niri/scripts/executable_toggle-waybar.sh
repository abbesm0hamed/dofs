#!/bin/bash

if pgrep -x "waybar" > /dev/null; then
    if pkill -SIGUSR1 -x "waybar" 2>/dev/null; then
        exit 0
    fi

    pkill -x "waybar"
    exit 0
fi

STATE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.current-variant"
SWITCHER="$HOME/.config/niri/scripts/waybar-switcher.sh"

if [ -x "$SWITCHER" ]; then
    variant="$(cat "$STATE_FILE" 2>/dev/null || echo "default")"
    "$SWITCHER" "$variant" &
    disown
    exit 0
fi

waybar & disown
