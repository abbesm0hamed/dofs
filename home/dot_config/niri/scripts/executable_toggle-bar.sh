#!/usr/bin/env bash
set -euo pipefail
# Hide only the panel surfaces; the launcher and shared services stay alive.
exec bash "${XDG_CONFIG_HOME:-$HOME/.config}/niri/scripts/quickshell-launcher.sh" --bar-toggle
