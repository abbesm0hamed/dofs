#!/usr/bin/env bash

# Power menu options with Nerd Font icons
options="󰌾 Lock\n󰗽 Logout\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown"

# Show walker menu and get selection
selected=$(echo -e "$options" | walker --dmenu --prompt="󰐥 Power: " --width=32 --lines=5)

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
