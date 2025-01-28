#!/bin/bash

# Configuration
LOG_FILE="/tmp/monitor-setup.log"
INTERNAL_DISPLAY="eDP-1"
EXTERNAL_DISPLAY="HDMI-1-0"
PRIMARY_RESOLUTION="1920x1080"
PRIMARY_REFRESH="170"

# Ensure script isn't running multiple times simultaneously
LOCK_FILE="/tmp/monitor-setup.lock"
if [ -e "$LOCK_FILE" ]; then
  if kill -0 $(cat "$LOCK_FILE") 2>/dev/null; then
    exit 1
  fi
fi
echo $$ >"$LOCK_FILE"

# Logging function with timestamps
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Function to cleanup lock file
cleanup() {
  rm -f "$LOCK_FILE"
}
trap cleanup EXIT

# Function to ensure X server is ready
wait_for_x() {
  for i in {1..30}; do
    if DISPLAY=:0 XAUTHORITY="$HOME/.Xauthority" xrandr >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

# Function to detect displays
detect_displays() {
  if DISPLAY=:0 xrandr | grep "$EXTERNAL_DISPLAY connected" >/dev/null; then
    echo "external"
  else
    echo "internal"
  fi
}

# Function to get current primary display
get_current_primary() {
  DISPLAY=:0 xrandr | grep "primary" | cut -d" " -f1
}

# Function to handle workspace and window management
manage_workspaces() {
  local target_output=$1
  local current_primary=$(get_current_primary)

  if [ "$current_primary" != "$target_output" ]; then
    log "Changing primary display from $current_primary to $target_output"

    # Get current workspace and focused window
    local current_workspace=$(DISPLAY=:0 i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' -r)
    local focused_window=$(DISPLAY=:0 i3-msg -t get_tree | jq '.. | select(.focused? == true).id')

    # Set new primary display
    DISPLAY=:0 xrandr --output "$target_output" --primary || log "Failed to set primary display"

    # Move workspaces to new output
    for i in {1..10}; do
      DISPLAY=:0 i3-msg "workspace $i; move workspace to output $target_output" || log "Failed to move workspace $i"
      sleep 0.1
    done

    # Restore focus
    DISPLAY=:0 i3-msg "workspace $current_workspace" || log "Failed to return to workspace $current_workspace"
    if [ ! -z "$focused_window" ]; then
      DISPLAY=:0 i3-msg "[id=$focused_window] focus" || log "Failed to refocus window"
    fi
  fi
}

# Function to configure displays
configure_displays() {
  local display_mode=$1

  if [ "$display_mode" = "external" ]; then
    log "Setting up dual display mode"
    DISPLAY=:0 xrandr --output "$EXTERNAL_DISPLAY" --mode "$PRIMARY_RESOLUTION" --rate "$PRIMARY_REFRESH" --pos 1920x0 \
      --output "$INTERNAL_DISPLAY" --mode "$PRIMARY_RESOLUTION" --pos 0x0 ||
      log "Failed to configure dual display mode"
    manage_workspaces "$EXTERNAL_DISPLAY"
  else
    log "Setting up internal display mode"
    DISPLAY=:0 xrandr --output "$INTERNAL_DISPLAY" --mode "$PRIMARY_RESOLUTION" --pos 0x0 \
      --output "$EXTERNAL_DISPLAY" --off ||
      log "Failed to configure internal display mode"
    manage_workspaces "$INTERNAL_DISPLAY"
  fi

  # Restart polybar after display configuration
  pkill polybar
  sleep 1
  $HOME/.config/polybar/launch_polybar.sh
}

# Main execution
main() {
  log "Starting monitor configuration"

  # Ensure X server is ready
  if ! wait_for_x; then
    log "Error: X server not ready"
    exit 1
  fi

  # Detect and configure displays
  display_mode=$(detect_displays)
  configure_displays "$display_mode"
  log "Monitor configuration completed"
}

main
