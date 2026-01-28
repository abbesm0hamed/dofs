#!/bin/bash

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

if ! command -v waybar >/dev/null 2>&1; then
    command -v notify-send >/dev/null 2>&1 && notify-send "Waybar" "waybar not found in PATH"
    exit 1
fi

if pgrep -x "waybar" > /dev/null; then
    if pkill -SIGUSR1 -x "waybar" 2>/dev/null; then
        exit 0
    fi

    pkill -x "waybar" >/dev/null 2>&1 || true
    sleep 0.2
fi

STATE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.current-variant"
SWITCHER="$HOME/.config/niri/scripts/waybar-switcher.sh"

if [ -x "$SWITCHER" ]; then
    variant="$(cat "$STATE_FILE" 2>/dev/null || echo "default")"
    "$SWITCHER" "$variant" &
    disown
    sleep 0.2
    if pgrep -x "waybar" >/dev/null 2>&1; then
        exit 0
    fi
fi

waybar & disown
