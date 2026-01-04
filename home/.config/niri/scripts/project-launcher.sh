#!/bin/bash

# Project Launcher for Niri
# Uses zoxide and fd to find projects and opens them in a new workspace

# 1. Gather potential project directories
# We combine zoxide's history with a shallow search of common project roots
PROJECT_ROOTS=("$HOME/projects" "$HOME/Development" "$HOME/src" "$HOME/dofs" "$HOME/work")
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

# 2. Create a new Niri workspace
# We don't name it here, but we could if we wanted to dynamically add workspace names
# For now, just focus it
niri msg action focus-workspace-down
# Wait a bit for the workspace to be ready
sleep 0.1

# 3. Launch the environment
# - Neovim in the main column
# - Terminals/Lazygit if needed
(cd "$PICK" && ghostty -e nvim .) &
# Small delay to ensure Neovim opens first
sleep 0.3

# (Optional) Open Lazygit in a smaller column or floating
# niri msg action spawn -- ghostty -e lazygit

# Notify the user
notify-send "Project Starred" "Opened $(basename "$PICK") in a new workspace"
