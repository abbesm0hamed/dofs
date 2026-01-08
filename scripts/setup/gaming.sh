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
# Symlink custom udev rules
UDEV_RULES_DIR="/etc/udev/rules.d"
if [ -f "$HOME/.config/udev-rules/60-controller-support.rules" ]; then
    log "Enabling custom controller udev rules..."
    sudo ln -sf "$HOME/.config/udev-rules/60-controller-support.rules" "$UDEV_RULES_DIR/60-controller-support.rules"
    sudo udevadm control --reload-rules && sudo udevadm trigger
fi

# Clear Steam Web Cache (Fix for black screens)
log "Clearing Steam web helper cache..."
rm -rf ~/.steam/steam/config/htmlcache/* ~/.steam/steam/config/overlayhtmlcache/* || true

# Ensure gaming environment variables are set in fish
FISH_CONF_DIR="$HOME/.config/fish/conf.d"
if [ ! -d "$FISH_CONF_DIR" ]; then
    mkdir -p "$FISH_CONF_DIR"
fi

log "Ensuring gaming environment variables are configured..."

# Stability Enforcements:
log "Enforcing gaming stability settings..."

# Force XWayland for Steam/Proton (implemented in conf.d/gaming.fish)
log "Ensuring steam-stable function is available..."
if [ ! -f "$HOME/.config/fish/functions/steam-stable.fish" ]; then
    warn "steam-stable.fish missing in functions dir. Dotfiles stow should handle this."
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
