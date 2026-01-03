#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

log "Stowing dotfiles..."
# Ensure LOG_FILE is set, default to /dev/null if not
: "${LOG_FILE:=/dev/null}"

# Determine REPO_ROOT if not set
if [ -z "${REPO_ROOT:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

cd "${REPO_ROOT}"

# --- Set executable permissions on scripts within dotfiles ---
find home -type f -name "*.sh" -exec chmod +x {} +

# --- Backup existing files and directories ---
log "Backing up existing configurations..."

# Explicitly list directories to be managed by stow
STOW_DIRS=("home")

backup_item() {
    local item_path="$1"
    if [ -e "$item_path" ] && [ ! -L "$item_path" ]; then
        local backup_path="${item_path}.bak"
        if [ -e "$backup_path" ]; then
            warn "Backup ${backup_path} already exists. Skipping backup for ${item_path}."
            return
        fi
        log "Backing up ${item_path} to ${backup_path}"
        mv "$item_path" "$backup_path"
    fi
}

# Create target .config directory and subdirectories to prevent stow folding
log "Preparing target directories..."
mkdir -p "${HOME}/.config"

# Pre-creating specific subdirectories helps stow symlink files individually
# instead of linking the entire directory.
for config_dir in niri waybar ghostty alacritty fish swaylock nvim fuzzel; do
    mkdir -p "${HOME}/.config/${config_dir}"
done

# Loop through stow directories and back up their contents
shopt -s dotglob
for dir in "${STOW_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        for item in "$dir"/*; do
            [ -e "$item" ] || continue
            item_name=$(basename "$item")

            if [ "$item_name" == ".config" ] && [ -d "$item" ]; then
                # Handle .config folding
                for subitem in "$item"/*; do
                    [ -e "$subitem" ] || continue
                    subitem_name=$(basename "$subitem")
                    backup_item "${HOME}/.config/${subitem_name}"
                done
            else
                backup_item "${HOME}/${item_name}"
            fi
        done
    fi
done
shopt -u dotglob

# --- Run Stow ---
log "Stowing dotfiles to ${HOME}..."

# Use an array for stow command to handle spaces correctly
stow_cmd=("stow" "-R" "-v" "-t" "${HOME}")
stow_cmd+=("${STOW_DIRS[@]}")

if "${stow_cmd[@]}" 2>&1 | tee -a "$LOG_FILE"; then
    log "Stow complete."
else
    warn "Stow command failed. Some dotfiles may not be linked."
fi

# --- Link dofs manager ---
log "Linking dofs manager..."
mkdir -p "${HOME}/.local/bin"
ln -sf "${REPO_ROOT}/dofs" "${HOME}/.local/bin/dofs"
chmod +x "${REPO_ROOT}/dofs"
ok "dofs manager linked to ~/.local/bin/dofs"
