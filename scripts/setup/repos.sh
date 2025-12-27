#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }

COPR_CHROOT="fedora-41-x86_64"

enable_copr() {
    local repo="$1"
    log "Enabling COPR: $repo..."
    sudo dnf copr enable -y "$repo" || sudo dnf copr enable -y "$repo" "$COPR_CHROOT" >> "$LOG_FILE" 2>&1
}

log "Configuring repositories..."
enable_copr "alternateved/ghostty"
enable_copr "che/nerd-fonts"
enable_copr "peterwu/iosevka"
enable_copr "dejan/lazygit"
enable_copr "yalter/niri"
enable_copr "grahamwhiteuk/libfprint-tod"

log "Adding Windsurf repository..."
sudo rpm --import https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf
echo -e "[windsurf]\nname=Windsurf Repository\nbaseurl=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/repo/\nenabled=1\nautorefresh=1\ngpgcheck=1\ngpgkey=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf" | sudo tee /etc/yum.repos.d/windsurf.repo >/dev/null
