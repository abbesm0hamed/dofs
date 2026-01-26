#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

CONFIG_SRC="${REPO_ROOT}/etc/systemd/logind.conf.d/override.conf"
CONFIG_DEST="/etc/systemd/logind.conf.d/99-dofs-override.conf"

log "Configuring systemd-logind power management..."

if [ -f "$CONFIG_SRC" ]; then
    if [ -f "$CONFIG_DEST" ] && cmp -s "$CONFIG_SRC" "$CONFIG_DEST"; then
        ok "Power management configuration is already up to date."
    else
        sudo mkdir -p "$(dirname "$CONFIG_DEST")"
        sudo cp "$CONFIG_SRC" "$CONFIG_DEST"
        sudo chmod 644 "$CONFIG_DEST"
        ok "Power management configuration deployed to $CONFIG_DEST (Requires absolute reboot to apply safely)"
    fi
else
    warn "Power management template not found at $CONFIG_SRC"
fi
