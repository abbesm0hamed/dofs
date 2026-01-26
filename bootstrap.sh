#!/bin/bash

set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
err() {
    printf "\033[0;31m==> %s\033[0m\n" "$1" >&2
    exit 1
}

REPO_URL="https://github.com/abbesm0hamed/dofs.git"
INSTALL_DIR="${HOME}/dofs"

main() {
    local STASH_SUCCESSFUL=false

    if ! command -v git &>/dev/null; then
        err "Git is not installed. Please install it first."
    fi

    if [ -d "$INSTALL_DIR" ]; then
        log "Directory $INSTALL_DIR exists. Using existing configuration."
        cd "$INSTALL_DIR"
    else
        log "Cloning dofs repository to $INSTALL_DIR..."
        if git clone --branch fedora-niri "$REPO_URL" "$INSTALL_DIR"; then
            cd "$INSTALL_DIR"
            ok "Repository cloned successfully."
        else
            err "Failed to clone repository."
        fi
    fi

    if [ -d "./ansible" ]; then
        log "Running Ansible playbook..."
        if ! command -v ansible-playbook &>/dev/null; then
            log "Ensuring Ansible is installed..."
            sudo dnf install -y ansible || err "Failed to install Ansible."
        fi
        
        log "Verifying Ansible playbook syntax..."
        if ! ansible-playbook ansible/playbook.yml --syntax-check; then
            err "Ansible playbook syntax check failed."
        fi

        log "Running playbook..."
        sudo -v
        ansible-playbook ansible/playbook.yml "$@"
        ok "Installation complete! Please restart your session."
    else
        err "Ansible directory not found in the repository."
    fi
}

# --- Run main ---
main "$@"
