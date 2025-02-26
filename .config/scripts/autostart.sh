#!/bin/bash

# Improved process management function
function run {
  if ! pgrep -f "${1##*/}" >/dev/null; then
    if [ "$#" -gt 1 ]; then
      "$@" &
    else
      "$1" &
    fi
    # Add basic error checking with a loop
    local attempts=0
    while ! pgrep -f "${1##*/}" >/dev/null && [ $attempts -lt 5 ]; do
      sleep 1
      ((attempts++))
    done
    if ! pgrep -f "${1##*/}" >/dev/null; then
      notify-send -u normal "Startup Error" "Failed to start ${1##*/}"
    fi
  fi
}

# Performance settings with error handling
if command -v powerprofilesctl >/dev/null; then
  powerprofilesctl set performance ||
    notify-send -u normal "Power Profile" "Failed to set performance mode"
fi

# User applications with proper delays and error handling
(sleep 2 && {
  run discord --start-minimized
  sleep 1
  run slack -u
  sleep 1
  run thunderbird
}) &

