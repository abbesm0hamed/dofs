#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

CONFIG_SRC="${REPO_ROOT}/etc/systemd/logind.conf.d/override.conf"
CONFIG_DEST="/etc/systemd/logind.conf.d/99-dofs-override.conf"

log "Configuring systemd-logind power management..."

if [ -f "$CONFIG_SRC" ]; then
    sudo mkdir -p "$(dirname "$CONFIG_DEST")"
    sudo cp "$CONFIG_SRC" "$CONFIG_DEST"
    sudo chmod 644 "$CONFIG_DEST"
    
    # IMPORTANT: We do NOT restart logind here to avoid immediate suspension.
    # The user is notified to reboot at the end of the installation.
    ok "Power management configuration deployed to $CONFIG_DEST (Requires absolute reboot to apply safely)"
else
    warn "Power management template not found at $CONFIG_SRC"
fi
