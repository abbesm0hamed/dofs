#!/bin/bash
set -euo pipefail

LAYOUT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/layout.kdl"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/niri/gaps-state"
DEFAULT_GAPS=0

if [ ! -f "$LAYOUT_FILE" ]; then
    notify-send "Niri" "Missing layout file: $LAYOUT_FILE"
    exit 1
fi

mkdir -p "$(dirname "$STATE_FILE")"

current_gaps=$(awk '/^[[:space:]]*gaps[[:space:]]+/ {print $2; exit}' "$LAYOUT_FILE")
current_gaps=${current_gaps:-$DEFAULT_GAPS}

if [ "$current_gaps" = "0" ]; then
    next_gaps=8
else
    next_gaps=0
fi

awk -v gaps="$next_gaps" '
/^[[:space:]]*gaps[[:space:]]+/ {
    sub(/[0-9.]+/, gaps)
}
{print}
' "$LAYOUT_FILE" >"$LAYOUT_FILE.tmp"

mv "$LAYOUT_FILE.tmp" "$LAYOUT_FILE"

echo "$next_gaps" >"$STATE_FILE"

niri msg action load-config-file >/dev/null 2>&1 || true

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Niri" "Gaps set to $next_gaps"
fi
