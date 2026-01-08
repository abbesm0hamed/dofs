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
    if [ -z "$(fnm list)" ]; then
        log "Installing latest Node.js version..."
        fnm install --lts
        eval "$(fnm env --shell bash)"
    else
        log "Node.js is already installed via fnm."
    fi
    # Set default to lts-latest (fnm alias), ignoring errors if already set/missing alias
    fnm default lts-latest 2>/dev/null || true
    eval "$(fnm env --shell bash)"

    # Configure user's shell
    if [[ "$SHELL" == *"fish"* ]]; then
        log "Configuring fish shell for fnm..."
        FISH_CONFIG="$HOME/.config/fish/config.fish"
        FNM_INIT_LINE='fnm env --use-on-cd | source'
        mkdir -p "$(dirname "$FISH_CONFIG")"
        if ! grep -q "$FNM_INIT_LINE" "$FISH_CONFIG" 2>/dev/null; then
            echo "$FNM_INIT_LINE" >> "$FISH_CONFIG"
        fi
    fi
    fnm use lts-latest
    
    log "Enabling corepack (for yarn/pnpm)..."
    corepack enable
fi

# --- Bun ---
log "Setting up Bun..."
if ! command -v bun &>/dev/null; then
    curl -fsSL https://bun.sh/install | bash 2>&1 | tee -a "$LOG_FILE" || warn "Bun installation failed."
fi

