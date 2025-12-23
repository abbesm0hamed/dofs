#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

log "Installing packages..."
ALL_PACKAGES=()
while IFS= read -r package; do
    package="${package%%#*}"
    package="$(printf '%s' "$package" | xargs)"
    [[ -z "$package" ]] && continue
    ALL_PACKAGES+=("$package")
done < <(cat "${PACKAGES_DIR}"/*.txt)

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
        "starship"|"fnm"|"bun") continue ;;
        *) FEDORA_PACKAGES+=("$pkg") ;;
    esac
done

sudo dnf install -y --allowerasing --skip-unavailable --best "${FEDORA_PACKAGES[@]}" 2>&1 | tee -a "$LOG_FILE" || warn "Some DNF packages failed."

log "Installing Flatpaks..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

FLATPAK_PACKAGES=()
if [ -f "${PACKAGES_DIR}/flatpak.txt" ]; then
    while IFS= read -r package; do
        package="${package%%#*}" # remove comments
        package="$(printf '%s' "$package" | xargs)" # trim
        [[ -z "$package" ]] && continue
        FLATPAK_PACKAGES+=("$package")
    done < "${PACKAGES_DIR}/flatpak.txt"
fi

if [ ${#FLATPAK_PACKAGES[@]} -gt 0 ]; then
    flatpak install -y flathub "${FLATPAK_PACKAGES[@]}" 2>&1 | tee -a "$LOG_FILE" || warn "Flatpak installation failed."
fi
