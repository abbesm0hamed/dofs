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