#!/bin/bash

# Define the menu options with icons
entries="⏻ Shutdown\n⭮ Reboot\n⏾ Suspend\n⇠ Logout\n🔒 Lock"

# Show wofi in the center with a nice style
selected=$(echo -e $entries | wofi \
    --dmenu \
    --cache-file=/dev/null \
    --prompt="Power Menu" \
    --width=250 \
    --height=255 \
    --style=/home/abbes/.config/wofi/power-menu.css \
    --location=center \
    --conf=/home/abbes/.config/wofi/power-menu.conf)

# Handle the selection
case $selected in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "⭮ Reboot")
        systemctl reboot
        ;;
    "⏾ Suspend")
        systemctl suspend
        ;;
    "⇠ Logout")
        swaymsg exit
        ;;
    "🔒 Lock")
        swaylock -f
        ;;
esac
