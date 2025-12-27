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

# Ensure fish is in /etc/shells
if ! grep -q "$FISH_PATH" /etc/shells; then
    log "Adding $FISH_PATH to /etc/shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

log "Installing Starship..."
if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1 && ok "Starship installed" || err "Starship failed"
fi

log "Installing Atuin..."
if ! command -v atuin &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh >/dev/null 2>&1 && ok "Atuin installed" || err "Atuin failed"
fi

log "Installing Carapace..."
if ! command -v carapace &>/dev/null; then
    curl -fsSL https://carapace-sh.github.io/carapace-bin/install.sh | bash >/dev/null 2>&1 && ok "Carapace installed" || err "Carapace failed"
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

log "Setting default shell to Fish..."
sudo chsh -s "$FISH_PATH" "$USER" && ok "Success! Please re-login." || err "Failed."
