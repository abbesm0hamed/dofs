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

# Wait for X server to be fully ready
sleep 2

# Clean up existing processes
killall -q picom dunst
# Wait for processes to end
while pgrep -u $UID -x picom >/dev/null; do sleep 0.1; done
while pgrep -u $UID -x dunst >/dev/null; do sleep 0.1; done

# Start critical system services with lower priority
nice -n 10 /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Setup monitors and wallpaper
(sleep 1 && $HOME/.config/scripts/setup-wallpaper.sh) &

# Optimize power management
run xfce4-power-manager --no-daemon

# Start compositor with optimized settings
PICOM_CONFIG="$HOME/.config/picom/picom.conf"
if [ -f "$PICOM_CONFIG" ]; then
    run picom --config "$PICOM_CONFIG" --vsync --backend glx --unredir-if-possible --use-damage
else
    run picom --vsync --backend glx --unredir-if-possible --use-damage
fi

# Start system tray applications with slight delays
(sleep 1 && run nm-applet) &
(sleep 1.5 && run blueman-applet) &
(sleep 2 && run pamac-tray) &

# Start user applications
run numlockx on
run dunst
run flameshot

