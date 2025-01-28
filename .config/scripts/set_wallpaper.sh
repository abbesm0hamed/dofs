#!/bin/bash

BACKGROUND_PRIMARY="$HOME/.config/backgrounds/old-war.jpeg"
BACKGROUND_SECONDARY="$HOME/.config/backgrounds/horse-war.jpg"
VARIETY_CONFIG="$HOME/.config/variety"

# Function to check if the second monitor is connected
function is_second_monitor_connected {
    xrandr | grep "HDMI-1-0 connected" >/dev/null
}

# Function to get a random wallpaper
function get_random_wallpaper {
    find "$HOME/.config/backgrounds" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1
}

# Check if Variety is running and has a wallpaper set
if pgrep -x "variety" >/dev/null && [ -f "$VARIETY_CONFIG/wallpaper/wallpaper.jpg.txt" ]; then
    # Variety is running and has set a wallpaper, let it handle things
    exit 0
else
    # Either Variety isn't running or hasn't set a wallpaper yet
    if command -v variety >/dev/null 2>&1; then
        # Create Variety config directory if it doesn't exist
        mkdir -p "$VARIETY_CONFIG"

        # Set initial wallpaper with feh
        if is_second_monitor_connected; then
            feh --no-fehbg --bg-fill "$BACKGROUND_PRIMARY" --bg-fill "$BACKGROUND_SECONDARY"
        else
            feh --no-fehbg --bg-fill "$BACKGROUND_PRIMARY"
        fi

        # Start Variety if it's not running
        if ! pgrep -x "variety" >/dev/null; then
            variety --profile "$VARIETY_CONFIG" --set "$BACKGROUND_PRIMARY" &
            sleep 2
            variety --profile "$VARIETY_CONFIG" --add "$HOME/.config/backgrounds" &
        fi
    else
        # Fallback to feh if Variety is not installed
        if is_second_monitor_connected; then
            if [ -f "$BACKGROUND_PRIMARY" ] && [ -f "$BACKGROUND_SECONDARY" ]; then
                feh --no-fehbg --bg-fill "$BACKGROUND_PRIMARY" --bg-fill "$BACKGROUND_SECONDARY"
            else
                feh --no-fehbg --bg-fill "$(get_random_wallpaper)" --bg-fill "$(get_random_wallpaper)"
            fi
        else
            if [ -f "$BACKGROUND_PRIMARY" ]; then
                feh --no-fehbg --bg-fill "$BACKGROUND_PRIMARY"
            else
                feh --no-fehbg --bg-fill "$(get_random_wallpaper)"
            fi
        fi
    fi
fi
