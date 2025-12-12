#!/bin/bash
# CachyOS Gaming Optimization Wrapper
# Uses game-performance to boost performance during gaming

set -euo pipefail

# Check if game-performance is available
if ! command -v game-performance &> /dev/null; then
    echo "Warning: game-performance not found. Running game without optimization."
    echo "Install with: yay -S game-performance"
    exec "$@"
fi

# Set Wayland-native environment variables for better performance
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export CLUTTER_BACKEND=wayland

# Enable Wayland for Proton games (experimental but better latency)
export PROTON_ENABLE_WAYLAND=1

# Disable window decorations for borderless fullscreen
export PROTON_NO_WM_DECORATION=1

# Use game-performance wrapper
echo "Starting game with performance optimizations..."
echo "Command: $*"

exec game-performance "$@"
