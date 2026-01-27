#!/bin/bash

# uninstall.sh - Remove dofs configurations and optionally packages
# Cleans up dotfiles managed by chezmoi and dofs symlinks

set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
err() {
    printf "\033[0;31m==> %s\033[0m\n" "$1" >&2
    exit 1
}

confirm() {
    local prompt="$1"
    read -p "$prompt [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

main() {
    warn "This will remove dofs configurations from your system"
    echo ""
    
    if ! confirm "Are you sure you want to continue?"; then
        log "Uninstall cancelled"
        return 0
    fi
    
    # Remove chezmoi-managed dotfiles
    if command -v chezmoi &>/dev/null && [ -d "$HOME/.local/share/chezmoi" ]; then
        log "Removing chezmoi-managed dotfiles..."
        
        if confirm "Remove all dotfiles managed by chezmoi?"; then
            # Get list of managed files
            chezmoi managed | while read -r file; do
                if [ -f "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
                    log "Removing $HOME/$file"
                    rm -f "$HOME/$file"
                fi
            done
            
            # Remove chezmoi state
            log "Removing chezmoi state directory..."
            rm -rf "$HOME/.local/share/chezmoi"
            ok "Dotfiles removed"
        else
            log "Skipping dotfiles removal"
        fi
    fi
    
    # Remove dofs symlink
    if [ -L "$HOME/.local/bin/dofs" ]; then
        log "Removing dofs symlink..."
        rm -f "$HOME/.local/bin/dofs"
        ok "dofs symlink removed"
    fi
    
    # Optionally remove packages
    if confirm "Remove packages installed by dofs? (This will uninstall niri, waybar, etc.)"; then
        warn "Package removal not yet implemented"
        log "You can manually remove packages using: sudo dnf remove <package>"
    fi
    
    echo ""
    ok "Uninstall complete!"
    log "The dofs repository in ~/dofs has not been removed"
    log "You can delete it manually if desired: rm -rf ~/dofs"
}

main "$@"
