#!/bin/bash

# Configuration
CACHE_FILE="/tmp/waybar_check_updates_cache"
CACHE_TTL=3600 # 1 hour

# Ensure the cache file exists
if [ ! -f "$CACHE_FILE" ]; then
    echo "0" > "$CACHE_FILE"
fi

# Check if cache is expired
LAST_UPDATE=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)

if [ $((CURRENT_TIME - LAST_UPDATE)) -gt "$CACHE_TTL" ]; then
    # Check DNF updates (quietly)
    DNF_COUNT=$(dnf check-update -q --refresh | grep '\.' | grep -v 'Security:' | wc -l || echo 0)
    
    # Check Flatpak updates (if installed)
    FLATPAK_COUNT=0
    if command -v flatpak &>/dev/null; then
        FLATPAK_COUNT=$(flatpak remote-ls --updates --short | wc -l || echo 0)
    fi
    
    TOTAL_COUNT=$((DNF_COUNT + FLATPAK_COUNT))
    echo "$TOTAL_COUNT" > "$CACHE_FILE"
fi

TOTAL_COUNT=$(cat "$CACHE_FILE" 2>/dev/null | tr -d '\n' || echo 0)

if [ "$TOTAL_COUNT" -gt 0 ]; then
    echo "{\"text\": \"<span rise='1000'>󰚰</span> $TOTAL_COUNT\", \"tooltip\": \"$TOTAL_COUNT updates available (DNF + Flatpak)\", \"class\": \"updates\"}"
else
    echo "{\"text\": \"\", \"class\": \"none\"}"
fi
