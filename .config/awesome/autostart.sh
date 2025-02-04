#!/bin/bash

function run {
    if ! pgrep -f "$1" > /dev/null; then
        $@&
    fi
}

# Essential system services
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1  # For GUI authentication
run nm-applet  # Network management
run numlockx on  # Numlock state

# Monitor setup - using xrandr directly for speed
xrandr --output HDMI-1-0 --primary --mode 1920x1080 --pos 1920x0 --rate 170 --rotate normal --output HDMI-2-0 --off

# Set wallpaper - using feh for its low resource usage
feh --no-fehbg --bg-fill $HOME/.config/awesome/themes/mytheme/wallpapers/sphere.jpg --bg-fill $HOME/.config/awesome/themes/mytheme/wallpapers/vanilla.jpg
