#!/bin/bash

# Configuration
CACHE_FILE="/tmp/dnf_updates_cache"
CACHE_TTL=3600 # 1 hour

# Ensure the cache file exists
if [ ! -f "$CACHE_FILE" ]; then
    echo "0" > "$CACHE_FILE"
fi

# Check if cache is expired
LAST_UPDATE=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)

if [ $((CURRENT_TIME - LAST_UPDATE)) -gt "$CACHE_TTL" ]; then
    # Run check-update in background to avoid blocking Waybar
    # We use a temp file to store the new count
    (
        COUNT=$(dnf check-update -q --refresh | grep -v '^$' | wc -l || echo 0)
        # dnf check-update returns 100 if updates exist, 0 if not. 
        # But we want the count of packages.
        echo "$COUNT" > "$CACHE_FILE"
    ) &
fi

COUNT=$(cat "$CACHE_FILE")

if [ "$COUNT" -eq 0 ]; then
    # No updates, output empty JSON or hidden state
    echo "{\"text\": \"\", \"class\": \"none\", \"alt\": \"none\"}"
else
    echo "{\"text\": \"󰚰 $COUNT\", \"tooltip\": \"$COUNT updates available\", \"class\": \"updates\", \"alt\": \"updates\"}"
fi
