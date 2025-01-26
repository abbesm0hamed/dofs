#!/bin/bash

# Debug logging
exec 1> >(tee -a /tmp/polybar_toggle.log)
exec 2>&1
echo "[$(date)] Toggle bars script started with arg: $1"

# Function to kill existing polybars
kill_polybars() {
    echo "[$(date)] Killing existing polybars"
    killall -q polybar
    while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done
}

# Function to launch a bar
launch_bar() {
    local bar=$1
    echo "[$(date)] Launching bar: $bar"
    
    # Set monitor if not set
    if [ -z "$MONITOR" ]; then
        export MONITOR=$(polybar -m | head -n 1 | cut -d":" -f1)
    fi
    
    # Launch the bar
    polybar $bar &
    sleep 0.5  # Give some time for the bar to start
}

# Function to toggle a specific bar
toggle_bar() {
    local bar=$1
    echo "[$(date)] Attempting to toggle bar: $bar"
    
    local pids=$(pgrep -f "polybar.*$bar")
    
    if [ -n "$pids" ]; then
        echo "[$(date)] Bar $bar is running, toggling visibility"
        for pid in $pids; do
            polybar-msg -p $pid cmd toggle 2>/dev/null || {
                echo "[$(date)] Failed to toggle bar $bar (PID: $pid), restarting it"
                kill $pid 2>/dev/null
                launch_bar "$bar"
            }
        done
    else
        echo "[$(date)] Bar $bar is not running, launching it"
        launch_bar "$bar"
    fi
}

# Main logic
case "$1" in
    "top")
        toggle_bar "top"
        ;;
    "bottom")
        toggle_bar "bottom"
        ;;
    "all")
        # Check if any polybar is running
        if pgrep -x polybar >/dev/null; then
            echo "[$(date)] Polybars are running, toggling all"
            for bar in "top" "bottom"; do
                toggle_bar "$bar"
            done
        else
            echo "[$(date)] No polybars running, launching all"
            launch_bar "top"
            launch_bar "bottom"
        fi
        ;;
    *)
        echo "Usage: $0 {top|bottom|all}"
        exit 1
        ;;
esac
