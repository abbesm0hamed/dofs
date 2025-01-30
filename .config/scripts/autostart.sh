#!/bin/bash

function run {
    if ! pgrep $1; then
        "$@" &
    fi
}

PICOM_CONFIG="$HOME/.config/picom/picom.conf"

# Kill existing instances of dunst and picom
killall -q picom dunst

# Start critical system services first
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
run xfce4-power-manager
sleep 1

# Start window manager related services
if [ -f "$PICOM_CONFIG" ]; then
    run picom --config "$PICOM_CONFIG" --vsync
else
    run picom
fi

# Start system tray applications
run nm-applet
run blueman-applet
run pamac-tray
run blueberry-tray
# run volumeicon # if you have polybar then you don't need this

# Start user applications
run numlockx on
dunst &
run variety
run flameshot
run gammastep
