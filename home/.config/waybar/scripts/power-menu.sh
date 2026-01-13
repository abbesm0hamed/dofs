#!/bin/bash

options="󰌾 Lock\n󰗽 Logout\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown"

selected=$(echo -e "$options" | rofi -dmenu -p "󰐥 Power: " -theme-str 'window { width: 20%; height: 30%; }')

case $selected in
    "󰌾 Lock")
        hyprlock
        ;;
    "󰗽 Logout")
        niri msg action quit
        ;;
    "󰤄 Suspend")
        systemctl suspend
        ;;
    "󰜉 Reboot")
        systemctl reboot
        ;;
    "󰐥 Shutdown")
        systemctl poweroff
        ;;
esac
