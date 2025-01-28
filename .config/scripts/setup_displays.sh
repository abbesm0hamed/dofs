#!/bin/bash

# Function to check if the second monitor is connected
function is_second_monitor_connected {
    xrandr | grep "HDMI-1-0 connected" >/dev/null
}

# Function to get the name of the current primary display
function get_current_primary {
    xrandr | grep "primary" | cut -d" " -f1
}

# Function to set up the display configurations and handle workspace transitions
function setup_displays_and_workspaces {
    local current_primary=$(get_current_primary)
    local new_primary
    # Get both the current workspace and focused window ID
    local current_workspace=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' -r)
    local focused_window=$(i3-msg -t get_tree | jq '.. | select(.focused? == true).id')

    if is_second_monitor_connected; then
        new_primary="HDMI-1-0"
        # Check if the display configuration needs to change
        if ! xrandr | grep -q "HDMI-1-0.*1920x1080.*170.00"; then
            xrandr --output HDMI-1-0 --mode 1920x1080 --pos 1920x0 --rate 170 --rotate normal \
                --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal
        fi
    else
        new_primary="eDP-1"
        # Check if HDMI is currently active before turning it off
        if xrandr | grep -q "HDMI-1-0.*[0-9]\\+x[0-9]\\+"; then
            xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1-0 --off
        fi
    fi

    # Only change primary and move workspaces if there's an actual change in primary display
    if [ "$current_primary" != "$new_primary" ]; then
        xrandr --output $new_primary --primary

        # Move all workspaces to the new primary display
        for i in $(seq 1 10); do
            i3-msg "workspace $i; move workspace to output $new_primary"
        done

        # Switch back to the original workspace
        i3-msg "workspace $current_workspace"
    fi
}

# Main execution
setup_displays_and_workspaces
