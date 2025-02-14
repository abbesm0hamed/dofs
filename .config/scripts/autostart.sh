#!/bin/bash

# Improved process management function
function run {
    if ! pgrep -x "$1" >/dev/null; then
        if [ "$#" -gt 1 ]; then
            "$@" &
        else
            "$1" &
        fi
    fi
}

# Clean up existing processes
killall -q mako waybar

# Wait for processes to end
while pgrep -u $UID -x mako >/dev/null || pgrep -u $UID -x waybar >/dev/null; do sleep 0.1; done

# Start Waybar with restart capability
sleep 1 && WAYLAND_DISPLAY=wayland-1 waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css 2>&1 | tee /tmp/waybar.log &

# Start critical system services with lower priority
nice -n 10 /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Optimize power management
run powerprofilesctl set performance

# Start notification daemon (mako for Wayland)
sleep 1 && WAYLAND_DISPLAY=wayland-1 mako --config ~/.config/mako/config 2>&1 | tee /tmp/mako.log &

# Start system tray applications with slight delays to prevent resource contention
(sleep 1 && run nm-applet --indicator) & # --indicator for better Wayland support
(sleep 1.5 && run blueman-applet) &

(sleep 2 && run pamac-tray) &

# Start user applications
run discord # Start Discord on workspace 8
run slack   # Start Slack on workspace 9

# Initialize Wayland-specific services
run kanshi # Automatic display management
run wob # On-screen display bars
# run wlsunset -l 36.8 -L 10.2  # Night light management

# Initialize XDG portals for better app integration
run /usr/lib/xdg-desktop-portal-wlr &
run /usr/lib/xdg-desktop-portal &
