#!/bin/bash
set -euo pipefail

ANIMATIONS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/animations.kdl"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/niri/animations-state"
DEFAULT_SLOWDOWN=0.5

if [ ! -f "$ANIMATIONS_FILE" ]; then
    notify-send "Niri" "Missing animations file: $ANIMATIONS_FILE"
    exit 1
fi

mkdir -p "$(dirname "$STATE_FILE")"

current_slowdown=$(awk '/^[[:space:]]*slowdown[[:space:]]+/ {print $2; exit}' "$ANIMATIONS_FILE")
current_slowdown=${current_slowdown:-$DEFAULT_SLOWDOWN}

if [ "$current_slowdown" = "0" ] || [ "$current_slowdown" = "0.0" ]; then
    next_slowdown=$DEFAULT_SLOWDOWN
    label="on"
else
    next_slowdown=0
    label="off"
fi

awk -v slowdown="$next_slowdown" '
/^[[:space:]]*slowdown[[:space:]]+/ {
    sub(/[0-9.]+/, slowdown)
}
{print}
' "$ANIMATIONS_FILE" >"$ANIMATIONS_FILE.tmp"

mv "$ANIMATIONS_FILE.tmp" "$ANIMATIONS_FILE"

echo "$next_slowdown" >"$STATE_FILE"

niri msg action load-config-file >/dev/null 2>&1 || true

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Niri" "Animations $label"
fi
