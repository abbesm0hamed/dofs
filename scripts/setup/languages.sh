#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

# Ensure LOG_FILE is set, default to /dev/null if not
: "${LOG_FILE:=/dev/null}"

# --- FNM & Node.js ---
log "Setting up FNM and Node.js..."
if ! command -v fnm &>/dev/null; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell 2>&1 | tee -a "$LOG_FILE" || warn "fnm installation failed."
fi

# Set up the environment for this script's execution
export PATH="$HOME/.local/share/fnm:$PATH"
if command -v fnm &>/dev/null; then
    eval "$(fnm env --shell bash)"
    log "Installing latest Node.js version..."
    fnm install --lts
    fnm default lts
    log "Enabling corepack (for yarn/pnpm)..."
    corepack enable
fi

# --- Bun ---
log "Setting up Bun..."
if ! command -v bun &>/dev/null; then
    curl -fsSL https://bun.sh/install | bash 2>&1 | tee -a "$LOG_FILE" || warn "Bun installation failed."
fi

