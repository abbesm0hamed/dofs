#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

# Ensure environment variables are set, default if not
: "${REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
: "${PACKAGES_DIR:=${REPO_ROOT}/packages}"
: "${LOG_FILE:=/dev/null}"

read_packages_from_files() {
    local file_pattern="$1"
    local -n packages_array="$2" # Use a nameref for the output array

    while IFS= read -r package; do
        package="${package%%#*}" # Remove comments
        package="$(printf '%s' "$package" | xargs)" # Trim whitespace
        if [[ -n "$package" ]]; then
            packages_array+=("$package")
        fi
    done < <(find "$file_pattern" -type f -print0 | xargs -0 cat)
}

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
done < <(find "${PACKAGES_DIR}" -maxdepth 1 -name "*.txt" ! -name "flatpak.txt" -type f -print0 | xargs -0 cat)

# Deduplicate packages
ALL_PACKAGES=($(echo "${RAW_PACKAGES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

FEDORA_PACKAGES=()
for pkg in "${ALL_PACKAGES[@]}"; do
    case "$pkg" in
        "base-devel")   FEDORA_PACKAGES+=("@development-tools") ;;
        "github-cli")   FEDORA_PACKAGES+=("gh") ;;
        "imagemagick")  FEDORA_PACKAGES+=("ImageMagick") ;;
        "python-pip")   FEDORA_PACKAGES+=("python3-pip") ;;
        "qt5-wayland")  FEDORA_PACKAGES+=("qt5-qtwayland") ;;
        "qt6-wayland")  FEDORA_PACKAGES+=("qt6-qtwayland") ;;
        "libfprint-tod") FEDORA_PACKAGES+=("libfprint-tod") ;;
        "starship"|"fnm"|"bun") 
            log "Skipping '$pkg' (will be installed by language manager/shell script)."
            continue 
            ;;
        *) FEDORA_PACKAGES+=("$pkg") ;;
    esac
done

if [ ${#FEDORA_PACKAGES[@]} -gt 0 ]; then
    log "Final list to install: ${FEDORA_PACKAGES[*]}"
    sudo dnf install -y --allowerasing --skip-unavailable --best "${FEDORA_PACKAGES[@]}" 2>&1 | tee -a "$LOG_FILE" || warn "Some DNF packages failed to install. Check $LOG_FILE for details."
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

# --- Manual Binary Installations ---
log "Installing additional binaries..."

# Install lazydocker
if ! command -v lazydocker &> /dev/null; then
    log "Installing lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>&1 | tee -a "$LOG_FILE" || warn "lazydocker installation failed."
else
    log "lazydocker is already installed."
fi
