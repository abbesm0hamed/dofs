#!/bin/bash

# Kill existing waybar instances
killall waybar

# Wait a moment for cleanup
sleep 1

# Start waybar with explicit Wayland display
WAYLAND_DISPLAY=wayland-1 waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css 2>&1 | tee /tmp/waybar.log &
