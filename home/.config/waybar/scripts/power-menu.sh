#!/bin/bash

options="󰌾 Lock\n󰗽 Logout\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown"

selected=$(echo -e "$options" | fuzzel --dmenu --prompt="󰐥 Power: " --width=25 --lines=5 --line-height=15)

case $selected in
    "󰌾 Lock")
        swaylock -f -C "$HOME/.config/swaylock/config"
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
