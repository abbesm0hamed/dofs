#!/bin/bash

# Function to get and display the current volume or mute status
get_volume_status() {
  local volume
  local mute_status
  volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+%' | head -1)
  mute_status=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -Po '(yes|no)')

  if [ "$mute_status" = "yes" ]; then
    echo "󰖁 Muted"
  else
    echo "󰕾 $volume"
  fi
}

# Ensure the command line argument is passed
if [ -z "$1" ]; then
  get_volume_status
  exit 0
fi

# Get the current volume and ensure it doesn't exceed 100%
current_volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+%' | head -1 | tr -d '%')

# Set the volume limit to 100%
if [ "$current_volume" -gt 100 ]; then
  pactl set-sink-volume @DEFAULT_SINK@ 100%
fi

# Perform the action
case $1 in
up)
  pactl set-sink-volume @DEFAULT_SINK@ +5%
  ;;
down)
  pactl set-sink-volume @DEFAULT_SINK@ -5%
  ;;
mute)
  pactl set-sink-mute @DEFAULT_SINK@ toggle
  ;;
open)
  pavucontrol &
  exit 0
  ;;
*)
  echo "Invalid action. Use up, down, mute, or open."
  exit 1
  ;;
esac

# Display the new volume status after the action
get_volume_status
