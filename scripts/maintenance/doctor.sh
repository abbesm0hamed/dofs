#!/bin/bash

# doctor.sh - System health diagnostics
# Verifies key binaries, services, config files, and environment

set -euo pipefail

# Color output helpers
log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m✓ %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m⚠ %s\033[0m\n" "$1"; }
err() { printf "\033[0;31m✗ %s\033[0m\n" "$1"; }

ISSUES=0

check_binary() {
    local binary=$1
    local optional=${2:-false}
    
    if command -v "$binary" &>/dev/null; then
        ok "$binary is installed"
        return 0
    else
        if [ "$optional" = "true" ]; then
            warn "$binary is not installed (optional)"
        else
            err "$binary is not installed"
            ((ISSUES++))
        fi
        return 1
    fi
}

check_config() {
    local config=$1
    local path="$HOME/$config"
    
    if [ -f "$path" ] || [ -d "$path" ]; then
        ok "$config exists"
        return 0
    else
        err "$config is missing"
        ((ISSUES++))
        return 1
    fi
}

check_service() {
    local service=$1
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        ok "$service is running"
        return 0
    elif systemctl --user is-active --quiet "$service" 2>/dev/null; then
        ok "$service is running (user)"
        return 0
    else
        warn "$service is not running"
        return 1
    fi
}

check_env_var() {
    local var=$1
    
    if [ -n "${!var:-}" ]; then
        ok "$var is set: ${!var}"
        return 0
    else
        warn "$var is not set"
        return 1
    fi
}

main() {
    log "Running dofs health diagnostics..."
    echo ""
    
    # Check essential binaries
    log "Checking essential binaries..."
    check_binary git
    check_binary ansible
    check_binary chezmoi
    check_binary fish
    echo ""
    
    # Check desktop environment binaries
    log "Checking desktop environment..."
    check_binary niri
    check_binary waybar
    check_binary mako
    check_binary rofi
    check_binary wezterm
    echo ""
    
    # Check development tools
    log "Checking development tools..."
    check_binary nvim
    check_binary fnm true
    check_binary rustup true
    check_binary docker true
    check_binary rclone true
    echo ""
    
    # Check configuration files
    log "Checking configuration files..."
    check_config ".config/niri/config.kdl"
    check_config ".config/waybar/config.jsonc"
    check_config ".config/fish/config.fish"
    check_config ".config/nvim"
    echo ""
    
    # Check important services
    log "Checking services..."
    check_service docker true
    check_service firewalld true
    echo ""
    
    # Check environment variables
    log "Checking environment variables..."
    check_env_var HOME
    check_env_var USER
    check_env_var SHELL
    echo ""
    
    # Check PATH
    log "Checking PATH..."
    if echo "$PATH" | grep -q "$HOME/.local/bin"; then
        ok "\$HOME/.local/bin is in PATH"
    else
        warn "\$HOME/.local/bin is not in PATH"
    fi
    echo ""
    
    # Check dofs symlink
    log "Checking dofs installation..."
    if [ -L "$HOME/.local/bin/dofs" ]; then
        local target=$(readlink -f "$HOME/.local/bin/dofs")
        ok "dofs is symlinked to $target"
    else
        warn "dofs symlink not found in ~/.local/bin"
    fi
    echo ""
    
    # Check chezmoi state
    log "Checking chezmoi state..."
    if [ -d "$HOME/.local/share/chezmoi" ]; then
        ok "chezmoi is initialized"
        local source_dir=$(chezmoi source-path 2>/dev/null || echo "unknown")
        log "Source directory: $source_dir"
    else
        err "chezmoi is not initialized"
        ((ISSUES++))
    fi
    echo ""
    
    # Summary
    if [ $ISSUES -eq 0 ]; then
        ok "All checks passed! Your system is healthy."
        return 0
    else
        err "Found $ISSUES issue(s). Please review the output above."
        return 1
    fi
}

main "$@"
