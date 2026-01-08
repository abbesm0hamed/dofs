#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

# Dynamically determine the correct COPR chroot
FEDORA_VERSION=$(grep -oP '(?<=VERSION_ID=)[0-9]+' /etc/os-release)
ARCH=$(uname -m)
COPR_CHROOT="fedora-${FEDORA_VERSION}-${ARCH}"

enable_copr() {
    local repo_name=$(echo "$1" | sed 's|/|-|')
    if [ -f "/etc/yum.repos.d/_copr_${repo_name}.repo" ]; then
        log "COPR repository $1 is already enabled."
        return 0
    fi

    log "Enabling COPR: $1..."
    if ! sudo dnf copr enable -y "$1" "$COPR_CHROOT"; then
        warn "Failed to enable COPR repository: $1. It may not be available for your system version."
        return 1
    fi
    return 0
}

log "Optimizing DNF..."
if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf 2>/dev/null; then
    echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
    echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
fi

log "Configuring repositories..."

# Read COPR repositories from file
COPR_FILE="${REPO_ROOT}/packages/copr.txt"
repos_changed=false

if [ -f "$COPR_FILE" ]; then
    while IFS= read -r repo; do
        repo="${repo%%#*}" # Remove comments
        repo="$(echo "$repo" | xargs)" # Trim whitespace
        if [[ -n "$repo" ]]; then
            if enable_copr "$repo"; then
                repos_changed=true
            fi
        fi
    done < "$COPR_FILE"
else
    warn "COPR file not found at $COPR_FILE"
fi

if [ "$repos_changed" = true ]; then
    log "Updating dnf cache..."
    sudo dnf makecache
else
    log "No repository changes, skipping dnf makecache."
fi

log "Enabling RPM Fusion repositories..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

log "Enabling Cisco OpenH264..."
if dnf --version | grep -q "dnf5"; then
    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1 || true
else
    sudo dnf config-manager --set-enabled fedora-cisco-openh264 || true
fi
