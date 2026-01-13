#!/bin/bash
set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log() { printf "${BLUE}==>${NC} %s\n" "$1"; }
ok() { printf "${GREEN} [OK] ${NC} %s\n" "$1"; }
err() { printf "${RED} [FAIL] ${NC} %s\n" "$1"; }
warn() { printf "${YELLOW} [WARN] ${NC} %s\n" "$1"; }

log "Starting Niri Desktop Environment Health Check..."

# --- Check Core Binaries ---
check_bin() {
    local cmd=$1
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "Binary found: $cmd ($(command -v "$cmd"))"
    else
        err "Binary NOT found: $cmd"
        return 1
    fi
}

log "Checking core components..."
check_bin "niri"
check_bin "waybar"
check_bin "ghostty"
check_bin "rofi"
check_bin "hyprlock"
check_bin "fish"
check_bin "starship"
check_bin "satty"

# --- Check Symlinks ---
check_link() {
    local target=$1
    if [ -L "$target" ]; then
        ok "Link intact: $target -> $(readlink -f "$target")"
    elif [ -e "$target" ]; then
        warn "File exists but is NOT a symlink (manually placed?): $target"
    else
        err "Config missing: $target"
    fi
}

log "Checking configuration symlinks..."
check_link "${HOME}/.config/niri/config.kdl"
check_link "${HOME}/.config/waybar/config.jsonc"
check_link "${HOME}/.config/fish/config.fish"
check_link "${HOME}/.config/rofi/config.rasi"
check_link "${HOME}/.config/rofi/theme.rasi"

# --- Check Session File ---
SESSION_FILE="/usr/share/wayland-sessions/niri-custom.desktop"
if [ -f "$SESSION_FILE" ]; then
    ok "Session file found: $SESSION_FILE"
else
    warn "Custom session file NOT found at $SESSION_FILE. GDM/SDDM might not show Niri (Custom)."
fi

# --- User Shell ---
if [[ "$SHELL" == *"fish" ]]; then
    ok "Current shell is Fish"
else
    warn "Current shell is $SHELL (Expected Fish). Run 'chsh -s \$(which fish)' if intended."
fi

# --- Security & Performance ---
log "Checking security and performance..."
if systemctl is-active --quiet firewalld; then
    ok "Firewall (firewalld) is active"
else
    warn "Firewall (firewalld) is NOT active"
fi

if zramctl | grep -q "zram0"; then
    ok "Zram is active"
    zramctl
else
    warn "Zram is NOT active (requires reboot or manual start)"
fi

# --- GPU & Wayland ---
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    ok "Wayland session active: $WAYLAND_DISPLAY"
else
    warn "Not currently in a Wayland session (run this from within Niri to check GL)."
fi

log "Health check complete!"
