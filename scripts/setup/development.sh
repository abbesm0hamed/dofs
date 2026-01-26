#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }

# Ensure environment variables are set, default if not
: "${REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
: "${LOG_FILE:=/dev/null}"

log "Setting up development tools..."

WINDSURF_REPO="/etc/yum.repos.d/windsurf.repo"
if [ ! -f "$WINDSURF_REPO" ]; then
    log "Adding Windsurf repository..."
    sudo rpm --import https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf
    printf "%s\n" \
        "[windsurf]" \
        "name=Windsurf Repository" \
        "baseurl=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/repo/" \
        "enabled=1" \
        "autorefresh=1" \
        "gpgcheck=1" \
        "gpgkey=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf" \
        | sudo tee "$WINDSURF_REPO" >/dev/null
fi

ANTIGRAVITY_REPO="/etc/yum.repos.d/antigravity.repo"
if [ ! -f "$ANTIGRAVITY_REPO" ]; then
    log "Adding Antigravity repository..."
    sudo tee "$ANTIGRAVITY_REPO" >/dev/null <<'EOL'
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOL
fi

if ! command -v zed &>/dev/null; then
    log "Installing Zed IDE..."
    curl -f https://zed.dev/install.sh | sh 2>&1 | tee -a "$LOG_FILE" || warn "Zed IDE installation failed."
fi

# --- Install Development CLIs ---

# Ensure npm is in PATH (if installed via fnm in languages.sh)
export PATH="$HOME/.local/share/fnm:$PATH"
command -v fnm &>/dev/null && eval "$(fnm env --shell bash)"

# GEMINI CLI
if command -v npm &>/dev/null && ! command -v gemini &>/dev/null; then
    log "Installing Gemini CLI..."
    sudo npm i -g @google/gemini-cli 2>&1 | tee -a "$LOG_FILE" || warn "Gemini CLI installation failed."
fi

# OpenCode
if ! command -v opencode &>/dev/null; then
    log "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash 2>&1 | tee -a "$LOG_FILE" || warn "OpenCode installation failed."
fi

# Install lazydocker
if ! command -v lazydocker &>/dev/null; then
    log "Installing lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash 2>&1 | tee -a "$LOG_FILE" || warn "lazydocker installation failed."
fi

# Install TablePlus
if ! command -v tableplus &>/dev/null; then
    log "Installing TablePlus..."
    sudo rpm -v --import https://yum.tableplus.com/apt.tableplus.com.gpg.key 2>&1 | tee -a "$LOG_FILE" || warn "TablePlus GPG key import failed."
    sudo dnf install -y dnf-plugins-core 2>&1 | tee -a "$LOG_FILE" || warn "Failed to install dnf-plugins-core (required for dnf config-manager)."
    sudo dnf config-manager addrepo --from-repofile=https://yum.tableplus.com/rpm/x86_64/tableplus.repo 2>&1 | tee -a "$LOG_FILE" || warn "Failed to add TablePlus repo."
    sudo dnf install -y tableplus 2>&1 | tee -a "$LOG_FILE" || warn "TablePlus installation failed."
fi