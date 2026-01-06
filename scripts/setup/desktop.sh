#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

SESSION_DIR="/usr/share/wayland-sessions"
LAUNCH_SCRIPT="${REPO_ROOT}/scripts/helpers/niri-launch.sh"

log "Installing Niri Custom Session..."

DESKTOP_FILE_CONTENT="[Desktop Entry]\nName=Niri (Custom)\nComment=Log in to Niri with custom environment\nExec=$(readlink -f "$LAUNCH_SCRIPT")\nType=Application\nDesktopNames=niri"
DEST_FILE="$SESSION_DIR/niri-custom.desktop"

# Create session directory if it doesn't exist
if [ ! -d "$SESSION_DIR" ]; then
    log "Creating session directory..."
    sudo mkdir -p "$SESSION_DIR"
fi

# Check if the file exists and content matches
if [ -f "$DEST_FILE" ] && [ "$(sudo cat "$DEST_FILE")" == "$DESKTOP_FILE_CONTENT" ]; then
    ok "Niri custom session is already up to date."
else
    echo -e "$DESKTOP_FILE_CONTENT" | sudo tee "$DEST_FILE" > /dev/null
    ok "Installed/updated session to $DEST_FILE"
fi

ok "Installed session to $SESSION_DIR/niri-custom.desktop"
