#!/bin/bash

if systemctl --user is-active --quiet swayidle.service 2>/dev/null; then
    systemctl --user stop swayidle.service
elif pgrep -x swayidle >/dev/null 2>&1; then
    pkill -x swayidle
else
    if systemctl --user list-unit-files swayidle.service >/dev/null 2>&1; then
        systemctl --user start swayidle.service
    else
        swayidle -w \
            timeout 1200 'niri msg action power-off-monitors' \
            resume 'niri msg action power-on-monitors' \
            timeout 1800 "swaylock -f -i '$LOCK_WALLPAPER'" \
            before-sleep "swaylock -f -i '$LOCK_WALLPAPER'" &
    fi
fi

pkill -RTMIN+10 waybar
