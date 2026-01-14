#!/bin/bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-$HOME/.dofs-install.log}"
log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
err() { printf "\033[0;31m==> %s\033[0m\n" "$1"; }

FISH_PATH=$(command -v fish)
# Ensure common user bins are on PATH for installs that rely on them
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ -z "$FISH_PATH" ]; then
    err "Fish not found."
    exit 1
fi

if [[ "$SHELL" == *"/fish" ]]; then
    ok "Already using Fish."
else
    # Ensure fish is in /etc/shells
    if ! grep -q "$FISH_PATH" /etc/shells; then
        log "Adding $FISH_PATH to /etc/shells..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi

    log "Setting default shell to Fish..."
    sudo chsh -s "$FISH_PATH" "$USER" && ok "Success! Please re-login." || err "Failed."
fi


log "Installing Starship..."
if ! command -v starship &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1 && ok "Starship installed" || err "Starship failed"
fi

log "Installing Atuin..."
if ! command -v atuin &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh >/dev/null 2>&1
    # Add atuin to PATH in current session
    export PATH="$HOME/.atuin/bin:$PATH"
    if command -v atuin &>/dev/null; then
        ok "Atuin installed"
    else
        err "Atuin failed"
    fi
fi

log "Installing Carapace..."
if ! command -v carapace &>/dev/null; then
    REPO_FILE="/etc/yum.repos.d/fury.repo"
    if ! grep -q "yum.fury.io/rsteube" "$REPO_FILE" 2>/dev/null; then
        log "Adding rsteube fury repo..."
        sudo tee "$REPO_FILE" >/dev/null <<'EOF'
[fury]
name=Gemfury Private Repo
baseurl=https://yum.fury.io/rsteube/
enabled=1
gpgcheck=0
EOF
    fi

    if sudo dnf install -y carapace-bin 2>&1 | tee -a "$LOG_FILE"; then
        ok "Carapace installed (rpm)"
    else
        err "Carapace installation failed"
    fi
fi

log "Installing Eza..."
if ! command -v eza &>/dev/null; then
    # Install via cargo since it's not in Fedora repos
    if command -v cargo &>/dev/null; then
        cargo install --locked eza >/dev/null 2>&1 && ok "Eza installed" || err "Eza failed"
    else
        warn "Cargo not found, skipping Eza"
    fi
fi

# Pokemon Colorscripts
log "Setting up pokemon-colorscripts..."
if ! command -v pokemon-colorscripts &>/dev/null; then
    log "Installing pokemon-colorscripts..."
    tmp_dir=$(mktemp -d)
    git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$tmp_dir"
    pushd "$tmp_dir" >/dev/null
    sudo ./install.sh
    popd >/dev/null
    rm -rf "$tmp_dir"
    ok "pokemon-colorscripts installed"
else
    ok "pokemon-colorscripts checked"
fi

# --- Configure Fish PATH for language managers ---
if command -v fish &>/dev/null; then
    log "Configuring Fish shell PATH for language managers..."
    
    # Add fnm path if not already present
    fish -c "contains '$HOME/.local/share/fnm' (string split ':' \$fish_user_paths) || set -Ua fish_user_paths '$HOME/.local/share/fnm'"
    
    # Add bun path if not already present
    fish -c "contains '$HOME/.bun/bin' (string split ':' \$fish_user_paths) || set -Ua fish_user_paths '$HOME/.bun/bin'"
    
    # Add cargo path if not already present
    fish -c "contains '$HOME/.cargo/bin' (string split ':' \$fish_user_paths) || set -Ua fish_user_paths '$HOME/.cargo/bin'"
    
    # Add windsurf abbreviations if binary exists
    fish -c "
        if command -v windsurf >/dev/null
            abbr -a ws windsurf
        else if command -v antigravity >/dev/null
            abbr -a ws antigravity
        end
    "
    
    ok "Fish PATH and abbreviations configured."
fi

if command -v fish &>/dev/null; then
    log "Sourcing Fish config for current session..."
    if "$FISH_PATH" -c 'source ~/.config/fish/config.fish' >/dev/null 2>&1; then
        ok "Fish config sourced"
    else
        warn "Fish config could not be sourced automatically; run 'exec fish' to reload"
    fi
fi

