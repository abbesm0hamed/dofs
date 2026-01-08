#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

log "Starting complete system update..."

# Elevate
sudo -v

# DNF Upgrade
log "Checking for system updates (DNF)..."
sudo dnf upgrade --refresh -y

# Flatpak Update
log "Checking for Flatpak updates..."
if command -v flatpak &>/dev/null; then
    flatpak update -y
    flatpak uninstall --unused -y
fi

# Fish Shell Update
log "Updating Fish plugins..."
if command -v fisher &>/dev/null; then
    fish -c "fisher update"
fi
fish -c "fish_update_completions"

# Neovim Plugins
log "Updating Neovim plugins..."
if command -v nvim &>/dev/null; then
    nvim --headless "+Lazy! sync" +qa
fi

# Rust/Cargo (if present)
if command -v cargo-install-update &>/dev/null; then
    log "Updating Cargo packages..."
    cargo install-update -a
fi

# Cleaning Up
log "Cleaning up old caches..."
sudo dnf autoremove -y
sudo dnf clean all

# Notify Waybar if it's running (to refresh update indicator)
if pgrep -x waybar >/dev/null; then
    rm -f /tmp/dnf_updates_cache
    pkill -RTMIN+9 waybar
fi

ok "System update complete!"
