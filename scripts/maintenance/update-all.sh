#!/bin/bash

# update-all.sh - Unified system update script
# Updates DNF packages, Flatpak apps, Neovim plugins, Fish plugins, and dev tools

set -euo pipefail

# Color output helpers
log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
err() {
    printf "\033[0;31m==> %s\033[0m\n" "$1" >&2
    exit 1
}

main() {
    log "Starting system-wide update..."
    
    # DNF package updates
    if command -v dnf &>/dev/null; then
        log "Updating DNF packages..."
        if sudo dnf upgrade --refresh -y; then
            ok "DNF packages updated"
        else
            warn "DNF update failed or was cancelled"
        fi
    fi
    
    # Flatpak updates
    if command -v flatpak &>/dev/null; then
        log "Updating Flatpak applications..."
        if flatpak update -y; then
            ok "Flatpak apps updated"
        else
            warn "Flatpak update failed or no updates available"
        fi
    fi
    
    # Neovim plugin updates (lazy.nvim)
    if command -v nvim &>/dev/null; then
        log "Updating Neovim plugins..."
        if nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
            ok "Neovim plugins updated"
        else
            warn "Neovim plugin update failed (this is normal if lazy.nvim isn't configured)"
        fi
    fi
    
    # Fish plugin updates (fisher)
    if command -v fish &>/dev/null && fish -c "type -q fisher" 2>/dev/null; then
        log "Updating Fish plugins..."
        if fish -c "fisher update" 2>/dev/null; then
            ok "Fish plugins updated"
        else
            warn "Fish plugin update failed"
        fi
    fi
    
    # Rust toolchain updates
    if command -v rustup &>/dev/null; then
        log "Updating Rust toolchain..."
        if rustup update; then
            ok "Rust toolchain updated"
        else
            warn "Rust update failed"
        fi
    fi
    
    # Node.js updates via fnm
    if command -v fnm &>/dev/null; then
        log "Checking Node.js version..."
        CURRENT_NODE=$(fnm current 2>/dev/null || echo "none")
        log "Current Node.js: $CURRENT_NODE"
        # Note: fnm doesn't auto-update, user must manually install new versions
    fi
    
    # Clean up
    log "Cleaning up..."
    if command -v dnf &>/dev/null; then
        sudo dnf autoremove -y 2>/dev/null || true
        sudo dnf clean all 2>/dev/null || true
    fi
    
    if command -v flatpak &>/dev/null; then
        flatpak uninstall --unused -y 2>/dev/null || true
    fi
    
    ok "All updates complete!"
    log "You may need to restart some applications or your session for changes to take effect."
}

main "$@"
