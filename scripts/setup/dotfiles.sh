#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

log "Stowing dotfiles..."
# Ensure LOG_FILE is set, default to /dev/null if not
: "${LOG_FILE:=/dev/null}"

cd "${REPO_ROOT}"

# --- Set executable permissions on scripts within dotfiles ---
find .config -type f -name "*.sh" -exec chmod +x {} +

# --- Backup existing files and directories ---
log "Backing up existing configurations..."

# Explicitly list directories to be managed by stow
STOW_DIRS=(".config")

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

# Create target .config directory if it doesn't exist
mkdir -p "${HOME}/.config"

# Loop through stow directories and back up their contents
for dir in "${STOW_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        for item in "$dir"/*; do
            [ -e "$item" ] || continue
            item_name=$(basename "$item")
            backup_item "${HOME}/${dir}/${item_name}"
        done
    fi
done

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
