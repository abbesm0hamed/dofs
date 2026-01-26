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

mapfile -t package_files < <(find "${PACKAGES_DIR}" -maxdepth 1 -name "*.txt" ! -name "flatpak.txt" ! -name "copr.txt" -type f | sort)
if [ ${#package_files[@]} -gt 0 ]; then
    mapfile -t all_packages < <(
        awk 'NF && $1 !~ /^#/ { print $1 }' "${package_files[@]}" | sort -u
    )
else
    all_packages=()
fi

if [ ${#all_packages[@]} -gt 0 ]; then
    log "Final list to install: ${all_packages[*]}"
    DNF_FLAGS=("--allowerasing" "--skip-unavailable")
    # --best is not supported in DNF5
    if ! dnf --version | grep -q "dnf5"; then
        DNF_FLAGS+=("--best")
    fi
    sudo dnf install -y "${DNF_FLAGS[@]}" "${all_packages[@]}" 2>&1 | tee -a "$LOG_FILE" || warn "Some DNF packages failed to install. Check $LOG_FILE for details."
fi

# --- Flatpak Package Installation ---
log "Installing Flatpaks..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

if [ -f "${PACKAGES_DIR}/flatpak.txt" ]; then
    mapfile -t flatpak_packages < <(awk 'NF && $1 !~ /^#/ { print $1 }' "${PACKAGES_DIR}/flatpak.txt")
else
    flatpak_packages=()
fi

if [ ${#flatpak_packages[@]} -gt 0 ]; then
    flatpak install -y flathub "${flatpak_packages[@]}" 2>&1 | tee -a "$LOG_FILE" || warn "Some Flatpak packages failed to install."
fi