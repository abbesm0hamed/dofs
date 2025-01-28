#!/bin/bash

# Configuration
LOG_FILE="/tmp/monitor-setup.log"
INTERNAL_DISPLAY="eDP-1"
declare -a POSSIBLE_EXTERNAL_DISPLAYS=("HDMI-1-0" "DP-1" "HDMI-1" "DP-1-0" "HDMI-2")
PRIMARY_RESOLUTION="1920x1080"
PRIMARY_REFRESH="170"
MAX_RETRIES=3
RETRY_DELAY=1

# Ensure script isn't running multiple times simultaneously
LOCK_FILE="/tmp/monitor-setup.lock"
if [ -e "$LOCK_FILE" ]; then
    if kill -0 $(cat "$LOCK_FILE") 2>/dev/null; then
        echo "Another instance is running. Exiting."
        exit 1
    fi
fi
echo $$ >"$LOCK_FILE"

# Logging function with timestamps and log rotation
log() {
    local max_size=$((1024 * 1024)) # 1MB
    if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE") -gt $max_size ]; then
        mv "$LOG_FILE" "$LOG_FILE.old"
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Enhanced error handling with debugging information
handle_error() {
    local exit_code=$?
    local command=$1
    if [ $exit_code -ne 0 ]; then
        log "Error executing: $command (Exit code: $exit_code)"
        log "Debug info: $(DISPLAY=:0 xrandr --verbose 2>&1)"
        return 1
    fi
    return 0
}

# Cleanup function
cleanup() {
    log "Cleaning up..."
    DISPLAY=:0 xrandr --auto
    rm -f "$LOCK_FILE"
    log "Cleanup completed"
}
trap cleanup EXIT INT TERM

# Function to ensure X server is ready
wait_for_x() {
    local timeout=30
    local interval=0.1
    local elapsed=0

    while [ $(echo "$elapsed < $timeout" | bc) -eq 1 ]; do
        if DISPLAY=:0 XAUTHORITY="$HOME/.Xauthority" xrandr >/dev/null 2>&1; then
            log "X server is ready"
            return 0
        fi
        sleep $interval
        elapsed=$(echo "$elapsed + $interval" | bc)
    done

    log "Error: X server not ready after ${timeout}s"
    return 1
}

# Function to detect all connected displays
detect_displays() {
    local connected_displays=()
    local xrandr_output
    xrandr_output=$(DISPLAY=:0 xrandr --query)

    # Always check internal display
    if [[ "$xrandr_output" == *"$INTERNAL_DISPLAY connected"* ]]; then
        connected_displays+=("$INTERNAL_DISPLAY")
    fi

    # Check all possible external displays
    for display in "${POSSIBLE_EXTERNAL_DISPLAYS[@]}"; do
        if [[ "$xrandr_output" == *"$display connected"* ]]; then
            connected_displays+=("$display")
        fi
    done

    echo "${connected_displays[@]}"
}

# Function to get optimal display settings
get_display_settings() {
    local display=$1
    local info
    info=$(DISPLAY=:0 xrandr --query | grep -A1 "^$display")

    # Extract best mode and refresh rate
    local best_mode
    local best_rate
    best_mode=$(echo "$info" | grep -oP '\d+x\d+' | head -1)
    best_rate=$(echo "$info" | grep -oP '\d+\.\d+(?=\*)|\d+(?=\*)' | head -1)

    if [ -z "$best_mode" ]; then
        best_mode="$PRIMARY_RESOLUTION"
    fi
    if [ -z "$best_rate" ]; then
        best_rate="$PRIMARY_REFRESH"
    fi

    echo "$best_mode:$best_rate"
}

# Calculate display positions function
calculate_display_positions() {
    local -a displays=("$@")
    local position_x=0
    local position_y=0
    local layout=""
    local max_width=3840
    local current_row_height=0

    for display in "${displays[@]}"; do
        local settings
        settings=$(get_display_settings "$display")
        local resolution
        local refresh
        resolution=$(echo "$settings" | cut -d: -f1)
        refresh=$(echo "$settings" | cut -d: -f2)
        local width
        local height
        width=${resolution%x*}
        height=${resolution#*x}

        if ((position_x + width > max_width)) && ((position_x > 0)); then
            position_x=0
            position_y=$((position_y + current_row_height))
            current_row_height=0
        fi

        layout+="--output $display --mode $resolution --rate $refresh --pos ${position_x}x${position_y} "

        position_x=$((position_x + width))
        if ((height > current_row_height)); then
            current_row_height=$height
        fi
    done

    echo "$layout"
}

# Workspace management function
manage_workspaces() {
    local -a displays=("$@")
    local num_displays=${#displays[@]}
    local current_workspace
    current_workspace=$(DISPLAY=:0 i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' -r)

    # Set primary display
    DISPLAY=:0 xrandr --output "${displays[0]}" --primary

    # Handle workspace distribution based on number of displays
    if [ "$num_displays" -le 3 ]; then
        local workspaces_per_display=$((10 / num_displays))
        local workspace=1

        for display in "${displays[@]}"; do
            local end_workspace=$((workspace + workspaces_per_display - 1))
            for ((ws = workspace; ws <= end_workspace; ws++)); do
                DISPLAY=:0 i3-msg "workspace $ws; move workspace to output $display"
                sleep 0.1
            done
            workspace=$((end_workspace + 1))
        done
    else
        local display_index=0
        for display in "${displays[@]}"; do
            case $display_index in
            0)
                for ws in {1..3}; do
                    DISPLAY=:0 i3-msg "workspace $ws; move workspace to output $display"
                done
                ;;
            1)
                for ws in {4..6}; do
                    DISPLAY=:0 i3-msg "workspace $ws; move workspace to output $display"
                done
                ;;
            2)
                for ws in {7..8}; do
                    DISPLAY=:0 i3-msg "workspace $ws; move workspace to output $display"
                done
                ;;
            *)
                for ws in {9..10}; do
                    DISPLAY=:0 i3-msg "workspace $ws; move workspace to output $display"
                done
                ;;
            esac
            display_index=$((display_index + 1))
            sleep 0.1
        done
    fi

    # Return to original workspace or fallback to workspace 1
    if ! DISPLAY=:0 i3-msg "workspace $current_workspace"; then
        DISPLAY=:0 i3-msg "workspace 1"
    fi
}

# Function to restart UI elements
restart_ui() {
    pkill polybar
    sleep 2

    if ! "$HOME/.config/polybar/launch_polybar.sh"; then
        log "Failed to launch polybar, retrying..."
        sleep 1
        if ! "$HOME/.config/polybar/launch_polybar.sh"; then
            log "Failed to launch polybar after retry"
        fi
    fi

    DISPLAY=:0 i3-msg restart
}

# Main execution
main() {
    log "Starting monitor configuration"

    if ! wait_for_x; then
        log "Error: X server not ready"
        exit 1
    fi

    local connected_displays
    connected_displays=($(detect_displays))
    log "Detected displays: ${connected_displays[*]}"

    if [ ${#connected_displays[@]} -eq 0 ]; then
        log "No displays detected!"
        exit 1
    fi

    local layout
    layout=$(calculate_display_positions "${connected_displays[@]}")
    log "Applying layout: $layout"

    local retry_count=0
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if DISPLAY=:0 xrandr $layout; then
            break
        fi
        retry_count=$((retry_count + 1))
        log "Failed to apply layout (attempt $retry_count/$MAX_RETRIES)"
        sleep $RETRY_DELAY
    done

    manage_workspaces "${connected_displays[@]}"
    restart_ui

    log "Monitor configuration completed successfully"
}

main

