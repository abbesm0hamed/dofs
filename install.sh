#!/bin/bash
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
PACKAGES_DIR="${REPO_ROOT}/packages"
LOG_FILE="${HOME}/install.log"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { printf "${BLUE}==> %s${NC}\n" "$1"; }
success() { printf "${GREEN}==> %s${NC}\n" "$1"; }
error() { printf "${RED}==> ERROR: %s${NC}\n" "$1"; }

backup_path_if_conflict() {
    local path="$1"

    if [ -e "$path" ] && [ ! -L "$path" ]; then
        local backup="${path}.bak"
        if [ -e "$backup" ] || [ -L "$backup" ]; then
            backup="${path}.bak.$(date +%s)"
        fi

        log "Backing up existing file to avoid stow conflict: $path → $backup"
        mv "$path" "$backup"
    fi
}

# 0. Pre-flight checks
if [ -f "${REPO_ROOT}/scripts/preflight-check.sh" ]; then
    log "Running pre-flight checks..."
    bash "${REPO_ROOT}/scripts/preflight-check.sh" 2>&1 | tee -a "$LOG_FILE"
fi

# Cache sudo credentials once, then keep them alive for the duration of the script
log "Caching sudo credentials (you may be prompted once)..."
sudo -v
(
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit 0
    done
) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# 1. Ensure yay is installed
if ! command -v yay &> /dev/null; then
    log "Installing yay..."
    sudo pacman -Syu --needed --noconfirm git base-devel
    TMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TMP_DIR/yay"
    pushd "$TMP_DIR/yay" > /dev/null
    makepkg -si --noconfirm
    popd > /dev/null
    rm -rf "$TMP_DIR"
fi

# 2. Install all packages
log "Reading package lists..."
ALL_PACKAGES=()

# Read all .txt files in packages/ directory
while IFS= read -r package; do
    # Skip empty lines and comments
    package="${package%%#*}"
    package="$(printf '%s' "$package" | xargs)"
    [[ -z "$package" ]] && continue
    ALL_PACKAGES+=("$package")
done < <(cat "${PACKAGES_DIR}"/*.txt)

if [ ${#ALL_PACKAGES[@]} -gt 0 ]; then
    log "Installing ${#ALL_PACKAGES[@]} packages..."
    # Install everything in one go to avoid re-dependency checks
    yay -S --needed --noconfirm --answerclean None --answerdiff None "${ALL_PACKAGES[@]}" 2>&1 | tee -a "$LOG_FILE"
else
    success "No packages to install."
fi

# 3. Stow dotfiles
log "Stowing dotfiles..."

# Ensure target directories exist (stow handling descent)
mkdir -p "${HOME}/.config" \
         "${HOME}/.config/autostart" \
         "${HOME}/.config/fish"

# Avoid stow conflicts with known pre-existing files from CachyOS / previous setups
backup_path_if_conflict "${HOME}/.config/autostart/cachyos-hello.desktop"
backup_path_if_conflict "${HOME}/.config/autostart/cachyos-hello"
backup_path_if_conflict "${HOME}/.config/fish/fish_variables"
backup_path_if_conflict "${HOME}/.config/fish/config.fish"
backup_path_if_conflict "${HOME}/.config/fish/fish.config"

# Stow from the repo root to home
# We ignored scripts/ and packages/ in .stow_local_ignore
cd "${REPO_ROOT}" || exit 1

stow -v -t "${HOME}" --restow . 2>&1 | tee -a "$LOG_FILE"

# 4. Security Setup (PAM)
log "Configuring security (Fingerprint/U2F)..."
if [ -f "${REPO_ROOT}/scripts/configure-pam.sh" ]; then
    sudo bash "${REPO_ROOT}/scripts/configure-pam.sh"
fi

# 5. System Setup (Display Manager)
log "Setting up Display Manager session..."
bash "${REPO_ROOT}/scripts/setup-display-manager.sh"

# 6. Apply Default Theme
log "Applying default theme (default )..."
bash "${REPO_ROOT}/scripts/theme-manager.sh" set default

# 7. Post-install verification
if [ -f "${REPO_ROOT}/scripts/verify-installation.sh" ]; then
    log "Running post-install verification..."
    bash "${REPO_ROOT}/scripts/verify-installation.sh" 2>&1 | tee -a "$LOG_FILE"
fi

success "Installation complete!"
log "Please log out and log back in (or reboot) for all changes to take effect."
