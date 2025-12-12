#!/bin/bash

# Clipboard manager using cliphist and fuzzel
# Shows clipboard history and allows selection

# Get clipboard history and show in fuzzel
SELECTION=$(cliphist list | fuzzel --dmenu --prompt="Clipboard: " --width=60)

if [ -n "$SELECTION" ]; then
    # Copy selected item back to clipboard
    echo "$SELECTION" | cliphist decode | wl-copy
    notify-send "Clipboard" "Item copied to clipboard"
fi
