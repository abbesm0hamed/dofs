#!/bin/bash

instance="$1"
command="$2"

# Check if window exists and is not visible
if ! swaymsg -t get_tree | jq -r ".. | select(.app_id? == \"$instance\" and .visible == true) | .app_id" | grep -q .; then
    # Check if window exists in scratchpad
    if swaymsg -t get_tree | jq -r ".. | select(.app_id? == \"$instance\") | .app_id" | grep -q .; then
        # Window exists but is hidden, show it
        swaymsg "[app_id=\"$instance\"] scratchpad show, move position center"
    else
        # Create new window
        eval "$command" &
        sleep 0.5
        # Move to scratchpad and show
        swaymsg "[app_id=\"$instance\"] move scratchpad"
        sleep 0.1
        swaymsg "[app_id=\"$instance\"] scratchpad show, move position center"
    fi
else
    # Window is visible, move it to scratchpad
    swaymsg "[app_id=\"$instance\"] move scratchpad"
fi