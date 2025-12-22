#!/bin/bash
set -euo pipefail

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="${REPO_ROOT}/packages"
LOG_FILE="${REPO_ROOT}/install.log"
# Fallback chroot for Fedora Rawhide (43)
COPR_CHROOT="fedora-41-x86_64"

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
success() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

# Cache sudo credentials
if [ -t 0 ]; then
    log "Caching sudo credentials..."
    sudo -v
fi

# 1. Enable Third-Party Repos (COPR) with Fallback for Rawhide
enable_copr() {
    local repo="$1"
    log "Enabling COPR repository: $repo..."
    if ! sudo dnf copr enable -y "$repo" 2>>"$LOG_FILE"; then
        log "Default COPR failed. Trying with fallback chroot $COPR_CHROOT..."
        sudo dnf copr enable -y "$repo" "$COPR_CHROOT" 2>&1 | tee -a "$LOG_FILE"
    fi
}

# 3. Enable Required COPR Repositories
log "Enabling COPR repositories..."
enable_copr "alternateved/ghostty"
enable_copr "che/nerd-fonts"
enable_copr "peterwu/iosevka"
enable_copr "dejan/lazygit"
# Note: atarishi/starship often 404s on Rawhide; we'll use the official installer script below.

# 2. Add Windsurf Repository
log "Adding Windsurf repository..."
sudo rpm --import https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf
echo -e "[windsurf]\nname=Windsurf Repository\nbaseurl=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/repo/\nenabled=1\nautorefresh=1\ngpgcheck=1\ngpgkey=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf" | sudo tee /etc/yum.repos.d/windsurf.repo >/dev/null

# 3. Install Packages
log "Reading package lists..."
ALL_PACKAGES=()
while IFS= read -r package; do
    package="${package%%#*}"
    package="$(printf '%s' "$package" | xargs)"
    [[ -z "$package" ]] && continue
    ALL_PACKAGES+=("$package")
done < <(cat "${PACKAGES_DIR}"/*.txt)

if [ ${#ALL_PACKAGES[@]} -gt 0 ]; then
    log "Preparing packages for Fedora..."

    # Fedora-specific mapping
    FEDORA_PACKAGES=()
    for pkg in "${ALL_PACKAGES[@]}"; do
        case "$pkg" in
            "base-devel") FEDORA_PACKAGES+=("@development-tools") ;;
            "swaylock-effects") FEDORA_PACKAGES+=("swaylock") ;;
            "github-cli") FEDORA_PACKAGES+=("gh") ;;
            "imagemagick") FEDORA_PACKAGES+=("ImageMagick") ;;
            "python-pip") FEDORA_PACKAGES+=("python3-pip") ;;
            "qt5-wayland") FEDORA_PACKAGES+=("qt5-qtwayland") ;;
            "qt6-wayland") FEDORA_PACKAGES+=("qt6-qtwayland") ;;
            "ghostty") FEDORA_PACKAGES+=("ghostty") ;;
            "swww") FEDORA_PACKAGES+=("swww") ;;
            "starship") continue ;; # Handle via official script below
            "fnm") continue ;;      # Handle via official script below
            *) FEDORA_PACKAGES+=("$pkg") ;;
        esac
    done

    log "Installing main package batch..."
    # Using --allowerasing --skip-unavailable --best for maximum resilience
    if ! sudo dnf install -y --allowerasing --skip-unavailable --best "${FEDORA_PACKAGES[@]}" 2>&1 | tee -a "$LOG_FILE"; then
        warn "Main package batch encountered errors. Attempting to proceed with remaining steps."
    fi
else
    log "No packages found to install."
fi

# 5. Setup Docker
if command -v docker &>/dev/null; then
    log "Enabling and starting docker.service..."
    sudo systemctl enable --now docker 2>/dev/null || true
fi

# 5.1 Setup FNM (Fast Node Manager) from https://github.com/Schniz/fnm
if ! command -v fnm &>/dev/null; then
    log "fnm not found. Installing via official script..."
    # Using the exact recommended command from the repo
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell 2>&1 | tee -a "$LOG_FILE" || warn "fnm installation failed."
    # Ensure binary is accessible for the rest of the script if needed
    [ -d "$HOME/.local/share/fnm" ] && export PATH="$HOME/.local/share/fnm:$PATH"
fi

# 5.2 Setup Starship (Fall back to official script)
if ! command -v starship &>/dev/null; then
    log "Starship not found. Installing via official script..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y 2>&1 | tee -a "$LOG_FILE" || warn "Starship installation failed."
fi

# 5.3 Install Zen Browser via Flatpak
log "Installing Zen Browser via Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub app.zen_browser.zen 2>&1 | tee -a "$LOG_FILE" || warn "Zen Browser Flatpak installation failed."

# 6. Stow Dotfiles (Full Automation)
log "Stowing configurations..."
cd "${REPO_ROOT}"
# Ensure scripts are executable before stowing
[ -d ".config/niri/scripts" ] && chmod +x .config/niri/scripts/*
[ -d "scripts" ] && chmod +x scripts/*

mkdir -p "${HOME}/.config"

STOW_ITEMS=$(ls -A | grep -vE "^(\.git|scripts|packages|templates|install\.sh|install\.log|README\.md)$")

for item in $STOW_ITEMS; do
    if [ "$item" == ".config" ]; then
        for subitem in .config/*; do
            [ -e "$subitem" ] || continue
            target="${HOME}/${subitem}"
            if [ -e "$target" ] && [ ! -L "$target" ]; then
                log "Removing existing $target to prioritize your repo config..."
                rm -rf "$target"
            fi
        done
    else
        target="${HOME}/${item}"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            log "Removing existing $target..."
            rm -rf "$target"
        fi
    fi
done

# Restow recursively to ensure all symlinks are created correctly
stow -R -v -t "${HOME}" . 2>&1 | tee -a "$LOG_FILE" || warn "Stow encountered some issues."

# 7. Apply Theme
if [ -f "${REPO_ROOT}/scripts/theme-manager.sh" ]; then
    log "Applying default theme..."
    bash "${REPO_ROOT}/scripts/theme-manager.sh" set default 2>&1 | tee -a "$LOG_FILE"
fi

# 8. Refresh Font Cache
log "Refreshing font cache..."
fc-cache -fv 2>&1 | tee -a "$LOG_FILE"

# 9. Setup Shell
if [ -f "${REPO_ROOT}/scripts/setup-shell.sh" ]; then
    log "Setting up default shell..."
    bash "${REPO_ROOT}/scripts/setup-shell.sh" 2>&1 | tee -a "$LOG_FILE"
fi

success "Installation and configuration complete!"
warn "IMPORTANT: To use your new shell (fish), please log out and back in."
warn "If fonts still look broken, ensure 'nerd-fonts' package was installed correctly."
