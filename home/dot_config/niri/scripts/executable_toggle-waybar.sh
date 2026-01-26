#!/bin/bash

if pgrep -x "waybar" > /dev/null; then
    if pkill -SIGUSR1 -x "waybar" 2>/dev/null; then
        exit 0
    fi

    pkill -x "waybar"
    exit 0
fi

waybar & disown
