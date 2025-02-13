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
killall -q picom dunst

# Wait for processes to end
while pgrep -u $UID -x picom >/dev/null; do sleep 0.1; done
while pgrep -u $UID -x dunst >/dev/null; do sleep 0.1; done

# Start critical system services with lower priority
nice -n 10 /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Optimize power management
run xfce4-power-manager --no-daemon

# Start compositor with optimized settings
PICOM_CONFIG="$HOME/.config/picom/picom.conf"
if [ -f "$PICOM_CONFIG" ]; then
    run picom --config "$PICOM_CONFIG" --vsync --backend glx --unredir-if-possible --use-damage
else
    run picom --vsync --backend glx --unredir-if-possible --use-damage
fi

# Start system tray applications with slight delays to prevent resource contention
(sleep 0.5 && run nm-applet) &
(sleep 0.7 && run blueman-applet) &
(sleep 0.9 && run pamac-tray) &
(sleep 1.1 && run blueberry-tray) &

# Start user applications
# run gammastep -l 36.8:10.2 # Adjusted for Tunisia location
run numlockx on
run dunst
run variety
run flameshot
