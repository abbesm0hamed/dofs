#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

SESSION_DIR="/usr/share/wayland-sessions"
LAUNCH_SCRIPT="${REPO_ROOT}/scripts/helpers/niri-launch.sh"

log "Installing Niri Custom Session..."

# Create a temporary desktop file
cat <<EOF > /tmp/niri-custom.desktop
[Desktop Entry]
Name=Niri (Custom)
Comment=Log in to Niri with custom environment
Exec=$(readlink -f "$LAUNCH_SCRIPT")
Type=Application
DesktopNames=niri
EOF

if [ ! -d "$SESSION_DIR" ]; then
    log "Creating session directory..."
    sudo mkdir -p "$SESSION_DIR"
fi

sudo cp /tmp/niri-custom.desktop "$SESSION_DIR/niri-custom.desktop"
rm /tmp/niri-custom.desktop

ok "Installed session to $SESSION_DIR/niri-custom.desktop"
