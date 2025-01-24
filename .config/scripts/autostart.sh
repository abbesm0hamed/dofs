#!/bin/bash

function run {
    if ! pgrep $1; then
        "$@" &
    fi
}

BACKGROUND_PRIMARY="$HOME/.config/backgrounds/alien.jpg"
BACKGROUND_SECONDARY="$HOME/.config/backgrounds/rats.jpg"
PICOM_CONFIG="$HOME/.config/picom/picom.conf"

# Function to check if the second monitor (HDMI-1-0) is connected
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
        xrandr --output HDMI-1-0 --mode 1920x1080 --pos 1920x0 --rate 170 --rotate normal \
            --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal
    else
        new_primary="eDP-1"
        xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1-0 --off
    fi

    if [ "$current_primary" != "$new_primary" ]; then
        xrandr --output $new_primary --primary

        # Move all workspaces to the new primary display
        for i in $(seq 1 10); do
            i3-msg "workspace $i; move workspace to output $new_primary"
        done
    fi

    # First switch to the target workspace
    i3-msg "workspace $current_workspace"

    # Then focus the previously focused window if it exists
    if [ ! -z "$focused_window" ] && [ "$focused_window" != "null" ]; then
        i3-msg "[con_id=$focused_window] focus"
    fi
}

# Main execution
setup_displays_and_workspaces

# Kill existing instances of polybar and picom
killall -q polybar picom dunst

# Start critical system services first
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
run xfce4-power-manager
sleep 1

# Set up displays and backgrounds
run xrandr --output HDMI-1-0 --primary --mode 1920x1080 --pos 1920x0 --rate 170 --rotate normal --output HDMI-2-0 --off
run feh --no-fehbg --bg-fill "$BACKGROUND_PRIMARY" --bg-fill "$BACKGROUND_SECONDARY"

# Start window manager related services
run picom --config $PICOM_CONFIG --vsync
run ~/.config/polybar/launch_polybar.sh # Ensure this script sets the MONITOR variable
run sxhkd -c "$HOME/.config/sxhkd/sxhkdrc"
run autotiling

# Start system tray applications
run pamac-tray
run nm-applet
run blueman-applet
run blueberry-tray
run volumeicon

# Start user applications
run numlockx on
dunst &
run variety
run flameshot
run gammastep
