#!/bin/bash

# Function to check if gammastep is running
is_running() {
    pgrep -x gammastep >/dev/null
}

# Function to toggle gammastep
toggle() {
    if is_running; then
        pkill gammastep
        gammastep -x
    else
        gammastep -l 36.8:10.2 -t 6500:3500 -P &
    fi
}

# Handle command line argument
if [[ "$1" == "toggle" ]]; then
    toggle
    exit 0
fi

# Output status with icon
if is_running; then
    echo "󰛨"  # Icon when gammastep is active
else
    echo "󰹏"  # Icon when gammastep is inactive
fi
