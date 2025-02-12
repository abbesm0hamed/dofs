#!/bin/bash

# Source configuration
CONFIG_FILE="$HOME/.config/grimshot/config.sh"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Default configuration if not set in config.sh
SCREENSHOT_DIR=${SCREENSHOT_DIR:-"$HOME/Pictures/Screenshots"}
SCREENSHOT_FILENAME=${SCREENSHOT_FILENAME:-"screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"}
NOTIFY_TIMEOUT=${NOTIFY_TIMEOUT:-2000}
NOTIFY_URGENCY=${NOTIFY_URGENCY:-"low"}

# Ensure screenshot directory exists
mkdir -p "$SCREENSHOT_DIR"

take_screenshot() {
    local type=$1
    local filename=$(date +"$SCREENSHOT_FILENAME")
    local filepath="$SCREENSHOT_DIR/$filename"

    case $type in
    "screen")
        grim "$filepath"
        ;;
    "area")
        grim -g "$(slurp)" "$filepath"
        ;;
    "active")
        swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' |
            grim -g - "$filepath"
        ;;
    *)
        echo "Invalid screenshot type. Use: screen, area, or active."
        exit 1
        ;;
    esac

    if [ $? -eq 0 ]; then
        # Notify user of success
        notify-send -t "$NOTIFY_TIMEOUT" -u "$NOTIFY_URGENCY" \
            "Screenshot Captured" "Saved as: $filename\nPath: $filepath" \
            -i "$filepath"

        # Copy to clipboard
        wl-copy <"$filepath"
    else
        # Notify user of failure
        notify-send -t "$NOTIFY_TIMEOUT" -u "critical" \
            "Screenshot Failed" "Could not capture screenshot"
    fi
}

# Check if a parameter is passed
if [ -z "$1" ]; then
    echo "Usage: $0 [screen|area|active]"
    exit 1
fi

# Execute screenshot function with parameter
take_screenshot "$1"
