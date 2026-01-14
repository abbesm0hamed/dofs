#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

# Ensure environment variables are set, default if not
: "${REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
: "${PACKAGES_DIR:=${REPO_ROOT}/packages}"
: "${LOG_FILE:=/dev/null}"

# --- DNF Package Installation ---
log "Installing DNF packages..."
RAW_PACKAGES=()
# Read all .txt files excluding flatpak.txt
while IFS= read -r package; do
    package="${package%%#*}" # Remove comments
    package="$(echo "$package" | xargs)" # Trim whitespace
    if [[ -n "$package" ]]; then
        RAW_PACKAGES+=("$package")
    fi
done < <(find "${PACKAGES_DIR}" -maxdepth 1 -name "*.txt" ! -name "flatpak.txt" ! -name "copr.txt" -type f -print0 | xargs -0 cat)

# Deduplicate packages
ALL_PACKAGES=($(echo "${RAW_PACKAGES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

if [ ${#ALL_PACKAGES[@]} -gt 0 ]; then
    log "Final list to install: ${ALL_PACKAGES[*]}"
    DNF_FLAGS=("--allowerasing" "--skip-unavailable")
    # --best is not supported in DNF5
    if ! dnf --version | grep -q "dnf5"; then
        DNF_FLAGS+=("--best")
    fi
    sudo dnf install -y "${DNF_FLAGS[@]}" "${ALL_PACKAGES[@]}" 2>&1 | tee -a "$LOG_FILE" || warn "Some DNF packages failed to install. Check $LOG_FILE for details."
fi

# --- Flatpak Package Installation ---
log "Installing Flatpaks..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

FLATPAK_PACKAGES=()
# Read flatpak.txt
if [ -f "${PACKAGES_DIR}/flatpak.txt" ]; then
    while IFS= read -r package; do
        package="${package%%#*}" # Remove comments
        package="$(echo "$package" | xargs)" # Trim whitespace
        if [[ -n "$package" ]]; then
            FLATPAK_PACKAGES+=("$package")
        fi
    done < "${PACKAGES_DIR}/flatpak.txt"
fi

if [ ${#FLATPAK_PACKAGES[@]} -gt 0 ]; then
    flatpak install -y flathub "${FLATPAK_PACKAGES[@]}" 2>&1 | tee -a "$LOG_FILE" || warn "Some Flatpak packages failed to install."
fi