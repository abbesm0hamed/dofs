#!/bin/bash

DIR="$HOME/.config/polybar"

# Kill all polybar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Small delay to ensure all processes are terminated
sleep 1

# Get the list of connected monitors
MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)

# If no monitors are connected, fall back to the default monitor
if [ -z "$MONITORS" ]; then
  MONITORS="eDP-1"
fi

# Launch polybar on all connected monitors
for m in $MONITORS; do
  echo "Launching polybar on monitor: $m" >>"$HOME/.config/polybar/polybar.log"
  MONITOR=$m polybar -q -r top -c "$DIR"/config.ini >>"$HOME/.config/polybar/polybar.log" 2>&1 &
  MONITOR=$m polybar -q -r bottom -c "$DIR"/config.ini >>"$HOME/.config/polybar/polybar.log" 2>&1 &
done
