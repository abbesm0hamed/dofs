#!/bin/bash

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Enable and start the service
sudo systemctl enable --now ollama

# Pull a default model
ollama pull deepseek-coder

# Ensure npm is in PATH (if installed via fnm in languages.sh)
export PATH="$HOME/.local/share/fnm:$PATH"
if command -v fnm &>/dev/null; then
    eval "$(fnm env --shell bash)"
fi

# GEMINI CLI
if command -v npm &> /dev/null; then
    npm i -g @google/gemini-cli
fi
