#!/bin/bash

options="󰌾 Lock\n󰗽 Logout\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown"

selected=$(echo -e "$options" | fuzzel --dmenu --prompt="󰐥 Power: " --width=32 --lines=5)

case $selected in
    "󰌾 Lock")
        swaylock
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
