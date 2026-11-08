#!/usr/bin/env bash
set -euo pipefail

exec bash "${XDG_CONFIG_HOME:-$HOME/.config}/niri/scripts/quickshell-launcher.sh" wallpapers
