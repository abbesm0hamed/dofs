#!/bin/bash

# Configuration
BACKGROUNDS_DIR="$HOME/.config/backgrounds"
CONFIG_DIR="$HOME/.config/wallpaper-manager"
CURRENT_CONFIG="$CONFIG_DIR/current_wallpapers.conf"

# Default wallpapers - add more as needed
declare -a DEFAULT_WALLPAPERS=(
    "$BACKGROUNDS_DIR/spider-man.jpg"
    "$BACKGROUNDS_DIR/ball.jpg"
    "$BACKGROUNDS_DIR/horse-battle.jpg"
    "$BACKGROUNDS_DIR/dash-for-the-timber.jpeg"
)

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Kill any existing swaybg instances more efficiently
pkill -x swaybg

# Get all connected outputs in order (more efficient jq query)
readarray -t OUTPUTS < <(swaymsg -t get_outputs | jq -r '.[] | select(.active == true) | .name')

# Launch all swaybg instances in parallel
for i in "${!OUTPUTS[@]}"; do
    WALLPAPER="${DEFAULT_WALLPAPERS[$i % ${#DEFAULT_WALLPAPERS[@]}]}"
    [ -f "$WALLPAPER" ] && swaybg -o "${OUTPUTS[$i]}" -i "$WALLPAPER" -m fill &
done

# Save current wallpaper configuration
printf "%s\n" "${WALLPAPERS[@]}" > "$CURRENT_CONFIG" &
