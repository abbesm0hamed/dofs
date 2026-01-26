#!/bin/bash

set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
err() {
    printf "\033[0;31m==> %s\033[0m\n" "$1" >&2
    exit 1
}

# --- Configuration ---
REPO_URL="https://github.com/abbesm0hamed/dofs.git"
INSTALL_DIR="${HOME}/dofs"

# --- Main logic ---
main() {
    local STASH_SUCCESSFUL=false

    # Check for dependencies
    if ! command -v git &>/dev/null; then
        err "Git is not installed. Please install it first."
    fi

    # Clone or update the repository
    if [ -d "$INSTALL_DIR" ]; then
        log "Updating existing dofs repository in $INSTALL_DIR..."
        cd "$INSTALL_DIR"
        # Check for local changes before attempting to update
        if [[ -n $(git status --porcelain) ]]; then
            warn "You have local changes that would be overwritten by an update."
            read -p "Do you want to stash them and proceed with the update? (y/N) " -n 1 -r
            echo # Move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Stashing local changes..."
                if ! git stash; then
                    err "Failed to stash changes. Aborting update."
                fi
                STASH_SUCCESSFUL=true
            else
                log "Update cancelled to preserve local changes."
                exit 0
            fi
        fi

        log "Fetching latest changes and updating repository..."
        if git fetch origin && git reset --hard origin/fedora-niri; then
            ok "Repository updated successfully."
            if [[ "$STASH_SUCCESSFUL" == "true" ]]; then
                log "Attempting to re-apply stashed changes..."
                if ! git stash pop; then
                    warn "Could not automatically apply stashed changes. Run 'git stash pop' manually to restore them."
                fi
            fi
        else
            err "Failed to update repository. Please resolve the issue manually in $INSTALL_DIR."
        fi
        log "Re-running installer to apply updates..."
    else
        log "Cloning dofs repository to $INSTALL_DIR..."
        if git clone --branch fedora-niri "$REPO_URL" "$INSTALL_DIR"; then
            cd "$INSTALL_DIR"
            ok "Repository cloned successfully."
        else
            err "Failed to clone repository."
        fi
    fi

    # Run the main installer
    if [ -f "./install.sh" ]; then
        log "Running the main installer..."
        if ! command -v chezmoi &>/dev/null; then
            log "Ensuring chezmoi is installed..."
            sudo dnf install -y chezmoi || err "Failed to install chezmoi."
        fi
        # Pass any arguments from the bootstrap script to the installer
        ./install.sh "$@"
        ok "Installation complete! Please restart your session."
    else
        err "install.sh not found in the repository."
    fi
}

# --- Run main ---
main "$@"
