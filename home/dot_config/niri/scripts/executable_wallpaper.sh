#!/usr/bin/env bash
set -euo pipefail

helper="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/dofs/wallpaper/backend.py"
if [[ ! -f "$helper" ]]; then
    echo "Quickshell wallpaper backend not found: $helper" >&2
    exit 1
fi
exec python3 -B "$helper" "$@"
