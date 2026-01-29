#!/bin/bash

# Event-driven Docker status script for Waybar
# Listens to docker events to update instantly, with retry when Docker is down.

docker_cli_available() {
    command -v docker &>/dev/null
}

docker_daemon_available() {
    docker info &>/dev/null
}

get_status() {
    if ! docker_cli_available; then
        echo "{\"text\": \"\", \"class\": \"hidden\"}"
        return 1
    fi

    if ! docker_daemon_available; then
        echo "{\"text\": \"<span rise='1000'>󰡨</span> -\", \"tooltip\": \"Docker daemon not running\", \"class\": \"inactive\"}"
        return 1
    fi

    # Count running containers
    RUNNING_NAMES=$(docker ps --format '{{.Names}}' 2>/dev/null)
    RUNNING=$(printf '%s\n' "$RUNNING_NAMES" | sed '/^$/d' | wc -l)

    if [ "$RUNNING" -gt 0 ]; then
        TOOLTIP_NAMES=$(printf '%s\n' "$RUNNING_NAMES" | sed '/^$/d' | awk 'NR==1 {printf "%s", $0; next} {printf "\\n%s", $0}')
        echo "{\"text\": \"<span rise='1000'>󰡨</span> $RUNNING\", \"tooltip\": \"Active Containers ($RUNNING):\\n$TOOLTIP_NAMES\", \"class\": \"active\"}"
    else
        echo "{\"text\": \"<span rise='1000'>󰡨</span> 0\", \"tooltip\": \"No active containers\", \"class\": \"inactive\"}"
    fi
}

get_status
