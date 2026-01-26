#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

# Determine REPO_ROOT (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DOTFILES_HOME="${REPO_ROOT}/home"

log "Stowing dotfiles using chezmoi..."

# Initialize chezmoi from the local source
log "Initializing chezmoi from ${DOTFILES_HOME}"
chezmoi init --source "${DOTFILES_HOME}"

# Apply the configuration
# Using --force to overwrite any existing symlinks and handle conflicts
log "Applying dotfiles configuration"
chezmoi apply --source "${DOTFILES_HOME}" --force --verbose

# --- Ensure executable permissions on management scripts ---
log "Setting executable permissions on scripts..."
find "${REPO_ROOT}/scripts" -type f -name "*.sh" -exec chmod +x {} +
chmod +x "${REPO_ROOT}/dofs"

# --- Link dofs manager for convenience ---
mkdir -p "${HOME}/.local/bin"
ln -sf "${REPO_ROOT}/dofs" "${HOME}/.local/bin/dofs"

ok "Dotfiles setup complete with chezmoi!"
