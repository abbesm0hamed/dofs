#!/bin/bash

# Project Launcher for Niri
# Uses zoxide and fd to find projects and opens them in a new workspace

# 1. Gather potential project directories
# We combine zoxide's history with a shallow search of common project roots
PROJECT_ROOTS=("$HOME/projects" "$HOME/Development" "$HOME/src" "$HOME/dofs" "$HOME/Documents/work" "$HOME/Documents/personal")
PROJECTS_FILE=$(mktemp)

# Add zoxide results
if command -v zoxide &>/dev/null; then
    zoxide query -l > "$PROJECTS_FILE"
fi

# Add shallow search results (depth 2 to find project folders)
for root in "${PROJECT_ROOTS[@]}"; do
    if [ -d "$root" ]; then
        fd --max-depth 2 --type d . "$root" >> "$PROJECTS_FILE"
    fi
done

# Deduplicate and filter (removing hidden dirs)
PICK=$(cat "$PROJECTS_FILE" | sort -u | grep -v "/\." | fuzzel --dmenu --prompt="Project: " --width=80)

rm "$PROJECTS_FILE"

if [ -z "$PICK" ]; then
    exit 0
fi

# Expand ~ if present
PICK="${PICK/#\~/$HOME}"

# 2. Create a new Niri workspace and rename it
PROJ_NAME=$(basename "$PICK")
niri msg action focus-workspace-down
sleep 0.1
niri msg action set-workspace-name "[$PROJ_NAME]"

# 3. Launch the environment
# - Neovim in the main column
(cd "$PICK" && ghostty -e nvim .) &
# Small delay to ensure Neovim opens first
sleep 0.3

# Notify the user
notify-send "Project Launched" "Opened [$PROJ_NAME] in a new workspace"
