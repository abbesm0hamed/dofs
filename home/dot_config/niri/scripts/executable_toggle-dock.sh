#!/bin/bash

# Toggle script for Crystal Dock

if pgrep -x "crystal-dock" > /dev/null; then
    # If the dock is running, kill it
    pkill -x "crystal-dock"
else
    # If the dock is not running, start it in the background
    crystal-dock & disown
fi
