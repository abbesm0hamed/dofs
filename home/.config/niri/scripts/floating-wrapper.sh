#!/bin/bash

# Wrapper to launch a terminal app that is killed when it loses focus in Niri.
# Usage: floating-wrapper.sh <terminal> <app_id> [command...]

set -euo pipefail

LOG_FILE="/tmp/floating-wrapper.log"

echo "--- Wrapper started at $(date) ---" >> "$LOG_FILE"
echo "Args: $*" >> "$LOG_FILE"

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <terminal> <app_id> [command...]" >> "$LOG_FILE"
    exit 1
fi

TERMINAL=$1
APP_ID=$2
shift 2
COMMAND=("$@")

echo "Terminal: $TERMINAL" >> "$LOG_FILE"
echo "App ID: $APP_ID" >> "$LOG_FILE"
echo "Command: ${COMMAND[*]}" >> "$LOG_FILE"

LAUNCH_CMD=()
PKILL_PATTERN=""

case "$TERMINAL" in
    kitty)
        LAUNCH_CMD=("kitty" "--class=$APP_ID" "${COMMAND[@]}")
        PKILL_PATTERN="kitty --class=$APP_ID"
        ;;
    ghostty)
        # Ghostty uses 'class' for Wayland app-id
        LAUNCH_CMD=("ghostty" "--class=$APP_ID" "${COMMAND[@]}")
        PKILL_PATTERN="ghostty --class=$APP_ID"
        ;;
    *)
        echo "Unsupported terminal: $TERMINAL" >> "$LOG_FILE"
        exit 1
        ;;
esac

echo "Launch command: ${LAUNCH_CMD[*]}" >> "$LOG_FILE"

# Launch the app
"${LAUNCH_CMD[@]}" &>> "$LOG_FILE" &

# Wait for the window to appear and get focus
sleep 0.2

echo "Monitoring focus changes..." >> "$LOG_FILE"

# Monitor Niri event stream for focus changes
niri msg -j event-stream | while read -r line; do
    if echo "$line" | jq -e 'has("FocusChanged")' >/dev/null; then
        FOCUSED_ID=$(niri msg -j focused-window | jq -r '.app_id // empty')
        echo "Focus changed to: $FOCUSED_ID" >> "$LOG_FILE"
        
        if [ "$FOCUSED_ID" != "$APP_ID" ] && [ -n "$FOCUSED_ID" ]; then
            echo "Focus lost. Killing pattern: $PKILL_PATTERN" >> "$LOG_FILE"
            pkill -f "$PKILL_PATTERN" || true
            echo "--- Wrapper finished ---" >> "$LOG_FILE"
            exit 0
        fi
    fi
done
