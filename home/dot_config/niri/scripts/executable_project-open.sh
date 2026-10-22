#!/bin/bash
# Open one project in a fresh, named niri workspace with nvim ready.
# Argument: the project directory (the launcher passes it as a single argv).
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

pick=$1
[[ -n $pick && -d $pick ]] || { echo "not a directory: $pick" >&2; exit 1; }

project_name=$(basename "$pick")
niri msg action focus-workspace-down
sleep 0.1
niri msg action set-workspace-name "[$project_name]"

(cd "$pick" && exec ghostty -e nvim .) &
notify-send "Project Launched" "Opened [$project_name] in a new workspace" || true
