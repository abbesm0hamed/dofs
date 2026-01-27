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
BRANCH="migrate/chezmoi"

main() {
    local STASH_SUCCESSFUL=false

    if ! command -v git &>/dev/null; then
        err "Git is not installed. Please install it first."
    fi

    if [ -d "$INSTALL_DIR" ]; then
        log "Directory $INSTALL_DIR exists. Checking for updates..."
        cd "$INSTALL_DIR"
        if git diff-index --quiet HEAD --; then
            git pull origin "$BRANCH" || warn "Failed to pull latest changes. Continuing with local version."
        else
            warn "Local changes detected. Skipping git pull to avoid conflicts."
        fi
    else
        log "Cloning dofs repository to $INSTALL_DIR..."
        if git clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"; then
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
        
        # Ensure Ansible uses our local config
        export ANSIBLE_CONFIG="${INSTALL_DIR}/ansible/ansible.cfg"

        log "Verifying Ansible playbook syntax..."
        if ! ansible-playbook ansible/playbook.yml -i ansible/inventory --syntax-check; then
            err "Ansible playbook syntax check failed."
        fi

        log "Running playbook..."
        sudo -v
        ansible-playbook ansible/playbook.yml -i ansible/inventory "$@"
        ok "Installation complete! Please restart your session."
    else
        err "Ansible directory not found in the repository."
    fi
}

# --- Run main ---
main "$@"
