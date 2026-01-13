#!/bin/bash

# Clipboard manager using cliphist and rofi
# Shows clipboard history and allows selection

# Get clipboard history and show in rofi
SELECTION=$(cliphist list | rofi -dmenu -p "󰅍 Clipboard: ")

if [ -n "$SELECTION" ]; then
    # Copy selected item back to clipboard
    echo "$SELECTION" | cliphist decode | wl-copy
    notify-send "Clipboard" "Item copied to clipboard"
fi
