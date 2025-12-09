#!/usr/bin/env bash

# Clipboard manager using cliphist and walker
# Shows clipboard history and allows selection

# Get clipboard history and show in walker
SELECTION=$(cliphist list | walker --dmenu --prompt="Clipboard: " --width=60)

if [ -n "$SELECTION" ]; then
    # Copy selected item back to clipboard
    echo "$SELECTION" | cliphist decode | wl-copy
    notify-send "Clipboard" "Item copied to clipboard"
fi
