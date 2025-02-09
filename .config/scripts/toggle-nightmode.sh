#!/bin/bash

# Check if wlsunset is running
if pgrep -x "wlsunset" > /dev/null; then
    # If running, kill it to disable night mode
    killall wlsunset
else
    # If not running, start it with mild temperature adjustment
    # Using a milder temperature of 5000K (slightly warmer) instead of 4500K
    wlsunset -t 5000 -T 6500
fi
