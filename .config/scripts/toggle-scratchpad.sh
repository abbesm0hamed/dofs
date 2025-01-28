#!/bin/bash

instance="$1"
command="$2"

# Check if the window exists
if ! xdotool search --classname "$instance" >/dev/null 2>&1; then
    # If window doesn't exist, create it
    eval "$command" &
    # Wait for window to be created
    sleep 0.5
    # Ensure proper positioning
    i3-msg "[instance=\"$instance\"] move position center"
fi

# Toggle scratchpad visibility and ensure centering
i3-msg "[instance=\"$instance\"] scratchpad show, move position center"