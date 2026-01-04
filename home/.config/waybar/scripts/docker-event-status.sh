#!/bin/bash

# Event-driven Docker status script for Waybar
# Listens to docker events to update instantly

get_status() {
    if ! command -v docker &>/dev/null; then
        echo "{\"text\": \"\", \"class\": \"hidden\"}"
        return
    fi

    # Count running containers
    RUNNING=$(docker ps -q | wc -l)

    if [ "$RUNNING" -gt 0 ]; then
        echo "{\"text\": \"󰡨 $RUNNING\", \"tooltip\": \"Active Containers: $RUNNING\", \"class\": \"active\"}"
    else
        echo "{\"text\": \"󰡨 0\", \"tooltip\": \"No active containers\", \"class\": \"inactive\"}"
    fi
}

# Initial status
get_status

# Listen for container events (start, die, stop, etc.)
# We use stdbuf to ensure line-buffered output from docker events
stdbuf -oL docker events --filter "type=container" --format "{{.Action}}" | while read -r event; do
    case "$event" in
        start|die|stop|kill|pause|unpause)
            get_status
            ;;
    esac
done
