#!/bin/bash

# Rofi Power Menu
rofi_command="rofi -dmenu -p Power Menu"

# Options
shutdown="Shutdown"
reboot="Reboot"
lock="Lock"
suspend="Suspend"
hibernate="Hibernate"
logout="Logout"

# Variable passed to rofi
options="$shutdown\n$reboot\n$lock\n$suspend\n$hibernate\n$logout"

chosen="$(echo -e "$options" | $rofi_command)"
case $chosen in
    $shutdown)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        ;;
    $lock)
        swaylock    
        ;;
    $suspend)
        systemctl suspend
        ;;
    $hibernate)
        systemctl hibernate
        ;;
    $logout)
        swaymsg exit    
        ;;
esac
