#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

NIRI_ENV_FILE="$HOME/.config/niri/configs/env"
read_env_value() {
    local key="$1"
    awk -F= -v k="$key" '/^[[:space:]]*export[[:space:]]+/ { if ($1 ~ k) v=$2 } END { gsub(/^["\x27 ]+|["\x27 ]+$/, "", v); print v }' "$NIRI_ENV_FILE"
}
if [ -f "$NIRI_ENV_FILE" ]; then
    if [ -z "${XCURSOR_THEME:-}" ]; then
        XCURSOR_THEME="$(read_env_value XCURSOR_THEME)"
    fi
    if [ -z "${XCURSOR_SIZE:-}" ]; then
        XCURSOR_SIZE="$(read_env_value XCURSOR_SIZE)"
    fi
fi

CURSOR_THEME="${CURSOR_THEME:-${XCURSOR_THEME}}"
CURSOR_SIZE="${CURSOR_SIZE:-${XCURSOR_SIZE}}"

ICONS_DIR="${HOME}/.local/share/icons"
mkdir -p "$ICONS_DIR"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# --- Install Layan Cursors ---
log "Installing Layan cursors..."
if [ ! -d "$ICONS_DIR/Layan-cursors" ]; then
    git clone https://github.com/vinceliuice/Layan-cursors.git "$TEMP_DIR/Layan-cursors"
    cd "$TEMP_DIR/Layan-cursors"
    ./install.sh
    ok "Layan cursors installed."
else
    ok "Layan cursors already installed."
fi
# --- Install Banana Cursor ---
log "Installing Banana cursor..."
if [ ! -d "$ICONS_DIR/Banana" ]; then
    BANANA_URL="https://github.com/ful1e5/banana-cursor/releases/download/v2.0.0/Banana.tar.xz"
    curl -L "$BANANA_URL" -o "$TEMP_DIR/Banana.tar.xz"
    tar -xf "$TEMP_DIR/Banana.tar.xz" -C "$ICONS_DIR"
    ok "Banana cursor installed."
else
    ok "Banana cursor already installed."
fi

# --- Browser & Flatpak Fixes ---
log "Applying browser and consistency fixes..."

if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"
    ok "Global GSettings updated to ${CURSOR_THEME}."
fi

mkdir -p "${HOME}/.icons/default"
cat >"${HOME}/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=${CURSOR_THEME}
EOF
ok "XWayland fallback created."

if command -v flatpak &>/dev/null; then
    flatpak override --user --filesystem="~/.local/share/icons:ro"
    flatpak override --user --filesystem="~/.icons:ro"
    ok "Flatpak overrides applied for icon access."
fi
