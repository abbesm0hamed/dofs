#!/bin/bash

# Set error handling
set -euo pipefail

# Configuration
BACKGROUND_PRIMARY="$HOME/.config/backgrounds/kanagawa-blue-sky.png"
BACKGROUND_SECONDARY="$HOME/.config/backgrounds/kanagawa.png"
PICOM_CONFIG="$HOME/.config/picom/picom.conf"

# Helper function to run processes if not already running
function run {
    if ! pgrep -x "$1" >/dev/null; then
        "$@" &
    fi
}

# Monitor configuration functions
function is_second_monitor_connected {
    xrandr | grep "HDMI-1-0 connected" > /dev/null
}

function get_current_primary {
    xrandr | grep "primary" | cut -d" " -f1
}

# Display setup with improved error handling and performance
function setup_displays_and_workspaces {
    local current_primary=$(get_current_primary)
    local new_primary
    local current_workspace=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' -r)
    
    # Wait for X server to be fully ready
    sleep 0.5

    if is_second_monitor_connected; then
        new_primary="HDMI-1-0"
        # Configure displays with proper sync and reduced tearing
        if ! xrandr --output HDMI-1-0 --mode 1920x1080 --pos 1920x0 --rate 60 --rotate normal \
                    --output eDP-1 --mode 1920x1080 --pos 0x0 --primary --rotate normal; then
            echo "Error: Failed to configure dual monitor setup" >&2
            return 1
        fi
        
        # Set proper DRI driver for better performance
        export LIBVA_DRIVER_NAME=i965
        export VDPAU_DRIVER=va_gl
    else
        new_primary="eDP-1"
        if ! xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal --primary \
                    --output HDMI-1-0 --off; then
            echo "Error: Failed to configure single monitor setup" >&2
            return 1
        fi
    fi

    # Only move workspaces if primary changed
    if [ "$current_primary" != "$new_primary" ]; then
        # Move workspaces in parallel for better performance
        for i in $(seq 1 10); do
            i3-msg "workspace $i; move workspace to output $new_primary" &
        done
        wait
    fi

    # Restore active workspace
    i3-msg "workspace $current_workspace"
}

# Compositor setup with optimized settings
function setup_compositor {
    # Kill existing compositor
    killall picom 2>/dev/null || true
    sleep 0.5

    # Start compositor with optimized settings
    run picom --config "$PICOM_CONFIG" \
             --vsync \
             --backend glx \
             --glx-no-stencil \
             --glx-no-rebind-pixmap \
             --use-damage \
             --xrender-sync-fence
}

# Main execution with parallel loading where possible
function main {
    # Set up displays first
    setup_displays_and_workspaces

    # Start essential services in parallel
    setup_compositor &
    run feh --no-fehbg --bg-fill "$BACKGROUND_PRIMARY" --bg-fill "$BACKGROUND_SECONDARY" &

    # Restart polybar
    killall polybar 2>/dev/null || true
    run ~/.config/polybar/launch_polybar.sh

    # Start system tray applications in parallel
    run pamac-tray &
    run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
    run xfce4-power-manager &
    run blueberry-tray &
    run blueman-applet &
    run nm-applet &
    run volumeicon &

    # Start utilities in parallel
    run autotiling &
    run dunst &
    run variety &
    run flameshot &
    run sxhkd -c "$HOME/.config/sxhkd/sxhkdrc" &

    # Wait for all background processes to initialize
    wait
}

# Execute main function
main
