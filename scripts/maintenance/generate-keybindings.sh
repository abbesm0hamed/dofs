#!/bin/bash

# generate-keybindings.sh - Generate KEYBINDINGS.md documentation
# Extracts keybindings from Niri and Neovim configurations

set -euo pipefail

# Get the repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_FILE="$REPO_ROOT/KEYBINDINGS.md"

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
err() {
    printf "\033[0;31m==> %s\033[0m\n" "$1" >&2
    exit 1
}

main() {
    log "Generating keybindings documentation..."
    
    # Check if KEYBINDINGS.md already exists
    if [ -f "$OUTPUT_FILE" ]; then
        log "KEYBINDINGS.md already exists at $OUTPUT_FILE"
        log "This script is a placeholder for auto-generation"
        log "Currently, KEYBINDINGS.md is manually maintained"
        ok "No changes made"
        return 0
    fi
    
    # TODO: Implement actual parsing of:
    # - ~/.config/niri/config.kdl (binds section)
    # - ~/.config/nvim/lua/*/keymaps.lua (Neovim keymaps)
    
    warn "Auto-generation not yet implemented"
    log "Please manually update KEYBINDINGS.md"
    
    return 0
}

main "$@"
