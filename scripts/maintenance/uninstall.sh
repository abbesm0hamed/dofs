#!/bin/bash

# Dofs Uninstaller
# Reverts changes made by the installation scripts.

set -euo pipefail

# --- Configuration & Helpers ---
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() { printf "${BLUE}==>${NC} %s\n" "$1"; }
ok() { printf "${GREEN} [OK] ${NC} %s\n" "$1"; }
err() { printf "${RED} [FAIL] ${NC} %s\n" "$1"; }
warn() { printf "${YELLOW} [WARN] ${NC} %s\n" "$1"; }

ask_confirm() {
    read -p "$1 [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    return 0
}

# --- Uninstall Functions ---

unstow_dotfiles() {
    log "Removing dotfile symlinks..."
    if ! command -v stow &>/dev/null; then
        warn "Stow command not found. Cannot unstow dotfiles."
        return
    fi

    cd "$REPO_ROOT"
    if stow -D -v -t "${HOME}" home 2>&1; then
        ok "Dotfiles unstowed successfully."
    else
        err "Failed to unstow dotfiles. You may need to remove symlinks manually."
    fi

    # Remove dofs manager symlink
    if [ -L "${HOME}/.local/bin/dofs" ]; then
        rm "${HOME}/.local/bin/dofs"
        ok "Removed dofs manager symlink."
    fi
}

remove_repositories() {
    log "Removing custom repositories..."
    local repo_dir="/etc/yum.repos.d"
    local files_to_remove=(
        "${repo_dir}/_copr_*.repo"
        "${repo_dir}/windsurf.repo"
        "${repo_dir}/antigravity.repo"
    )

    for file_pattern in "${files_to_remove[@]}"; do
        # Use ls to handle patterns that might not match any files
        ls ${file_pattern} 2>/dev/null | while read -r file; do
            if [ -f "$file" ]; then
                sudo rm "$file"
                ok "Removed $file"
            fi
        done
    done

    log "Running 'dnf clean all' to clear cache..."
    sudo dnf clean all >/dev/null
}

# --- Main Execution ---

log "DOFS Uninstaller"
worn "This script will remove configurations and symlinks managed by dofs."
worn "It will NOT uninstall packages or change your default shell."

if ask_confirm "Are you sure you want to proceed?"; then
    unstow_dotfiles
    remove_repositories
    # More functions will be added here in the future
    log "Uninstall process complete."
    log "Please review the manual steps above for full cleanup."
else
    log "Uninstall cancelled."
fi
