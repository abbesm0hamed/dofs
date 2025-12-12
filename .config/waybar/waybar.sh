#!/bin/bash
if pidof waybar >/dev/null; then
  killall waybar
  # Wait for processes to actually terminate
  while pidof waybar >/dev/null; do
    sleep 0.1
  done
  sleep 0.2
else
  sleep 0.5
  waybar &
fi
