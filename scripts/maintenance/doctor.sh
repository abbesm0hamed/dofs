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

# 1. Check Display Server
if [ -n "$WAYLAND_DISPLAY" ]; then
    ok "Wayland Display active ($WAYLAND_DISPLAY)"
else
    err "No Wayland Display found!"
fi

# 2. Check Composer
if pgrep -x niri >/dev/null; then
    ok "Niri composer is running"
else
    err "Niri composer is NOT running!"
fi

# 3. Check XDG Desktop Portals (CRITICAL for apps)
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

# 4. Check Polkit (CRITICAL for sudo apps)
if pgrep -f "polkit-gnome-authentication-agent-1" >/dev/null; then
    ok "Polkit agent is running"
else
    err "Polkit agent NOT found! (Graphical sudo will fail)"
fi

# 5. Check UI Elements
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

# 6. Check DBus session
if dbus-send --session --dest=org.freedesktop.DBus --type=method_call /org/freedesktop/DBus org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
    ok "DBus session responds"
else
    err "DBus session is NOT responding!"
fi

log "Diagnostics complete!"
