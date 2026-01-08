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
