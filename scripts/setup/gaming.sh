#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

log "Configuring system for gaming..."

# Enable Cisco OpenH264 for Steam media playback support
log "Enabling Cisco OpenH264..."
if dnf --version | grep -q "dnf5"; then
    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1 || true
else
    sudo dnf config-manager --set-enabled fedora-cisco-openh264 || true
fi

# Steam requires some tweaks for certain games
log "Applying Steam fixes..."

# Clear Steam Web Cache (one-time fix for black screens)
if [ -d ~/.steam/steam/config/htmlcache ] || [ -d ~/.steam/steam/config/overlayhtmlcache ]; then
    log "Clearing Steam web helper cache..."
    rm -rf ~/.steam/steam/config/htmlcache/* ~/.steam/steam/config/overlayhtmlcache/* 2>/dev/null || true
fi

# Patch Steam desktop entry for Wayland compatibility
log "Patching Steam desktop entry for Wayland..."
if [ -f "/usr/share/applications/steam.desktop" ]; then
    mkdir -p "$HOME/.local/share/applications"
    cp /usr/share/applications/steam.desktop "$HOME/.local/share/applications/steam.desktop"
    # Add -no-cef-sandbox flag to fix black screen on Wayland
    if grep -q "^Exec=/usr/bin/steam %U" "$HOME/.local/share/applications/steam.desktop"; then
        sed -i 's|^Exec=/usr/bin/steam %U|Exec=/usr/bin/steam -no-cef-sandbox %U|' "$HOME/.local/share/applications/steam.desktop"
        log "Steam desktop entry patched with -no-cef-sandbox flag"
    fi
fi

# Steam wrapper function uses -no-cef-sandbox for better Wayland compatibility
log "Verifying steam wrapper function..."
if [ -f "$HOME/.config/fish/functions/steam.fish" ]; then
    log "Steam wrapper function found."
else
    warn "steam.fish not found. Ensure dotfiles are properly stowed."
fi

# Optimize gamescope usage
log "Gamescope is installed. Recommended usage for tricky games:"
log "  gamescope -W 1920 -H 1080 -f -- %command%"

log "Checking for performance optimizations..."
if grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
    log "DNF is already optimized."
else
    warn "DNF parallel downloads not set. repos.sh should have handled this."
fi

log "Gaming setup complete. Please restart your shell/session to apply new settings."
