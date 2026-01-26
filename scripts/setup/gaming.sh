#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

log "Configuring system for gaming..."
log "Applying Steam fixes..."

if [ -d ~/.steam/steam/config/htmlcache ] || [ -d ~/.steam/steam/config/overlayhtmlcache ]; then
    log "Clearing Steam cache..."
    rm -rf ~/.steam/steam/config/htmlcache/* ~/.steam/steam/config/overlayhtmlcache/* 2>/dev/null || true
fi

log "Patching Steam desktop entry..."
if [ -f "/usr/share/applications/steam.desktop" ]; then
    mkdir -p "$HOME/.local/share/applications"
    cp /usr/share/applications/steam.desktop "$HOME/.local/share/applications/steam.desktop"
    if grep -q "^Exec=/usr/bin/steam %U" "$HOME/.local/share/applications/steam.desktop"; then
        sed -i 's|^Exec=/usr/bin/steam %U|Exec=/usr/bin/steam -system-composer -no-cef-sandbox %U|' "$HOME/.local/share/applications/steam.desktop"
        log "Steam patched with necessary flags"
    fi
fi

log "Verifying steam wrapper..."
if [ -f "$HOME/.config/fish/functions/steam.fish" ]; then
    log "Steam wrapper function found."
else
    warn "steam.fish not found. Ensure dotfiles are properly linked."
fi

log "Gaming setup complete. Restart session to apply."
