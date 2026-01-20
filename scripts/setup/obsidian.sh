#!/bin/bash
# Setup script for Obsidian with Google Drive sync
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[0;33m==> %s\033[0m\n" "$1"; }
err() { printf "\033[0;31m==> %s\033[0m\n" "$1"; }
ok() { printf "\033[0;32m==> %s\033[0m\n" "$1"; }

log "Setting up Obsidian Sync (rclone + Google Drive)..."

# Check if rclone is installed and supports bisync (v1.58+)
RCLONE_VERSION=$(rclone version | head -n 1 | grep -oP 'v\K[0-9]+\.[0-9]+' || echo "0.0")
MIN_VERSION="1.58"
# Check if MIN_VERSION is strictly greater than RCLONE_VERSION (meaning RCLONE is older)
if [ "$(printf '%s\n%s' "$MIN_VERSION" "$RCLONE_VERSION" | sort -V | head -n1)" != "$MIN_VERSION" ]; then
    err "rclone version $RCLONE_VERSION is too old! bisync requires v1.58 or later."
    err "Please update rclone: sudo dnf update rclone"
    exit 1
fi

# Check for private configuration
RCLONE_CONFIG="${HOME}/.config/rclone/rclone.conf"
if ! rclone listremotes 2>/dev/null | grep -q "^gdrive:$"; then
    log "Privacy Notice: rclone stores your private tokens in '$RCLONE_CONFIG'."
    log "This file is NOT part of your dotfiles repo and stays local to this machine."
    warn "ACTION REQUIRED: Please run 'rclone config' and create a remote named 'gdrive'."
    exit 0 # Exit gracefully, user needs to do manual step
else
    ok "'gdrive' remote found in local configuration."
fi

# Test Google Drive API access
log "Testing Google Drive API connection..."
if ! rclone lsd gdrive: --max-depth 0 &>/dev/null; then
    err "Cannot connect to Google Drive!"
    err "Please enable the Google Drive API in your Google Cloud Console:"
    err "  https://console.developers.google.com/apis/api/drive.googleapis.com/overview"
    err "After enabling the API, run this script again."
    exit 1
fi
ok "Google Drive API connection successful."

# Create the OBSIDIAN folder on Google Drive if it doesn't exist
GDRIVE_FOLDER="OBSIDIAN"
log "Ensuring '$GDRIVE_FOLDER' folder exists on Google Drive..."
if ! rclone lsd "gdrive:$GDRIVE_FOLDER" --max-depth 0 &>/dev/null; then
    log "Creating '$GDRIVE_FOLDER' folder on Google Drive..."
    rclone mkdir "gdrive:$GDRIVE_FOLDER"
    ok "'$GDRIVE_FOLDER' folder created on Google Drive."
else
    ok "'$GDRIVE_FOLDER' folder already exists on Google Drive."
fi

# Ensure local vault directory exists
VAULT_DIR="${HOME}/vaults/google-drive"
mkdir -p "$VAULT_DIR"
ok "Local vault directory ready: $VAULT_DIR"

# Cleanup old service if it exists
OLD_SERVICE="rclone-mount.service"
if systemctl --user is-active --quiet "$OLD_SERVICE"; then
    log "Stopping old mount service..."
    systemctl --user stop "$OLD_SERVICE" || true
fi
systemctl --user disable "$OLD_SERVICE" &>/dev/null || true

# Enable and start the systemd user service/timer
SERVICE_NAME="rclone-sync.service"
TIMER_NAME="rclone-sync.timer"
log "Activating background sync timer..."

# Reload systemd to pick up new files
systemctl --user daemon-reload

# Perform initial resync only if not already initialized
log "Checking if initial sync is needed..."
# rclone bisync stores state files - we check if a sync has ever run successfully
if rclone bisync "$VAULT_DIR" "gdrive:OBSIDIAN" --dry-run &>/dev/null; then
    log "Vault already initialized for bisync. Performing a standard sync..."
    SYNC_SCRIPT="${HOME}/dofs/scripts/obsidian/sync.sh"
    if [ -x "$SYNC_SCRIPT" ]; then
        "$SYNC_SCRIPT"
    else
        warn "Sync script not found or not executable at $SYNC_SCRIPT. Skipping initial sync."
    fi
else
    log "Performing first-time bidirectional resync (this may take a moment)..."
    if rclone bisync "$VAULT_DIR" "gdrive:OBSIDIAN" --resync --verbose --compare size,modtime; then
        ok "Initial resync successful."
    else
        err "Initial resync failed! Please check your internet connection and rclone config."
        exit 1
    fi
fi

# Enable timer
systemctl --user enable "$TIMER_NAME"
systemctl --user start "$TIMER_NAME"

# Check if timer is active
if systemctl --user is-active --quiet "$TIMER_NAME"; then
    ok "Obsidian sync timer is now active."
else
    warn "Timer started but may have issues. Check with: systemctl --user status $TIMER_NAME"
fi

ok "Obsidian setup script finished."
