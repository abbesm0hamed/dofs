#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

# Ensure environment variables are set, default if not
: "${REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
: "${LOG_FILE:=/dev/null}"

log "Setting up development tools..."

# Windsurf
if [ ! -f "/etc/yum.repos.d/windsurf.repo" ]; then
    log "Adding Windsurf repository..."
    sudo rpm --import https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf
    echo -e "[windsurf]\nname=Windsurf Repository\nbaseurl=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/repo/\nenabled=1\nautorefresh=1\ngpgcheck=1\ngpgkey=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf" | sudo tee /etc/yum.repos.d/windsurf.repo >/dev/null
else
    log "Windsurf repository already exists."
fi

# Antigravity
if [ ! -f "/etc/yum.repos.d/antigravity.repo" ]; then
    log "Adding Antigravity repository..."
    sudo tee /etc/yum.repos.d/antigravity.repo >/dev/null <<'EOL'
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOL
else
    log "Antigravity repository already exists."
fi

# Zed IDE
if ! command -v zed &>/dev/null; then
    log "Installing Zed IDE..."
    curl -f https://zed.dev/install.sh | sh 2>&1 | tee -a "$LOG_FILE" || warn "Zed IDE installation failed."
else
    log "Zed IDE is already installed."
fi

# --- Install Development CLIs ---

# Ensure npm is in PATH (if installed via fnm in languages.sh)
export PATH="$HOME/.local/share/fnm:$PATH"
if command -v fnm &>/dev/null; then
    eval "$(fnm env --shell bash)"
fi

# GEMINI CLI
if command -v npm &> /dev/null; then
    if ! command -v gemini &> /dev/null; then
        log "Installing Gemini CLI..."
        npm i -g @google/gemini-cli 2>&1 | tee -a "$LOG_FILE" || warn "Gemini CLI installation failed."
    else
        log "Gemini CLI is already installed."
    fi
fi

# OpenCode
if ! command -v opencode &> /dev/null; then
    log "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash 2>&1 | tee -a "$LOG_FILE" || warn "OpenCode installation failed."
else
    log "OpenCode is already installed."
fi