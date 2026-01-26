#!/bin/bash

# Get the default source (microphone) mute status
MUTE_STATUS=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')

# Get the volume percentage
VOLUME=$(pactl get-source-volume @DEFAULT_SOURCE@ | grep -oP '\d+%' | head -1 | tr -d '%')

if [ "$MUTE_STATUS" = "yes" ]; then
    # Muted - red microphone off icon
    echo "{\"text\":\"<span foreground='#f38ba8'> </span>\",\"tooltip\":\"Mic: Muted\"}"
else
    # Unmuted - normal microphone icon
    echo "{\"text\":\"\",\"tooltip\":\"Mic: ${VOLUME}%\"}"
fi
