#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

# Dynamically determine the correct COPR chroot
FEDORA_VERSION=$(grep -oP '(?<=VERSION_ID=)[0-9]+' /etc/os-release)
ARCH=$(uname -m)
COPR_CHROOT="fedora-${FEDORA_VERSION}-${ARCH}"

enable_copr() {
    local repo="$1"
    log "Enabling COPR: $repo..."
    if ! sudo dnf copr enable -y "$repo" "$COPR_CHROOT"; then
        warn "Failed to enable COPR repository: $repo. It may not be available for your system version."
    fi
}

log "Optimizing DNF..."
if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf 2>/dev/null; then
    echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
    echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
fi

log "Configuring repositories..."

# List of COPRs to enable
COPR_REPOS=(
    "alternateved/ghostty"
    "che/nerd-fonts"
    "peterwu/iosevka"
    "dejan/lazygit"
    "yalter/niri"
    "grahamwhiteuk/libfprint-tod"
    "solopasha/hyprland", # for hyprpaper
    "varlad/yazi"
)

for repo in "${COPR_REPOS[@]}"; do
    enable_copr "$repo"
done

log "Adding Windsurf repository..."
sudo rpm --import https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf
echo -e "[windsurf]\nname=Windsurf Repository\nbaseurl=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/repo/\nenabled=1\nautorefresh=1\ngpgcheck=1\ngpgkey=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf" | sudo tee /etc/yum.repos.d/windsurf.repo >/dev/null

log "Adding Antigravity repository..."
sudo tee /etc/yum.repos.d/antigravity.repo >/dev/null <<'EOL'
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOL

sudo dnf makecache
