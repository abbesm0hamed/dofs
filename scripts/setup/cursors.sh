#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

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

# 1. Global GSettings update (for GTK apps that monitor this)
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface cursor-theme "Banana"
    gsettings set org.gnome.desktop.interface cursor-size 24
    ok "Global GSettings updated to Banana."
fi

# 2. XWayland / Legacy fallback
# Some apps look at ~/.icons/default/index.theme
mkdir -p "${HOME}/.icons/default"
cat > "${HOME}/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=Banana
EOF
ok "XWayland fallback created."

# 3. Flatpak permission fix (for Zen Browser and others)
# Allows Flatpaks to read the local icons directory
if command -v flatpak &>/dev/null; then
    flatpak override --user --filesystem="~/.local/share/icons:ro"
    flatpak override --user --filesystem="~/.icons:ro"
    ok "Flatpak overrides applied for icon access."
fi
