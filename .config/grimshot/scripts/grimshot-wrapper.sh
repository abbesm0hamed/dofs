#!/bin/bash

source ~/.config/grimshot/config.sh

take_screenshot() {
    local type=$1
    local filename=$(date +"$SCREENSHOT_FILENAME")
    local filepath="$SCREENSHOT_DIR/$filename"
    
    case $type in
        "screen")
            grimshot save screen "$filepath"
            ;;
        "area")
            grimshot save area "$filepath"
            ;;
        "active")
            grimshot save active "$filepath"
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        notify-send -t "$NOTIFY_TIMEOUT" -u "$NOTIFY_URGENCY" \
            "Screenshot Captured" "Saved as: $filename" \
            -i "$filepath"
        
        # Copy to clipboard
        wl-copy < "$filepath"
    else
        notify-send -t "$NOTIFY_TIMEOUT" -u "critical" \
            "Screenshot Failed" "Failed to capture screenshot"
    fi
}

# Execute with parameter
take_screenshot "$1"