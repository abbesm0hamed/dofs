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
# Add any specific Steam environment variables or tweaks here if needed

# Gaming peripherals support
log "Configuring gaming peripherals support..."
# Piper and Solaar might need udev rules, but they are usually handled by packages in Fedora

# Stability Enforcements:
log "Enforcing gaming stability settings..."

# 1. Force XWayland for Steam/Proton (implemented in shell config via PROTON_ENABLE_WAYLAND=0)
# 2. Add helpful gaming aliases to fish config if not present
if fish -c "functions -q steam-stable" ; then
    log "steam-stable function already exists."
else
    log "Adding steam-stable function to fish config..."
    fish -c "function steam-stable; gamescope -W 1920 -H 1080 -f -- steam; end; funcsave steam-stable"
fi

# 3. Optimize gamescope usage
log "Gamescope is installed. Recommended usage for tricky games:"
log "  gamescope -W 1920 -H 1080 -f -- %command%"

log "Checking for performance optimizations..."
if grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
    log "DNF is already optimized."
else
    warn "DNF parallel downloads not set. repos.sh should have handled this."
fi

log "Gaming setup complete. Please restart your shell/session to apply new settings."
