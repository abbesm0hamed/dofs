#!/bin/bash
# ~/.config/eww/scripts/workspaces.sh
# Outputs eww literal strings for niri workspaces.

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "(box :class \"workspaces widget\" (label :text \"jq not found\"))"
    exit 1
fi

while true; do
    json=$(niri msg -j workspaces 2>/dev/null || echo "[]")
    
    # Check if empty
    if [ "$json" = "[]" ] || [ -z "$json" ]; then
        echo "(box :class \"workspaces widget\" :orientation \"h\" :space-evenly false (label :text \"No workspaces\"))"
    else
        # Process the JSON array into (button ...) structures using jq
        # We handle empty .name by falling back to .id
        items=$(echo "$json" | jq -r '.[] | "(button :class \"\(if .is_active then "focused " else "" end)\(if .is_focused then "active" else "" end)\" :onclick \"niri msg action focus-workspace \(.id)\" \"\(.name // .id)\")"')
        
        # Output the concatenated literal
        literal="(box :class \"workspaces widget\" :orientation \"h\" :space-evenly false $items)"
        
        # Eww reads stdout for deflisten
        echo "$literal"
    fi
    
    sleep 0.1
done
