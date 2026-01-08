#!/bin/bash

# Session Health Doctor for Niri/Wayland
# Usage: doctor.sh

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() { printf "${BLUE}==>${NC} %s\n" "$1"; }
ok() { printf "${GREEN} [PASS] ${NC} %s\n" "$1"; }
err() { printf "${RED} [FAIL] ${NC} %s\n" "$1"; }
warn() { printf "${YELLOW} [WARN] ${NC} %s\n" "$1"; }

log "Running Session Health Diagnostics..."

# Check Display Server
if [ -n "$WAYLAND_DISPLAY" ]; then
    ok "Wayland Display active ($WAYLAND_DISPLAY)"
else
    err "No Wayland Display found!"
fi

# Check Composer
if pgrep -x niri >/dev/null; then
    ok "Niri composer is running"
else
    err "Niri composer is NOT running!"
fi

# Check XDG Desktop Portals (CRITICAL for apps)
check_portal() {
    if pgrep -f "$1" >/dev/null; then
        ok "Portal active: $1"
    else
        warn "Portal NOT found: $1 (Apps may hang or fail to open files)"
    fi
}

log "Checking Portals..."
check_portal "xdg-desktop-portal"
check_portal "xdg-desktop-portal-gnome"
check_portal "xdg-desktop-portal-gtk"

# Check Polkit (CRITICAL for sudo apps)
if pgrep -f "polkit-gnome-authentication-agent-1" >/dev/null; then
    ok "Polkit agent is running"
else
    err "Polkit agent NOT found! (Graphical sudo will fail)"
fi

# Check UI Elements
check_service() {
    if pgrep -x "$1" >/dev/null; then
        ok "Service active: $1"
    else
        warn "Service NOT running: $1"
    fi
}

log "Checking UI Services..."
check_service "waybar"
check_service "mako"
check_service "swayidle"
check_service "hyprpaper"

# Check DBus session
if dbus-send --session --dest=org.freedesktop.DBus --type=method_call /org/freedesktop/DBus org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
    ok "DBus session responds"
else
    err "DBus session is NOT responding!"
fi

# Check for critical symlinks
log "Checking for critical symlinks..."
check_symlink() {
    local link_path="$1"
    local target_should_contain="$2"
    if [ -L "$link_path" ]; then
        local target=$(readlink "$link_path")
        if [[ "$target" == *"$target_should_contain"* ]]; then
            ok "Symlink valid: $link_path"
        else
            err "Symlink invalid: $link_path points to '$target', expected it to contain '$target_should_contain'"
        fi
    else
        err "Symlink NOT found: $link_path"
    fi
}
check_symlink "$HOME/.config/nvim" "dofs/home/.config/nvim"
check_symlink "$HOME/.local/bin/dofs" "dofs/dofs"

# Check for system services
log "Checking for system services..."
check_system_service() {
    if systemctl is-active --quiet "$1"; then
        ok "System service active: $1"
    else
        warn "System service NOT active: $1"
    fi
}
check_system_service "docker"
check_system_service "libvirtd"

# Check PATH configuration
log "Checking PATH configuration..."
check_path() {
    local dir_to_check="$1"
    if [[ ":$PATH:" == *":$dir_to_check:"* ]]; then
        ok "PATH contains: $dir_to_check"
    else
        warn "PATH does NOT contain: $dir_to_check"
    fi
}
check_path "$HOME/.local/bin"
check_path "$HOME/.cargo/bin"
check_path "$HOME/.local/share/fnm"
check_path "$HOME/.bun/bin"

log "Diagnostics complete!"
