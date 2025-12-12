#!/bin/bash

# Screenshot script for Niri with Satty integration
# Usage: screenshot.sh [region|window|screen]

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Temporary file for satty
TEMP_FILE="/tmp/screenshot-$(date +%Y%m%d-%H%M%S).png"
FINAL_FILE="$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"

case "${1:-region}" in
    "region")
        # Select area and screenshot, then open in satty for editing
        if grim -g "$(slurp)" "$TEMP_FILE" 2>/dev/null; then
            # Open in satty for annotation/editing
            if command -v satty >/dev/null 2>&1; then
                satty --filename "$TEMP_FILE" --fullscreen --output-filename "$FINAL_FILE" --copy-command "wl-copy" --early-exit
                # Clean up temp file
                rm -f "$TEMP_FILE" 2>/dev/null
            else
                # Fallback: just save and copy to clipboard
                cp "$TEMP_FILE" "$FINAL_FILE"
                wl-copy <"$FINAL_FILE"
                rm -f "$TEMP_FILE"
                notify-send "Screenshot" "Region screenshot saved and copied to clipboard"
            fi
        else
            notify-send "Screenshot" "Region selection cancelled"
        fi
        ;;
    "window")
        # Screenshot focused window, then open in satty
        if niri msg focused-window | jq -r '.geometry | "\(.x),\(.y) \(.width)x\(.height)"' | xargs -I {} grim -g "{}" "$TEMP_FILE" 2>/dev/null; then
            if command -v satty >/dev/null 2>&1; then
                satty --filename "$TEMP_FILE" --fullscreen --output-filename "$FINAL_FILE" --copy-command "wl-copy" --early-exit
                rm -f "$TEMP_FILE" 2>/dev/null
            else
                cp "$TEMP_FILE" "$FINAL_FILE"
                wl-copy <"$FINAL_FILE"
                rm -f "$TEMP_FILE"
                notify-send "Screenshot" "Window screenshot saved and copied to clipboard"
            fi
        else
            notify-send "Screenshot" "Failed to capture window"
        fi
        ;;
    "screen")
        # Full screen screenshot, then open in satty
        if grim "$TEMP_FILE" 2>/dev/null; then
            if command -v satty >/dev/null 2>&1; then
                satty --filename "$TEMP_FILE" --fullscreen --output-filename "$FINAL_FILE" --copy-command "wl-copy" --early-exit
                rm -f "$TEMP_FILE" 2>/dev/null
            else
                cp "$TEMP_FILE" "$FINAL_FILE"
                wl-copy <"$FINAL_FILE"
                rm -f "$TEMP_FILE"
                notify-send "Screenshot" "Screen screenshot saved and copied to clipboard"
            fi
        else
            notify-send "Screenshot" "Failed to capture screen"
        fi
        ;;
    *)
        echo "Usage: $0 [region|window|screen]"
        exit 1
        ;;
esac
