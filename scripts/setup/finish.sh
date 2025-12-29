#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }

log "Refreshing font cache..."
fc-cache -fv >/dev/null 2>&1

log "Configuring fingerprint authentication..."
if command -v authselect >/dev/null 2>&1; then
    # Enable fingerprint feature if not already enabled
    if ! authselect current | grep -q "with-fingerprint"; then
        sudo authselect enable-feature with-fingerprint
        log "Fingerprint authentication enabled."
    fi

    # Fix GDM interference: Ensure failed fingerprint doesn't block password
    if [ -f /etc/pam.d/gdm-password ]; then
        if ! grep -q "pam_fprintd.so" /etc/pam.d/gdm-password; then
            # Insert pam_fprintd.so as optional to avoid blocking
            sudo sed -i '1s/^/auth [success=done default=ignore] pam_fprintd.so\n/' /etc/pam.d/gdm-password
            log "GDM fingerprint interference fixed."
        fi
    fi
fi

log "Setting Zen Browser as default..."
if command -v xdg-settings >/dev/null && flatpak info app.zen_browser.zen >/dev/null 2>&1; then
    xdg-settings set default-web-browser app.zen_browser.zen.desktop
    log "Default browser set to Zen."
fi

log "Optimizing PAM for swaylock..."
if [[ -f "${REPO_ROOT}/scripts/configs/swaylock.pam" ]]; then
    sudo cp "${REPO_ROOT}/scripts/configs/swaylock.pam" /etc/pam.d/swaylock
    sudo chmod 644 /etc/pam.d/swaylock
    log "Swaylock PAM configuration optimized."
fi
