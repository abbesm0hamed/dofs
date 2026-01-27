#!/bin/bash

# preflight.sh - Pre-installation conflict detection and backup
# Checks for existing configurations before applying changes

set -euo pipefail

# Color output helpers
log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m✓ %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m⚠ %s\033[0m\n" "$1"; }
err() { printf "\033[0;31m✗ %s\033[0m\n" "$1"; }

# Get repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
CONFLICTS=0
WARNINGS=0

check_chezmoi_conflicts() {
    log "Checking for chezmoi conflicts..."
    
    if ! command -v chezmoi &>/dev/null; then
        warn "chezmoi not installed yet - will be installed during bootstrap"
        return 0
    fi
    
    # Check what would change
    local diff_output
    if diff_output=$(chezmoi diff --source "$REPO_ROOT/home" 2>&1); then
        ok "No conflicts detected"
        return 0
    else
        if echo "$diff_output" | grep -q "diff"; then
            warn "Found differences between managed files and current state"
            echo "$diff_output" | head -20
            ((WARNINGS++))
            return 1
        fi
    fi
}

check_existing_configs() {
    log "Checking for existing manual configurations..."
    
    local managed_dirs=(
        ".config/niri"
        ".config/waybar"
        ".config/fish"
        ".config/nvim"
        ".config/wezterm"
        ".config/mako"
    )
    
    for dir in "${managed_dirs[@]}"; do
        if [ -d "$HOME/$dir" ]; then
            if [ -L "$HOME/$dir" ]; then
                warn "$dir is a symlink (might be from old setup)"
                ((WARNINGS++))
            else
                ok "$dir exists (will be managed by chezmoi)"
            fi
        fi
    done
}

check_old_stow_configs() {
    log "Checking for old stow-managed configurations..."
    
    # Look for common stow patterns
    local stow_found=false
    
    if [ -d "$HOME/.dotfiles" ]; then
        warn "Found ~/.dotfiles directory (possible old stow setup)"
        stow_found=true
        ((WARNINGS++))
    fi
    
    # Check for symlinks pointing to a dotfiles repo
    local symlink_count=0
    while IFS= read -r -d '' symlink; do
        local target=$(readlink "$symlink")
        if echo "$target" | grep -q "dotfiles\|stow"; then
            ((symlink_count++))
        fi
    done < <(find "$HOME/.config" -maxdepth 2 -type l -print0 2>/dev/null || true)
    
    if [ $symlink_count -gt 0 ]; then
        warn "Found $symlink_count symlinks that might be from stow"
        stow_found=true
        ((WARNINGS++))
    fi
    
    if [ "$stow_found" = false ]; then
        ok "No old stow configurations detected"
    fi
}

create_backup() {
    log "Creating backup of existing configurations..."
    
    local backed_up=0
    local dirs_to_backup=(
        ".config/niri"
        ".config/waybar"
        ".config/fish"
        ".config/nvim"
        ".config/wezterm"
        ".config/mako"
        ".config/rofi"
        ".tmux.conf"
    )
    
    mkdir -p "$BACKUP_DIR"
    
    for item in "${dirs_to_backup[@]}"; do
        if [ -e "$HOME/$item" ]; then
            local parent_dir=$(dirname "$BACKUP_DIR/$item")
            mkdir -p "$parent_dir"
            cp -r "$HOME/$item" "$BACKUP_DIR/$item" 2>/dev/null || true
            ((backed_up++))
        fi
    done
    
    if [ $backed_up -gt 0 ]; then
        ok "Backed up $backed_up items to $BACKUP_DIR"
        log "You can restore with: cp -r $BACKUP_DIR/.config/* ~/.config/"
    else
        ok "No existing configurations to backup"
        rmdir "$BACKUP_DIR" 2>/dev/null || true
    fi
}

show_summary() {
    echo ""
    log "=== Preflight Check Summary ==="
    echo ""
    
    if [ $CONFLICTS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        ok "All checks passed! Safe to proceed with installation."
        echo ""
        log "Next steps:"
        echo "  1. Run: ./bootstrap.sh"
        echo "  2. Or with backup: ./bootstrap.sh (backup is automatic)"
        return 0
    elif [ $CONFLICTS -eq 0 ]; then
        warn "Found $WARNINGS warning(s), but no critical conflicts"
        echo ""
        log "Recommendations:"
        echo "  1. Review warnings above"
        echo "  2. Backup created at: $BACKUP_DIR"
        echo "  3. Proceed with: ./bootstrap.sh"
        return 0
    else
        err "Found $CONFLICTS conflict(s) and $WARNINGS warning(s)"
        echo ""
        log "Recommendations:"
        echo "  1. Review conflicts above"
        echo "  2. Manually resolve conflicts"
        echo "  3. Run preflight again"
        return 1
    fi
}

main() {
    log "Running preflight checks before installation..."
    echo ""
    
    check_existing_configs
    echo ""
    
    check_old_stow_configs
    echo ""
    
    check_chezmoi_conflicts
    echo ""
    
    # Always create backup if configs exist
    if [ -d "$HOME/.config/niri" ] || [ -d "$HOME/.config/waybar" ]; then
        create_backup
    fi
    
    show_summary
}

main "$@"
