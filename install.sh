#!/bin/bash
set -euo pipefail

# Configuration
export REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PACKAGES_DIR="${REPO_ROOT}/packages"
export LOG_FILE="${REPO_ROOT}/install.log"

log() { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m==> %s\033[0m\n" "$1"; }
success() { printf "\033[1;32m==> %s\033[0m\n" "$1"; }

# Elevate
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Execution
log "STARTING INSTALLATION (logging to $LOG_FILE)"
echo "--- Installation started at $(date) ---" >> "$LOG_FILE"

SETUP_SCRIPTS=(
    "repos.sh"
    "packages.sh"
    "languages.sh"
    "apps.sh"
    "dotfiles.sh"
    "performance.sh"
    "security.sh"
    "flatpak-theme.sh"
    "desktop.sh"
    "power.sh"
    "shell.sh"
    "install_broadcom_driver.sh"
    "finish.sh"
    "verify.sh"
)

for script_name in "${SETUP_SCRIPTS[@]}"; do
    # Special handling for conditional scripts
    if [[ "$script_name" == "install_broadcom_driver.sh" ]]; then
        # Check for Broadcom 58200 hardware before running the script
        if lsusb | grep -q "0a5c:5865"; then
            log "Broadcom 58200 fingerprint sensor detected. Installing driver..."
        else
            log "Broadcom 58200 fingerprint sensor not found. Skipping driver installation."
            continue
        fi
    fi

    script="${REPO_ROOT}/scripts/setup/${script_name}"
    title=$(echo "$script_name" | cut -f 1 -d '.' | tr 'a-z' 'A-Z')
    log "TOPIC: $title"
    if bash "$script" 2>&1 | tee -a "$LOG_FILE"; then
        success "DONE: $title"
    else
        warn "FAILED: $title (check $LOG_FILE for details)"
    fi
done

success "INSTALLATION COMPLETE"
log "Please log out and back in to apply shell changes."
