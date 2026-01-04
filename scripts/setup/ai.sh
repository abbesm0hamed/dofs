#!/bin/bash

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Enable and start the service
sudo systemctl enable --now ollama

# Pull a default model
ollama pull deepseek-coder
