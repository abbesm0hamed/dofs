#!/bin/bash

# Get the current user
USER_NAME=$(whoami)
USER_HOME=$(getent passwd $USER_NAME | cut -d: -f6)

# Export display for the script to work
export DISPLAY=:0
export XAUTHORITY="$USER_HOME/.Xauthority"

# Sleep for a moment to ensure the display is ready
sleep 1

# Run the display setup script
"$USER_HOME/.config/scripts/setup_displays.sh"

# Restart polybar to ensure it appears on the correct monitors
"$USER_HOME/.config/polybar/launch_polybar.sh"

# Reset wallpaper
"$USER_HOME/.config/scripts/set_wallpaper.sh"
