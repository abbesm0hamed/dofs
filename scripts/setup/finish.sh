#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }

log "Refreshing font cache..."
fc-cache -fv >/dev/null 2>&1

log "Setting Zen Browser as default..."
if command -v xdg-settings >/dev/null && flatpak info app.zen_browser.zen >/dev/null 2>&1; then
    xdg-settings set default-web-browser app.zen_browser.zen.desktop
    log "Default browser set to Zen."
fi
