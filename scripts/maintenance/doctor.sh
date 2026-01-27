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
STRICT_MODE=false

# Parse arguments
if [ "${1:-}" = "--strict" ]; then
    STRICT_MODE=true
    log "Running in strict mode (warnings count as errors)"
fi

check_binary() {
    local binary=$1
    local optional=${2:-false}
    
    if command -v "$binary" &>/dev/null; then
        ok "$binary is installed"
        return 0
    else
        if [ "$optional" = "true" ]; then
            warn "$binary is not installed (optional)"
            [ "$STRICT_MODE" = true ] && ((ISSUES++))
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
        [ "$STRICT_MODE" = true ] && ((ISSUES++))
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
        [ "$STRICT_MODE" = true ] && ((ISSUES++))
        return 1
    fi
}

check_chezmoi_drift() {
    log "Checking for configuration drift..."
    
    if ! command -v chezmoi &>/dev/null; then
        warn "chezmoi not installed - cannot check drift"
        return 1
    fi
    
    if [ ! -d "$HOME/.local/share/chezmoi" ]; then
        err "chezmoi not initialized"
        ((ISSUES++))
        return 1
    fi
    
    # Check for differences
    local diff_count=0
    if chezmoi diff 2>&1 | grep -q "diff"; then
        warn "Configuration drift detected - managed files differ from source"
        diff_count=$(chezmoi diff 2>&1 | grep -c "^diff" || echo 0)
        log "Run 'chezmoi diff' to see details"
        log "Run 'chezmoi apply' to sync changes"
        [ "$STRICT_MODE" = true ] && ((ISSUES++))
        return 1
    else
        ok "No configuration drift detected"
        return 0
    fi
}

check_ansible_roles() {
    log "Checking Ansible setup..."
    
    local repo_root
    if [ -L "$HOME/.local/bin/dofs" ]; then
        repo_root=$(dirname "$(readlink -f "$HOME/.local/bin/dofs")")
        
        if [ -f "$repo_root/ansible/playbook.yml" ]; then
            ok "Ansible playbook found at $repo_root/ansible/playbook.yml"
        else
            warn "Ansible playbook not found"
            [ "$STRICT_MODE" = true ] && ((ISSUES++))
        fi
    else
        warn "dofs not properly installed"
        [ "$STRICT_MODE" = true ] && ((ISSUES++))
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
        [ "$STRICT_MODE" = true ] && ((ISSUES++))
    fi
    echo ""
    
    # Check dofs symlink
    log "Checking dofs installation..."
    if [ -L "$HOME/.local/bin/dofs" ]; then
        local target=$(readlink -f "$HOME/.local/bin/dofs")
        ok "dofs is symlinked to $target"
    else
        warn "dofs symlink not found in ~/.local/bin"
        [ "$STRICT_MODE" = true ] && ((ISSUES++))
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
    
    # Check for drift
    check_chezmoi_drift
    echo ""
    
    # Check Ansible
    check_ansible_roles
    echo ""
    
    # Summary
    if [ $ISSUES -eq 0 ]; then
        ok "All checks passed! Your system is healthy."
        return 0
    else
        err "Found $ISSUES issue(s). Please review the output above."
        echo ""
        log "To fix issues:"
        echo "  - Run 'dofs install --update' to sync configuration"
        echo "  - Run 'chezmoi apply' to fix drift"
        echo "  - Run 'dofs verify' for detailed Ansible checks"
        return 1
    fi
}

main "$@"
