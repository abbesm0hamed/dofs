#!/bin/bash

options="󰌾 Lock\n󰗽 Logout\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown"

line_count=$(echo -e "$options" | wc -l)

theme_str="
window { width: 20%; height: 0px; }
listview { lines: ${line_count}; fixed-height: false; dynamic: false; }
"

selected=$(echo -e "$options" | rofi -dmenu -i -p "󰐥 Power: " -l "$line_count" -sync -theme-str "$theme_str")

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
