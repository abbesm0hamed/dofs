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
        echo "{\"text\": \"󰡨 -\", \"tooltip\": \"Docker daemon not running\", \"class\": \"inactive\"}"
        return 1
    fi

    # Count running containers
    RUNNING=$(docker ps -q 2>/dev/null | wc -l)

    if [ "$RUNNING" -gt 0 ]; then
        echo "{\"text\": \"󰡨 $RUNNING\", \"tooltip\": \"Active Containers: $RUNNING\", \"class\": \"active\"}"
    else
        echo "{\"text\": \"󰡨 0\", \"tooltip\": \"No active containers\", \"class\": \"inactive\"}"
    fi
}

while true; do
    get_status

    if ! docker_cli_available; then
        sleep 10
        continue
    fi

    if ! docker_daemon_available; then
        sleep 5
        continue
    fi

    # Listen for container events (start, die, stop, etc.)
    # We use stdbuf to ensure line-buffered output from docker events
    stdbuf -oL docker events --filter "type=container" --format "{{.Action}}" 2>/dev/null | while read -r event; do
        case "$event" in
            start|die|stop|kill|pause|unpause|restart)
                get_status
                ;;
        esac
    done

    sleep 2
done
