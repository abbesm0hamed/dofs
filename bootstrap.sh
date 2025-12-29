#!/bin/bash

set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
err() { printf "\033[0;31m==> %s\033[0m\n" "$1" >&2; exit 1; }

# --- Configuration ---
REPO_URL="https://github.com/abbesm0hamed/dofs.git"
INSTALL_DIR="${HOME}/dofs"

# --- Main logic ---
main() {
    # 1. Check for dependencies
    if ! command -v git &>/dev/null; then
        err "Git is not installed. Please install it first."
    fi

    # 2. Clone or update the repository
    if [ -d "$INSTALL_DIR" ]; then
        log "Updating existing dofs repository in $INSTALL_DIR..."
        cd "$INSTALL_DIR"
        if git pull --rebase --autostash; then
            ok "Repository updated successfully."
        else
            warn "Could not update repository. Continuing with local version."
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

    # 3. Run the main installer
    if [ -f "./install.sh" ]; then
        log "Running the main installer..."
        # Pass any arguments from the bootstrap script to the installer
        ./install.sh "$@"
        ok "Installation complete! Please restart your session."
    else
        err "install.sh not found in the repository."
    fi
}

# --- Run main --- 
main "$@"
