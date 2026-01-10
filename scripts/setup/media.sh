#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

log "Setting up Multimedia (Audio/Camera)..."

# Enable Camera Relay (Required for Intel IPU6 cameras)
if systemctl list-unit-files v4l2-relayd.service &>/dev/null; then
    log "Enabling and starting v4l2-relayd for IPU6 camera support..."
    sudo systemctl enable --now v4l2-relayd
    ok "v4l2-relayd service enabled and started."
else
    warn "v4l2-relayd service not found. Skipping camera relay setup."
fi

# Ensure Microphone is unmuted
if command -v wpctl &>/dev/null; then
    log "Ensuring default audio source is unmuted..."
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 || warn "Failed to unmute via wpctl"
    ok "Microphone unmute command attempted."
else
    warn "wpctl not found. Skipping audio configuration."
fi

ok "Multimedia setup complete."
