#!/bin/bash

# Visual feedback (OSD) script using wob
# Usage: osd.sh [volume|brightness] [value]

WOB_SOCK="${XDG_RUNTIME_DIR}/wob.sock"

# Ensure wob is running and the pipe exists
if [[ ! -p "$WOB_SOCK" ]]; then
    mkfifo "$WOB_SOCK" 2>/dev/null
    wob < "$WOB_SOCK" &
fi

case "$1" in
    "volume")
        # Get current volume from wpctl
        VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -oP '\d+\.\d+' | awk '{print $1 * 100}')
        MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q '\[MUTED\]' && echo 1 || echo 0)
        
        if [ "$MUTED" -eq 1 ]; then
            echo 0 > "$WOB_SOCK"
        else
            echo "$VOLUME" > "$WOB_SOCK"
        fi
        ;;
    "brightness")
        # Get current brightness percentage from brightnessctl
        BRIGHTNESS=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
        echo "$BRIGHTNESS" > "$WOB_SOCK"
        ;;
esac
