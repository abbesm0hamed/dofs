#!/bin/bash

# Install Ollama
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama is already installed."
fi

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
    if ! command -v gemini &> /dev/null; then
        echo "Installing Gemini CLI..."
        npm i -g @google/gemini-cli
    else
        echo "Gemini CLI is already installed."
    fi
fi

# OpenCode
if ! command -v opencode &> /dev/null; then
    echo "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
else
    echo "OpenCode is already installed."
fi
