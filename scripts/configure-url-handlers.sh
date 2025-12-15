#!/bin/bash

set -euo pipefail

log() { printf "==> %s\n" "$1"; }
warn() { printf "==> WARN: %s\n" "$1"; }

detected_default="$(xdg-settings get default-web-browser 2>/dev/null || true)"
if [[ -n "${BROWSER_DESKTOP:-}" ]]; then
    BROWSER_DESKTOP="$BROWSER_DESKTOP"
elif [[ "${USE_SYSTEM_DEFAULT:-0}" == "1" && -n "$detected_default" && "$detected_default" != "default" ]]; then
    BROWSER_DESKTOP="$detected_default"
else
    BROWSER_DESKTOP="zen.desktop"
fi

SCHEME_HANDLER="${CUSTOM_SCHEME_HANDLER:-$BROWSER_DESKTOP}"
CUSTOM_SCHEMES="${CUSTOM_SCHEMES:-}"

log "Setting default web browser handler to: $BROWSER_DESKTOP"
if ! xdg-settings set default-web-browser "$BROWSER_DESKTOP"; then
    warn "xdg-settings failed; ensure $BROWSER_DESKTOP is installed and exported."
fi

log "Setting xdg-mime handlers for http/https..."
for scheme in http https; do
    if ! xdg-mime default "$BROWSER_DESKTOP" "x-scheme-handler/${scheme}"; then
        warn "Failed to set handler for ${scheme}"
    fi
done

if [[ -n "$CUSTOM_SCHEMES" ]]; then
    for scheme in $CUSTOM_SCHEMES; do
        log "Setting handler for custom scheme: $scheme -> $SCHEME_HANDLER"
        if ! xdg-mime default "$SCHEME_HANDLER" "x-scheme-handler/${scheme}"; then
            warn "Failed to set handler for ${scheme}"
        fi
    done
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user restart xdg-desktop-portal{,-wlr,-gnome}.service 2>/dev/null || true
fi

log "URL handler configuration complete."