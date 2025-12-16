#!/bin/bash
set -euo pipefail

log_step() { printf "[portals] %s\n" "$1"; }
log_warn() { printf "[portals][warn] %s\n" "$1"; }

ensure_user_service() {
    local unit="$1"
    if systemctl --user enable --now "$unit" >/dev/null 2>&1; then
        log_step "Enabled and started user service: $unit"
    else
        # If --now failed (often because no user session dbus), still enable
        if systemctl --user enable "$unit" >/dev/null 2>&1; then
            log_warn "Enabled $unit but could not start it now (no user session?). It will start on next login."
        else
            log_warn "Failed to enable $unit (not installed or systemd --user unavailable)."
        fi
    fi
}

# Ensure user systemd session is reachable
if ! systemctl --user show-environment >/dev/null 2>&1; then
    log_warn "systemd --user not reachable; portal services will be enabled but not started."
fi

# Enable portal backend first, then main portal
ensure_user_service "xdg-desktop-portal-wlr.service"
ensure_user_service "xdg-desktop-portal.service"

# Restart main portal if possible to pick up backend preference
if systemctl --user restart xdg-desktop-portal.service >/dev/null 2>&1; then
    log_step "Restarted xdg-desktop-portal.service"
fi

log_step "Portal setup finished"
