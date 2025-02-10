#!/bin/bash

# Error handling
set -euo pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Improved process management function with error handling
run() {
    local name="$1"
    shift
    if ! pgrep -x "$name" >/dev/null; then
        log "Starting $name"
        if ! "$@" &>/dev/null & then
            log "Failed to start $name"
            return 1
        fi
    else
        log "$name is already running"
    fi
}

# Clean up existing processes
log "Cleaning up existing processes"
killall -q picom dunst || true

# Wait for processes to end with timeout
for proc in picom dunst; do
    timeout=5
    while pgrep -u $UID -x "$proc" >/dev/null && [ $timeout -gt 0 ]; do
        sleep 0.1
        timeout=$((timeout - 1))
    done
done

# Start critical system services
log "Starting critical services"
nice -n 10 /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Start power management
run "xfce4-power-manager" xfce4-power-manager --no-daemon

# Start compositor
PICOM_CONFIG="$HOME/.config/picom/picom.conf"
if [ -f "$PICOM_CONFIG" ]; then
    run "picom" picom --config "$PICOM_CONFIG" --vsync --backend glx --unredir-if-possible --use-damage
else
    run "picom" picom --vsync --backend glx --unredir-if-possible --use-damage
fi

# Start system tray applications with progressive delays
for delay in 1 2 3; do
    case $delay in
        1) (sleep $delay && run "nm-applet" nm-applet) ;;
        2) (sleep $delay && run "blueman-applet" blueman-applet) ;;
        3) (sleep $delay && run "pamac-tray" pamac-tray) ;;
    esac & 
done

# Start user applications with different priorities
nice -n 15 run "numlockx" numlockx on
nice -n 10 run "dunst" dunst
nice -n 10 run "flameshot" flameshot
# nice -n 5 run "gammastep" gammastep -l 36.8:10.2

log "Autostart completed"

