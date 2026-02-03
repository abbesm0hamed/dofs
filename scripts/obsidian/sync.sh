#!/bin/bash
# Wrapper script for rclone bisync for Obsidian notes
set -euo pipefail

LOCKFILE="/tmp/obsidian-sync.lock"
LOCAL_DIR="${HOME}/vaults/google-drive"
REMOTE_DIR="gdrive:OBSIDIAN"

# Ensure log directory exists
mkdir -p "${HOME}/.cache/obsidian"
LOG_FILE="${HOME}/.cache/obsidian/sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Run with lock to prevent concurrent syncs
(
    flock -n 9 || { log "Sync already in progress. Skipping."; exit 0; }

    log "Starting bidirectional sync..."
    
    # Run bisync
    # --compare size,modtime: fast comparison (standard for most syncs)
    # --resilient: don't fail on minor errors
    if rclone bisync "$LOCAL_DIR" "$REMOTE_DIR" \
        --compare size,modtime \
        --resilient \
        --links \
        --transfers 8 \
        --checkers 16 \
        --verbose \
        2>&1 | tee -a "$LOG_FILE"; then
        log "Sync completed successfully."
        # Notify user on desktop
        if command -v notify-send &>/dev/null; then
            notify-send "Obsidian Sync" "Notes synchronized successfully with Google Drive." -i obsidian
        fi
    else
        log "Sync failed! Check logs for details."
        if command -v notify-send &>/dev/null; then
            notify-send "Obsidian Sync" "Sync failed! Check logs at ~/.cache/obsidian/sync.log" -u critical -i error
        fi
        exit 1
    fi

) 9>"$LOCKFILE"