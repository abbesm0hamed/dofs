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

# Flags
DOTFILES_ONLY=false
ANSIBLE_ONLY=false
UPDATE_MODE=false
SKIP_PULL=false

usage() {
    cat << EOF
Usage: bootstrap.sh [OPTIONS]

Bootstrap Fedora workstation with dofs configuration.

OPTIONS:
    --dotfiles-only     Only apply dotfiles (skip Ansible)
    --ansible-only      Only run Ansible (skip dotfiles)
    --update            Update existing installation
    --skip-pull         Don't pull latest changes from git
    -h, --help          Show this help message

EXAMPLES:
    # Full installation
    ./bootstrap.sh

    # Only apply dotfiles
    ./bootstrap.sh --dotfiles-only

    # Update existing installation
    ./bootstrap.sh --update
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dotfiles-only)
                DOTFILES_ONLY=true
                shift
                ;;
            --ansible-only)
                ANSIBLE_ONLY=true
                shift
                ;;
            --update)
                UPDATE_MODE=true
                shift
                ;;
            --skip-pull)
                SKIP_PULL=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                err "Unknown option: $1"
                ;;
        esac
    done
    
    # Validate flag combinations
    if [ "$DOTFILES_ONLY" = true ] && [ "$ANSIBLE_ONLY" = true ]; then
        err "Cannot use --dotfiles-only and --ansible-only together"
    fi
}

setup_repository() {
    if ! command -v git &>/dev/null; then
        err "Git is not installed. Please install it first: sudo dnf install -y git"
    fi

    if [ -d "$INSTALL_DIR" ]; then
        log "Directory $INSTALL_DIR exists."
        cd "$INSTALL_DIR"
        
        if [ "$SKIP_PULL" = false ]; then
            log "Checking for updates..."
            if git diff-index --quiet HEAD --; then
                git pull origin "$BRANCH" || warn "Failed to pull latest changes. Continuing with local version."
            else
                warn "Local changes detected. Skipping git pull to avoid conflicts."
                log "Use --skip-pull to suppress this check"
            fi
        else
            log "Skipping git pull (--skip-pull flag)"
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
}

install_chezmoi() {
    if ! command -v chezmoi &>/dev/null; then
        log "Installing chezmoi..."
        if command -v dnf &>/dev/null; then
            sudo dnf install -y chezmoi || err "Failed to install chezmoi"
        else
            err "DNF not found. Please install chezmoi manually."
        fi
        ok "chezmoi installed"
    else
        log "chezmoi is already installed"
    fi
}

apply_dotfiles() {
    log "Applying dotfiles with chezmoi..."
    
    # Initialize chezmoi if needed
    if [ ! -d "$HOME/.local/share/chezmoi" ]; then
        log "Initializing chezmoi..."
        chezmoi init --source "$INSTALL_DIR/home" || err "Failed to initialize chezmoi"
    fi
    
    # Apply dotfiles
    log "Applying dotfiles..."
    chezmoi apply --source "$INSTALL_DIR/home" --force || err "Failed to apply dotfiles"
    
    ok "Dotfiles applied successfully"
}

run_ansible() {
    if [ ! -d "$INSTALL_DIR/ansible" ]; then
        err "Ansible directory not found in the repository."
    fi
    
    log "Running Ansible playbook..."
    
    # Install Ansible if needed
    if ! command -v ansible-playbook &>/dev/null; then
        log "Installing Ansible..."
        sudo dnf install -y ansible || err "Failed to install Ansible."
    fi
    
    # Set Ansible config
    export ANSIBLE_CONFIG="$INSTALL_DIR/ansible/ansible.cfg"

    # Syntax check
    log "Verifying Ansible playbook syntax..."
    if ! ansible-playbook "$INSTALL_DIR/ansible/playbook.yml" \
        -i "$INSTALL_DIR/ansible/inventory" \
        --syntax-check; then
        err "Ansible playbook syntax check failed."
    fi

    # Run playbook
    log "Running playbook..."
    sudo -v  # Refresh sudo timestamp
    
    ansible-playbook "$INSTALL_DIR/ansible/playbook.yml" \
        -i "$INSTALL_DIR/ansible/inventory" \
        "$@" || err "Ansible playbook failed"
    
    ok "Ansible playbook completed successfully"
}

main() {
    parse_args "$@"
    
    log "Starting dofs bootstrap..."
    
    # Setup repository
    setup_repository
    
    # Install chezmoi first (unless ansible-only mode)
    if [ "$ANSIBLE_ONLY" = false ]; then
        install_chezmoi
        apply_dotfiles
    fi
    
    # Run Ansible (unless dotfiles-only mode)
    if [ "$DOTFILES_ONLY" = false ]; then
        run_ansible
    fi
    
    # Apply default theme only if none is set
    THEME_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/themes/current_theme"
    if [ ! -f "$THEME_STATE" ] && [ -f "$HOME/.config/niri/scripts/set-theme.sh" ]; then
        log "No theme detected. Applying default dofs theme..."
        bash "$HOME/.config/niri/scripts/set-theme.sh" "dofs" --silent || warn "Failed to apply default theme"
    fi

    echo ""
    ok "Bootstrap complete!"
    
    if [ "$DOTFILES_ONLY" = false ]; then
        log "Please restart your session for all changes to take effect."
    fi
}

# Run main
main "$@"
