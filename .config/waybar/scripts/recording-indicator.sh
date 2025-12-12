#!/bin/bash

# Recording indicator script for Waybar
# Shows recording status with visual indicator using Nerd Font icons

INDICATOR_FILE="/tmp/recording_indicator"

if [ -f "$INDICATOR_FILE" ]; then
    MODE=$(cat "$INDICATOR_FILE")
    case "$MODE" in
        "Region (No Audio)")
            echo '{"text":" ","class":"recording","tooltip":"Recording: Region (No Audio)\nClick to stop recording"}'
            ;;
        "Full Screen (No Audio)")
            echo '{"text":" ","class":"recording","tooltip":"Recording: Full Screen (No Audio)\nClick to stop recording"}'
            ;;
        "Region + Audio")
            echo '{"text":"󰨜 ","class":"recording-audio","tooltip":"Recording: Region + Audio\nClick to stop recording"}'
            ;;
        "Full Screen + Audio")
            echo '{"text":"󰨜 ","class":"recording-audio","tooltip":"Recording: Full Screen + Audio\nClick to stop recording"}'
            ;;
        "Audio Only")
            echo '{"text":"󰍯","class":"recording-audio-only","tooltip":"Recording: Audio Only\nClick to stop recording"}'
            ;;
        *)
            echo '{"text":" ","class":"recording","tooltip":"Recording in progress\nClick to stop recording"}'
            ;;
    esac
else
    # No recording active - show inactive state
    echo '{"text":" ","class":"inactive","tooltip":"Screen recording ready\nUse keybindings to start recording"}'
fi
