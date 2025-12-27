#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

log "Stowing dotfiles..."
cd "${REPO_ROOT}"
[ -d ".config/niri/scripts" ] && chmod +x .config/niri/scripts/*
[ -d "scripts" ] && chmod +x scripts/*
mkdir -p "${HOME}/.config"

# Function to backup an item if it's not a symlink
backup_item() {
    local item="$1"
    if [ -e "$item" ] && [ ! -L "$item" ]; then
        log "Backing up ${item} to ${item}.bak"
        mv "$item" "${item}.bak"
    fi
}

STOW_ITEMS=$(ls -A | grep -vE "^(\.git|scripts|packages|templates|install\.sh|install\.log|README\.md)$")

for item in $STOW_ITEMS; do
    target="${HOME}/${item}"
    if [ "$item" == ".config" ]; then
        for subitem in .config/*; do
            [ -e "$subitem" ] || continue
            backup_item "${HOME}/${subitem}"
        done
    else
        backup_item "$target"
    fi
done

stow -R -v -t "${HOME}" . 2>&1 | tee -a "$LOG_FILE" || warn "Stow failed."
