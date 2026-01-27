#!/bin/bash

# verify.sh - Post-installation verification
# Runs Ansible verify role to check installation health

set -euo pipefail

# Get the repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
err() {
    printf "\033[0;31m==> %s\033[0m\n" "$1" >&2
    exit 1
}

main() {
    log "Running post-installation verification..."
    
    # Check if Ansible is available
    if ! command -v ansible-playbook &>/dev/null; then
        err "Ansible is not installed. Cannot run verification."
    fi
    
    # Check if playbook exists
    if [ ! -f "$REPO_ROOT/ansible/playbook.yml" ]; then
        err "Ansible playbook not found at $REPO_ROOT/ansible/playbook.yml"
    fi
    
    # Set Ansible config
    export ANSIBLE_CONFIG="$REPO_ROOT/ansible/ansible.cfg"
    
    # Run only the verify role
    log "Running Ansible verify role..."
    cd "$REPO_ROOT"
    
    if ansible-playbook ansible/playbook.yml \
        -i ansible/inventory \
        --tags verify \
        -e "ansible_user_dir=$HOME"; then
        ok "Verification complete!"
        return 0
    else
        err "Verification failed. Please check the output above."
    fi
}

main "$@"
