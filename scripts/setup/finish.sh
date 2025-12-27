#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }

log "Refreshing font cache..."
fc-cache -fv >/dev/null 2>&1

log "Configuring fingerprint authentication..."
if command -v authselect >/dev/null 2>&1; then
    # Enable fingerprint feature if not already enabled
    if ! authselect current | grep -q "with-fingerprint"; then
        sudo authselect enable-feature with-fingerprint
        log "Fingerprint authentication enabled."
    else
        log "Fingerprint authentication already enabled."
    fi
fi

log "Setting Zen Browser as default..."
if command -v xdg-settings >/dev/null && flatpak info app.zen_browser.zen >/dev/null 2>&1; then
    xdg-settings set default-web-browser app.zen_browser.zen.desktop
    log "Default browser set to Zen."
fi
