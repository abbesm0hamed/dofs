#!/bin/bash

DIR="$HOME/.config/polybar"

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do 
    sleep 0.1
    killall -q polybar  # Keep trying to kill if first attempt failed
done

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

echo "Polybar launched..."
