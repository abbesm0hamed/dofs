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
    # Avoid overlapping dnf checks
    if ! pgrep -x dnf > /dev/null; then
        # Identify package lines by looking for lines with dots (e.g. .x86_64) 
        # that aren't metadata/security messages.
        COUNT=$(dnf check-update -q --refresh | grep '\.' | grep -v 'Security:' | wc -l || echo 0)
        echo "$COUNT" > "$CACHE_FILE"
    fi
fi

COUNT=$(cat "$CACHE_FILE" 2>/dev/null | tr -d '\n' || echo 0)

if [ "$COUNT" -gt 0 ]; then
    echo "{\"text\": \"<span rise='1000'>󰚰</span> $COUNT\", \"tooltip\": \"$COUNT updates available\", \"class\": \"updates\"}"
else
    echo "{\"text\": \"\", \"class\": \"none\"}"
fi
