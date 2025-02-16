#!/bin/bash

# Configuration
BACKGROUNDS_DIR="$HOME/.config/backgrounds"

# Get all connected outputs
readarray -t OUTPUTS < <(swaymsg -t get_outputs | jq -r '.[] | select(.active == true) | .name')

# Skip the first three outputs (already configured in sway config)
for i in "${!OUTPUTS[@]:3}"; do
    # Select a random wallpaper
    WALLPAPER=$(find "$BACKGROUNDS_DIR" -type f | shuf -n 1)
    [ -f "$WALLPAPER" ] && swaymsg output "${OUTPUTS[$i]}" bg "$WALLPAPER" fill
done 