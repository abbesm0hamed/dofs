#!/bin/bash

# Simple wrapper to launch an app and kill it when it loses focus in Niri
# Usage: floating-wrapper.sh <app_id> <command...>

APP_ID=$1
shift
COMMAND=$@

# Launch the app in foot with a specific app-id
foot --app-id="$APP_ID" "$COMMAND" &
LAUNCH_PID=$!

# Wait for the window to appear and get focus
# Foot is very fast, so 0.2s might be enough, but let's stick to 0.4s to be safe
sleep 0.4

# Monitor Niri event stream for focus changes
niri msg -j event-stream | while read -r line; do
    # Check if a window-focus-changed event occurred
    if echo "$line" | jq -e 'has("FocusChanged")' >/dev/null; then
        # Get the new focused window app_id
        FOCUSED_ID=$(niri msg -j focused-window | jq -r '.app_id // empty')
        
        # If the focused ID is NOT our app, and is NOT empty (meaning focus moved away)
        if [ "$FOCUSED_ID" != "$APP_ID" ] && [ -n "$FOCUSED_ID" ]; then
            # kill the launched terminal via pkill using the app-id
            pkill -f "foot --app-id=$APP_ID"
            exit 0
        fi
    fi
done
