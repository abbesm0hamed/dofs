#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
success() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
error() { printf "\033[0;31m==> %s\033[0m\n" "$1"; }

# Detect fish path
FISH_PATH=$(command -v fish)

if [ -z "$FISH_PATH" ]; then
    error "Fish shell is not installed. Please install it first."
    exit 1
fi

# Check if already using fish
if [[ "$SHELL" == *"/fish" ]]; then
    success "You are already using fish shell!"
    exit 0
fi

log "Changing default shell to fish ($FISH_PATH)..."
if sudo chsh -s "$FISH_PATH" "$USER"; then
    success "Shell changed successfully! Please log out and back in for changes to take effect."
else
    error "Failed to change shell. You may need to run 'chsh -s $FISH_PATH' manually."
    exit 1
fi
