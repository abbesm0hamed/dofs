#!/bin/bash

# Configuration Paths
LOG_FILE="/tmp/monitor-setup.log"
BACKGROUNDS_DIR="$HOME/.config/backgrounds"
CONFIG_DIR="$HOME/.config/wallpaper-manager"
CURRENT_CONFIG="$CONFIG_DIR/current_wallpapers.conf"
LOCK_FILE="/tmp/monitor-setup.lock"

# Specific wallpapers for first three monitors (if they exist)
declare -a PRIORITY_WALLPAPERS=(
    "$BACKGROUNDS_DIR/old-war.jpeg"
    "$BACKGROUNDS_DIR/horse-battle.jpg"
    "$BACKGROUNDS_DIR/dragon.jpg"
)

# Ensure required directories exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$BACKGROUNDS_DIR"

# Lock file management
if [ -e "$LOCK_FILE" ]; then
    if kill -0 $(cat "$LOCK_FILE") 2>/dev/null; then
        echo "Another instance is running"
        exit 1
    fi
fi
echo $$ >"$LOCK_FILE"

# Logging function with timestamps
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

# Function to validate image file
is_valid_image() {
    local file="$1"
    file --mime-type "$file" | grep -q "image/"
}

# Function to get a random wallpaper, excluding specific wallpapers
get_random_wallpaper() {
    local exclude=("$@")
    local wallpaper
    local max_attempts=10
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        wallpaper=$(find "$BACKGROUNDS_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n 1)

        # Check if wallpaper is in exclude list
        local excluded=false
        for exc in "${exclude[@]}"; do
            if [ "$wallpaper" = "$exc" ]; then
                excluded=true
                break
            fi
        done

        if [ "$excluded" = false ] && [ -f "$wallpaper" ] && is_valid_image "$wallpaper"; then
            echo "$wallpaper"
            return 0
        fi
        ((attempt++))
    done

    # Fallback to first valid image found if no random selection works
    find "$BACKGROUNDS_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | head -n 1
}

# Function to get all connected monitors
get_connected_monitors() {
    DISPLAY=:0 xrandr --query | grep " connected" | cut -d " " -f1
}

# Function to set wallpapers
set_wallpapers() {
    local monitors=($(get_connected_monitors))
    local num_monitors=${#monitors[@]}
    local feh_args=()
    local used_wallpapers=()
    local wallpaper=""

    log "Detected $num_monitors monitors: ${monitors[*]}"

    # Build feh arguments for each monitor
    for ((i = 0; i < num_monitors; i++)); do
        if [ $i -lt ${#PRIORITY_WALLPAPERS[@]} ] && [ -f "${PRIORITY_WALLPAPERS[$i]}" ]; then
            # Use priority wallpaper for first three monitors if available
            wallpaper="${PRIORITY_WALLPAPERS[$i]}"
            log "Using priority wallpaper for monitor $((i + 1)): $wallpaper"
        else
            # Use random wallpaper for additional monitors
            wallpaper=$(get_random_wallpaper "${used_wallpapers[@]}")
            log "Using random wallpaper for monitor $((i + 1)): $wallpaper"
        fi

        used_wallpapers+=("$wallpaper")
        feh_args+=(--bg-fill "$wallpaper")
    done

    # Set the wallpapers using feh
    if DISPLAY=:0 feh --no-fehbg "${feh_args[@]}"; then
        log "Successfully set wallpapers"

        # Save current configuration
        printf "%s\n" "${used_wallpapers[@]}" >"$CURRENT_CONFIG"
    else
        log "Failed to set wallpapers"
        return 1
    fi
}

# Function to handle display configuration
configure_displays() {
    local monitors=($(get_connected_monitors))
    local primary_monitor="${monitors[0]}"
    local num_monitors=${#monitors[@]}
    local x_position=0

    log "Configuring $num_monitors displays"

    # Configure each monitor
    for monitor in "${monitors[@]}"; do
        # Get preferred resolution and refresh rate
        local preferred_mode=$(DISPLAY=:0 xrandr --query | grep -A1 "^$monitor" | tail -n1 | awk '{print $1}')
        local refresh_rate=$(DISPLAY=:0 xrandr --query | grep -A1 "^$monitor" | tail -n1 | grep -o '[0-9.]\+\*' | tr -d '*')

        if [ "$monitor" = "$primary_monitor" ]; then
            DISPLAY=:0 xrandr --output "$monitor" --primary --mode "$preferred_mode" --pos "${x_position}x0" --rate "$refresh_rate"
            log "Set $monitor as primary at position ${x_position}x0"
        else
            DISPLAY=:0 xrandr --output "$monitor" --mode "$preferred_mode" --pos "${x_position}x0" --rate "$refresh_rate"
            log "Set $monitor at position ${x_position}x0"
        fi

        # Update x_position for next monitor
        x_position=$((x_position + ${preferred_mode%x*}))
    done

    # Turn off disconnected outputs
    DISPLAY=:0 xrandr --query | grep "disconnected" | cut -d " " -f1 | while read -r output; do
        DISPLAY=:0 xrandr --output "$output" --off
        log "Turned off disconnected output: $output"
    done
}

# Function to restart window manager components
restart_components() {
    # Restart polybar if it exists
    if command -v polybar >/dev/null 2>&1; then
        pkill polybar
        sleep 0.5
        if [ -f "$HOME/.config/polybar/launch_polybar.sh" ]; then
            $HOME/.config/polybar/launch_polybar.sh
            log "Restarted polybar"
        fi
    fi
}

# Main execution
main() {
    log "Starting monitor and wallpaper configuration"

    # Wait for X server
    for i in {1..30}; do
        if DISPLAY=:0 xrandr >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
        if [ $i -eq 30 ]; then
            log "Error: X server not ready"
            exit 1
        fi
    done

    configure_displays
    set_wallpapers
    restart_components

    log "Configuration completed successfully"
}

main
