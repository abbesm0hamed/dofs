#!/bin/bash

# Get the current user and home directory
USER_NAME=$(whoami)
USER_HOME=$(getent passwd $USER_NAME | cut -d: -f6)

# Ensure DISPLAY is set
[ -z "$DISPLAY" ] && export DISPLAY=:0
export XAUTHORITY="$USER_HOME/.Xauthority"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "/tmp/monitor-setup-$USER_NAME.log"
}

# Function to check if the second monitor is connected
function is_second_monitor_connected {
    xrandr | grep "HDMI-1-0 connected" >/dev/null
}

# Function to get the name of the current primary display
function get_current_primary {
    xrandr | grep "primary" | cut -d" " -f1
}

# Function to check if X server is ready
function wait_for_x {
    for i in {1..30}; do
        if xrandr >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.1
    done
    return 1
}

# Function to set up the display configurations and handle workspace transitions
function setup_displays_and_workspaces {
    # Wait for X server
    if ! wait_for_x; then
        log "Error: X server not ready"
        return 1
    }

    local current_primary=$(get_current_primary)
    local new_primary
    # Get both the current workspace and focused window ID
    local current_workspace=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' -r)
    local focused_window=$(i3-msg -t get_tree | jq '.. | select(.focused? == true).id')

    if is_second_monitor_connected; then
        new_primary="HDMI-1-0"
        # Check if the display configuration needs to change
        if ! xrandr | grep -q "HDMI-1-0.*1920x1080.*170.00"; then
            log "Configuring HDMI-1-0 as primary display"
            xrandr --output HDMI-1-0 --mode 1920x1080 --pos 1920x0 --rate 170 --rotate normal \
                --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal || log "Error: Failed to configure HDMI-1-0"
        fi
    else
        new_primary="eDP-1"
        # Check if HDMI is currently active before turning it off
        if xrandr | grep -q "HDMI-1-0.*[0-9]\\+x[0-9]\\+"; then
            log "Disabling HDMI-1-0, setting eDP-1 as primary"
            xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1-0 --off || log "Error: Failed to disable HDMI-1-0"
        fi
    fi

    # Only change primary and move workspaces if there's an actual change in primary display
    if [ "$current_primary" != "$new_primary" ]; then
        log "Changing primary display from $current_primary to $new_primary"
        xrandr --output $new_primary --primary || log "Error: Failed to set primary display"

        # Move all workspaces to the new primary display
        for i in $(seq 1 10); do
            i3-msg "workspace $i; move workspace to output $new_primary" || log "Error: Failed to move workspace $i"
        done

        # Switch back to the original workspace
        i3-msg "workspace $current_workspace" || log "Error: Failed to switch back to workspace $current_workspace"
    else
        log "No change in primary display required"
    fi
}

# Main execution
log "Starting display configuration"
setup_displays_and_workspaces
log "Display configuration completed"
