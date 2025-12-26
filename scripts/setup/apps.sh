#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

log "Setting up Docker..."
if ! systemctl is-active --quiet docker; then
    if command -v docker &>/dev/null; then
        sudo systemctl enable --now docker 2>/dev/null || true
        ok "Docker enabled and started"
    else
        warn "Docker not found, skipping setup."
    fi
else
    ok "Docker already running"
fi
