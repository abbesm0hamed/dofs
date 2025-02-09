#!/bin/bash

# Configuration
BACKGROUNDS_DIR="$HOME/.config/backgrounds"
CONFIG_DIR="$HOME/.config/wallpaper-manager"
CURRENT_CONFIG="$CONFIG_DIR/current_wallpapers.conf"

# Default wallpapers - add more as needed
declare -a DEFAULT_WALLPAPERS=(
    "$BACKGROUNDS_DIR/unknown.png"
    "$BACKGROUNDS_DIR/html-selfclosed-tag.jpg"
    "$BACKGROUNDS_DIR/ball.jpg"
)

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Kill any existing swaybg instances
pkill swaybg

# Get all connected outputs in order
readarray -t OUTPUTS < <(swaymsg -t get_outputs | jq -r '.[] | select(.active == true) | .name')

# Set wallpapers for each output in order
for i in "${!OUTPUTS[@]}"; do
    # Use the wallpaper at the same index, or wrap around if we run out
    WALLPAPER="${DEFAULT_WALLPAPERS[$i % ${#DEFAULT_WALLPAPERS[@]}]}"
    
    # Verify the wallpaper file exists
    if [ ! -f "$WALLPAPER" ]; then
        echo "Warning: Wallpaper $WALLPAPER not found"
        continue
    fi
    
    # Launch swaybg for this output
    swaybg -o "${OUTPUTS[$i]}" -i "$WALLPAPER" -m fill &
done

# Save current wallpaper configuration
printf "%s\n" "${WALLPAPERS[@]}" > "$CURRENT_CONFIG"
