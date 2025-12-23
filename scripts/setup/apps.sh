#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

log "Setting up Starship..."
if ! command -v starship &>/dev/null; then
    log "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    ok "Starship installed"
else
    ok "Starship checked"
fi

# Pokemon Colorscripts
log "Setting up pokemon-colorscripts..."
if ! command -v pokemon-colorscripts &>/dev/null; then
    log "Installing pokemon-colorscripts..."
    tmp_dir=$(mktemp -d)
    git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$tmp_dir"
    pushd "$tmp_dir" >/dev/null
    sudo ./install.sh
    popd >/dev/null
    rm -rf "$tmp_dir"
    ok "pokemon-colorscripts installed"
else
    ok "pokemon-colorscripts checked"
fi

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
