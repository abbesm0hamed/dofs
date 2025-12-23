#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

log "Installing packages..."
ALL_PACKAGES=()
NEEDS_SWAYLOCK_EFFECTS_REPO=0
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
        "swaylock-effects")
            FEDORA_PACKAGES+=("swaylock-effects")
            NEEDS_SWAYLOCK_EFFECTS_REPO=1
            ;;
        "github-cli") FEDORA_PACKAGES+=("gh") ;;
        "imagemagick") FEDORA_PACKAGES+=("ImageMagick") ;;
        "python-pip") FEDORA_PACKAGES+=("python3-pip") ;;
        "qt5-wayland") FEDORA_PACKAGES+=("qt5-qtwayland") ;;
        "qt6-wayland") FEDORA_PACKAGES+=("qt6-qtwayland") ;;
        "starship"|"fnm"|"bun") continue ;;
        *) FEDORA_PACKAGES+=("$pkg") ;;
    esac
done

# Enable COPR for swaylock-effects on Fedora if requested
if [ "$NEEDS_SWAYLOCK_EFFECTS_REPO" -eq 1 ]; then
    if ! sudo dnf repolist --enabled 2>/dev/null | grep -q "swaylock-effects"; then
        log "Enabling COPR: eddsalkield/swaylock-effects"
        if ! sudo dnf copr enable -y eddsalkield/swaylock-effects 2>&1 | tee -a "$LOG_FILE"; then
            warn "Failed to enable copr eddsalkield/swaylock-effects; swaylock-effects may not install."
        fi
    fi
fi

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
