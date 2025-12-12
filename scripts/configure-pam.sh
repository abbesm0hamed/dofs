#!/bin/bash
# scripts/configure-pam.sh
# Configures PAM for Fingerprint (fprintd) and FIDO2 (pam_u2f) authentication

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[PAM-SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[PAM-SETUP] Warning:${NC} $1"; }
error() { echo -e "${RED}[PAM-SETUP] Error:${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
    exit 1
fi

# 1. Configure Fingerprint for Login (system-local-login)
# Arch defaults usually require adding pam_fprintd.so to system-local-login
PAM_LOGIN="/etc/pam.d/system-local-login"
if [ -f "$PAM_LOGIN" ]; then
    if ! grep -q "pam_fprintd.so" "$PAM_LOGIN"; then
        log "Enabling fingerprint for local login..."
        # Backup
        cp "$PAM_LOGIN" "${PAM_LOGIN}.bak"
        # Insert pam_fprintd.so as sufficient at the top of auth stack
        sed -i '0,/^auth/s//auth      sufficient  pam_fprintd.so\nauth/' "$PAM_LOGIN"
        log "Updated $PAM_LOGIN"
    else
        log "Fingerprint already configured in $PAM_LOGIN"
    fi
else
    warn "$PAM_LOGIN not found, skipping local login fingerprint setup"
fi

# 2. Configure Fingerprint & U2F for Sudo
PAM_SUDO="/etc/pam.d/sudo"
if [ -f "$PAM_SUDO" ]; then
    CHANGED=0
    
    # Fingerprint
    if ! grep -q "pam_fprintd.so" "$PAM_SUDO"; then
        log "Enabling fingerprint for sudo..."
        # Backup if not already backed up by previous step
        [ ! -f "${PAM_SUDO}.bak" ] && cp "$PAM_SUDO" "${PAM_SUDO}.bak"
        
        # Insert pam_fprintd.so as sufficient
        sed -i '0,/^auth/s//auth      sufficient  pam_fprintd.so\nauth/' "$PAM_SUDO"
        CHANGED=1
    fi

    # U2F / FIDO2
    if ! grep -q "pam_u2f.so" "$PAM_SUDO"; then
        log "Enabling FIDO2 (U2F) for sudo..."
        [ ! -f "${PAM_SUDO}.bak" ] && cp "$PAM_SUDO" "${PAM_SUDO}.bak"
        
        # Insert pam_u2f.so as sufficient (after fprintd if it exists, or at top)
        # We'll just put it at the top as well, order allows either one
        sed -i '0,/^auth/s//auth      sufficient  pam_u2f.so cue\nauth/' "$PAM_SUDO"
        CHANGED=1
    fi
    
    if [ $CHANGED -eq 1 ]; then
        log "Updated $PAM_SUDO"
    else
        log "Sudo already configured for Fingerprint/U2F"
    fi
else
    warn "$PAM_SUDO not found, skipping sudo security setup"
fi

log "PAM configuration complete."
