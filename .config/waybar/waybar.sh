#!/bin/bash
if pgrep -x waybar >/dev/null 2>&1; then
  pkill -x waybar || true
  # Wait for processes to actually terminate
  while pgrep -x waybar >/dev/null 2>&1; do
    sleep 0.1
  done
  sleep 0.2
else
  sleep 0.5
  waybar &
fi
