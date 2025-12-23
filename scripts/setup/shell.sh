#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
err() { printf "\033[0;31m==> %s\033[0m\n" "$1"; }

FISH_PATH=$(command -v fish)

if [ -z "$FISH_PATH" ]; then
    err "Fish not found."
    exit 1
fi

if [[ "$SHELL" == *"/fish" ]]; then
    ok "Already using Fish."
    exit 0
fi

log "Setting default shell to Fish..."
sudo chsh -s "$FISH_PATH" "$USER" && ok "Success! Please re-login." || err "Failed."
