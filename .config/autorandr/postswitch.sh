#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="/home/abbes/dofs/.config/backgrounds"

# Get current hour (24-hour format)
hour=$(date +%H)

# Define time periods
is_morning() { [ $hour -ge 6 ] && [ $hour -lt 12 ]; }
is_afternoon() { [ $hour -ge 12 ] && [ $hour -lt 18 ]; }
is_evening() { [ $hour -ge 18 ] && [ $hour -lt 22 ]; }
is_night() { [ $hour -ge 22 ] || [ $hour -lt 6 ]; }

# Function to get a themed wallpaper
get_themed_wallpaper() {
    local theme="$1"
    case $theme in
        "morning")
            # Bright, nature-themed wallpapers
            find "$WALLPAPER_DIR" -type f \( -name "*sky*.jpg" -o -name "*sky*.png" -o -name "bird.jpg" -o -name "earth.jpg" \) | shuf -n 1
            ;;
        "afternoon")
            # Vibrant wallpapers
            find "$WALLPAPER_DIR" -type f \( -name "*kanagawa*.png" -o -name "dragon.jpg" -o -name "sphere.jpg" \) | shuf -n 1
            ;;
        "evening")
            # Warm-toned wallpapers
            find "$WALLPAPER_DIR" -type f \( -name "*battle*.jpg" -o -name "*knights*.jpg" -o -name "*war*.jpg" \) | shuf -n 1
            ;;
        "night")
            # Dark, calm wallpapers
            find "$WALLPAPER_DIR" -type f \( -name "owl.jpg" -o -name "*cat*.jpg" -o -name "vanilla.jpg" \) | shuf -n 1
            ;;
        *)
            # Fallback: any wallpaper
            find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n 1
            ;;
    esac
}

# Get current time period
if is_morning; then
    time_period="morning"
elif is_afternoon; then
    time_period="afternoon"
elif is_evening; then
    time_period="evening"
else
    time_period="night"
fi

# Get list of connected monitors
connected_monitors=$(xrandr --query | grep " connected" | cut -d " " -f1)

# Build the feh command
feh_command="feh --no-fehbg --bg-fill"

# Get primary monitor
primary_monitor=$(xrandr --query | grep "primary" | cut -d " " -f1)

# Assign wallpapers based on monitor and time
for monitor in $connected_monitors; do
    if [ "$monitor" = "$primary_monitor" ]; then
        # Primary monitor gets a time-appropriate wallpaper
        wallpaper=$(get_themed_wallpaper "$time_period")
    else
        # Secondary monitors get random wallpapers from the current theme
        wallpaper=$(get_themed_wallpaper "$time_period")
    fi
    feh_command="$feh_command $wallpaper"
done

# Set the wallpapers
$feh_command

# Save current monitor configuration
autorandr --save default

# Notify awesome to update its configuration
awesome-client 'awesome.restart()'

# Log the change
echo "[$(date)] Monitor configuration changed. Connected monitors: $connected_monitors" >> "$HOME/.config/autorandr/monitor.log"
