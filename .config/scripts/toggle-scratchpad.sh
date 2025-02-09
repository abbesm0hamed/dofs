#!/bin/bash

instance="$1"
command="$2"

# Check if the window exists
if ! swaymsg -t get_tree | jq -r '.. | select(.app_id? == "'"$instance"'") | .app_id' | grep -q .; then
    # If window doesn't exist, create it
    eval "$command" &
    # Wait for window to be created
    sleep 0.5
    # Ensure proper positioning
    swaymsg "[app_id=\"$instance\"] move position center"
fi

# Toggle scratchpad visibility and ensure centering
swaymsg "[app_id=\"$instance\"] scratchpad show, move position center"