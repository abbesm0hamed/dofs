#!/bin/bash

function run {
    if ! pgrep -x "$1" >/dev/null; then
        "$@" &
    fi
}

# PICOM_CONFIG="$HOME/.config/picom/picom.conf"

# Kill existing instances
killall -q picom dunst

# Start critical system services
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
run xfce4-power-manager

# Start window manager related services
# if [ -f "$PICOM_CONFIG" ]; then
#     run picom --config "$PICOM_CONFIG" --vsync
# else
#     run picom
# fi

# Start essential system tray applications
run nm-applet
run blueman-applet
run pamac-tray

# Start minimal set of user applications
run numlockx on
dunst &
run flameshot
run gammastep

# Start minimal compositor without effects
picom --no-fading --no-vsync --backend glx --unredir-if-possible &
