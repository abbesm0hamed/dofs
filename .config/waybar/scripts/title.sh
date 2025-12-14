#!/bin/bash

if ! command -v jq >/dev/null 2>&1 || ! command -v niri >/dev/null 2>&1; then
    echo '{"text":"","tooltip":""}'
    exit 0
fi

window_json=$(niri msg focused-window 2>/dev/null || true)

if [ -z "$window_json" ]; then
    echo '{"text":"","tooltip":""}'
    exit 0
fi

title=$(printf '%s' "$window_json" | jq -r '[.. | .title? | select(type == "string" and length > 0)] | first // empty' 2>/dev/null || true)
app_id=$(printf '%s' "$window_json" | jq -r '[.. | .app_id? | select(type == "string" and length > 0)] | first // empty' 2>/dev/null || true)

if [ -z "$title" ]; then
    title=$(printf '%s' "$window_json" | jq -r '[.. | .name? | select(type == "string" and length > 0)] | first // empty' 2>/dev/null || true)
fi

jq -n --arg text "${title:-}" --arg tooltip "${app_id:-}" '{text: $text, tooltip: $tooltip}'
