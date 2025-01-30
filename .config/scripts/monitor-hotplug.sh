#!/bin/bash

# Configuration
LOG_FILE="/tmp/monitor-setup.log"
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

# Logging function with timestamps
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Enhanced error handling
handle_error() {
    local exit_code=$?
    local command=$1
    if [ $exit_code -ne 0 ]; then
        log "Error executing: $command (Exit code: $exit_code)"
        return 1
    fi
    return 0
}

# Function to cleanup lock file
cleanup() {
    rm -f "$LOCK_FILE"
    log "Cleanup completed"
}
trap cleanup EXIT

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

# Function to get internal display
get_internal_display() {
    # Try to identify internal display - usually contains eDP or LVDS
    DISPLAY=:0 xrandr --query | grep -E "^(eDP|LVDS)[-0-9]*" | cut -d" " -f1 | head -n 1
}

# Function to get external displays
get_external_displays() {
    # Get all connected displays except internal ones
    DISPLAY=:0 xrandr --query | grep " connected" | grep -vE "^(eDP|LVDS)[-0-9]*" | cut -d" " -f1
}

# Function to get display information
get_display_info() {
    local display=$1
    local info=$(DISPLAY=:0 xrandr --query | grep "^$display")
    echo "$info"
}

# Function to detect displays and their capabilities
detect_displays() {
    local internal_display=$(get_internal_display)
    local external_displays=$(get_external_displays)

    if [ -n "$external_displays" ]; then
        # Get first external display and its best mode
        local primary_external=$(echo "$external_displays" | head -n 1)
        local external_info=$(get_display_info "$primary_external")

        # Get best available mode for external display
        local best_mode=$(echo "$external_info" | grep -oP '\d+x\d+' | head -1)
        local best_rate=$(echo "$external_info" | grep -oP '\d+\.\d+(?=\*)|\d+(?=\*)' | head -1)

        if [ ! -z "$best_mode" ] && [ ! -z "$best_rate" ]; then
            echo "external:$primary_external:$best_mode:$best_rate:$internal_display"
        else
            echo "external:$primary_external:$PRIMARY_RESOLUTION:$PRIMARY_REFRESH:$internal_display"
        fi
    else
        echo "internal:$internal_display"
    fi
}

# Function to get current primary display
get_current_primary() {
    DISPLAY=:0 xrandr | grep "primary" | cut -d" " -f1
}

# Function to handle workspace and window management
manage_workspaces() {
    local target_output=$1
    local current_primary=$(get_current_primary)
    local retry_count=0

    if [ "$current_primary" != "$target_output" ]; then
        log "Changing primary display from $current_primary to $target_output"

        # Get current workspace and focused window
        local current_workspace=$(DISPLAY=:0 i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' -r)
        local focused_window=$(DISPLAY=:0 i3-msg -t get_tree | jq '.. | select(.focused? == true).id')

        # Set new primary display with retry mechanism
        while [ $retry_count -lt $MAX_RETRIES ]; do
            if DISPLAY=:0 xrandr --output "$target_output" --primary; then
                break
            fi
            retry_count=$((retry_count + 1))
            log "Failed to set primary display (attempt $retry_count/$MAX_RETRIES)"
            sleep $RETRY_DELAY
        done

        # Move workspaces with proper delays
        for i in {1..10}; do
            DISPLAY=:0 i3-msg "workspace $i; move workspace to output $target_output"
            handle_error "Moving workspace $i" || log "Failed to move workspace $i"
            sleep 0.2
        done

        # Restore focus with verification
        if ! DISPLAY=:0 i3-msg "workspace $current_workspace"; then
            log "Failed to return to workspace $current_workspace"
            DISPLAY=:0 i3-msg "workspace 1"
        fi

        if [ ! -z "$focused_window" ]; then
            DISPLAY=:0 i3-msg "[id=$focused_window] focus" || log "Failed to refocus window"
        fi
    fi
}

# Function to configure displays
configure_displays() {
    local display_info=$1
    local mode=$(echo $display_info | cut -d: -f1)
    local retry_count=0

    if [ "$mode" = "external" ]; then
        local external_display=$(echo $display_info | cut -d: -f2)
        local resolution=$(echo $display_info | cut -d: -f3)
        local refresh_rate=$(echo $display_info | cut -d: -f4)
        local internal_display=$(echo $display_info | cut -d: -f5)

        log "Setting up dual display mode (External: $external_display, Resolution: $resolution, Refresh: $refresh_rate)"

        while [ $retry_count -lt $MAX_RETRIES ]; do
            if DISPLAY=:0 xrandr \
                --output "$external_display" --mode "$resolution" --rate "$refresh_rate" --pos 1920x0 \
                --output "$internal_display" --mode "$PRIMARY_RESOLUTION" --pos 0x0; then
                break
            fi
            retry_count=$((retry_count + 1))
            log "Failed to configure dual display mode (attempt $retry_count/$MAX_RETRIES)"
            sleep $RETRY_DELAY
        done

        manage_workspaces "$external_display"
    else
        local internal_display=$(echo $display_info | cut -d: -f2)
        log "Setting up internal display mode"

        # Turn off all displays except internal
        for display in $(DISPLAY=:0 xrandr --query | grep " connected" | cut -d" " -f1); do
            if [ "$display" != "$internal_display" ]; then
                DISPLAY=:0 xrandr --output "$display" --off
            fi
        done

        # Configure internal display
        while [ $retry_count -lt $MAX_RETRIES ]; do
            if DISPLAY=:0 xrandr --output "$internal_display" --mode "$PRIMARY_RESOLUTION" --pos 0x0; then
                break
            fi
            retry_count=$((retry_count + 1))
            log "Failed to configure internal display mode (attempt $retry_count/$MAX_RETRIES)"
            sleep $RETRY_DELAY
        done

        manage_workspaces "$internal_display"
    fi

    # Restart polybar with proper delay and verification
    pkill polybar
    sleep 2
    if ! $HOME/.config/polybar/launch_polybar.sh; then
        log "Failed to launch polybar"
        sleep 1
        $HOME/.config/polybar/launch_polybar.sh
    fi
}

# Main execution
main() {
    log "Starting monitor configuration"

    # Ensure X server is ready
    if ! wait_for_x; then
        log "Error: X server not ready"
        exit 1
    fi

    # Detect and configure displays
    local display_info=$(detect_displays)
    configure_displays "$display_info"
    log "Monitor configuration completed successfully"
}

main
