#!/bin/bash

DIR="$HOME/.config/polybar"

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
count=0
while pgrep -u $UID -x polybar >/dev/null; do 
    sleep 0.5
    count=$((count + 1))
    
    # Force kill after 5 seconds
    if [ $count -gt 10 ]; then
        killall -9 polybar
        break
    fi
done

# Clean up any leftover log files
rm -f /tmp/polybar_*.log

# Get the list of connected monitors
MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)

# If no monitors are connected, fall back to the default monitor
if [ -z "$MONITORS" ]; then
  MONITORS="eDP-1"
fi

# Launch polybar on each monitor
for m in $MONITORS; do
    export MONITOR=$m
    polybar -r top -c "$DIR/config.ini" -l info 2>&1 | tee -a /tmp/polybar_$m.log &
    export MONITOR=$m
    polybar -r bottom -c "$DIR/config.ini" -l info 2>&1 | tee -a /tmp/polybar_$m.log &
done
