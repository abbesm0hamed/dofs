#!/bin/bash
SCRATCHPAD_NAME="$1"
COMMAND="$2"

if [ -z "$SCRATCHPAD_NAME" ] || [ -z "$COMMAND" ]; then
  echo "Usage: $0 <scratchpad_name> <command>"
  exit 1
fi

# Check if the scratchpad window exists
if hyprctl clients | grep -q "class: $SCRATCHPAD_NAME"; then
  # Window exists, check if it's visible
  if hyprctl clients | grep -A5 "class: $SCRATCHPAD_NAME" | grep -q "workspace: special"; then
    # Window is in special workspace (hidden), show it
    hyprctl dispatch togglespecialworkspace "$SCRATCHPAD_NAME"
  else
    # Window is visible, move to special workspace
    hyprctl dispatch movetoworkspacesilent "special:$SCRATCHPAD_NAME,class:$SCRATCHPAD_NAME"
  fi
else
  # Window doesn't exist, create it
  eval "$COMMAND" &
  sleep 0.5
  hyprctl dispatch movetoworkspacesilent "special:$SCRATCHPAD_NAME,class:$SCRATCHPAD_NAME"
fi

