#!/bin/bash

# Simple Docker status script for Waybar

if ! command -v docker &>/dev/null; then
    echo ""
    exit 0
fi

# Count running containers
RUNNING=$(docker ps -q | wc -l)

if [ "$RUNNING" -gt 0 ]; then
    echo "{\"text\": \"󰡨 $RUNNING \", \"tooltip\": \"Active Containers: $RUNNING\", \"class\": \"active\"}"
else
    echo "{\"text\": \"󰡨 0 \", \"tooltip\": \"No active containers\", \"class\": \"inactive\"}"
fi
