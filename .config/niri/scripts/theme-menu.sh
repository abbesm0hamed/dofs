#!/bin/bash

set -euo pipefail

if ! command -v fuzzel >/dev/null 2>&1; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Theme" "fuzzel not found"
    fi
    exit 1
fi

script_real="$(readlink -f "$0" 2>/dev/null || echo "$0")"
script_dir="$(cd "$(dirname "$script_real")" && pwd)"
repo_root="$(cd "$script_dir/../../.." && pwd)"

theme_manager=""
if [ -f "$repo_root/scripts/theme-manager.sh" ]; then
    theme_manager="$repo_root/scripts/theme-manager.sh"
elif [ -f "$HOME/dofs/scripts/theme-manager.sh" ]; then
    theme_manager="$HOME/dofs/scripts/theme-manager.sh"
fi

if [ -z "$theme_manager" ]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Theme" "theme-manager.sh not found"
    fi
    exit 1
fi

theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
if [ ! -d "$theme_dir" ] && [ -d "$repo_root/.config/theme" ]; then
    theme_dir="$repo_root/.config/theme"
fi

if [ ! -d "$theme_dir" ]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Theme" "Theme directory not found"
    fi
    exit 1
fi

themes="$(find "$theme_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort)"
if [ -z "$themes" ]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Theme" "No themes found"
    fi
    exit 1
fi

choice="$(printf '%s\n' "$themes" | fuzzel --dmenu --prompt="Theme: " --width=30 --lines=10)"
if [ -z "${choice:-}" ]; then
    exit 0
fi

bash "$theme_manager" set "$choice"
