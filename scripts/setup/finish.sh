#!/bin/bash
set -euo pipefail

log() { printf "\033[0;34m==> %s\033[0m\n" "$1"; }

log "Refreshing font cache..."
fc-cache -fv >/dev/null 2>&1
