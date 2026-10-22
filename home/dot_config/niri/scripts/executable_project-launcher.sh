#!/bin/bash
# Project picker for the dofs Quickshell launcher.
# Provider: zoxide + shallow fd scan of project roots; activation opens the
# project in a new named niri workspace (see project-open.sh).
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/menu-lib.sh"

PROJECT_ROOTS=("$HOME/projects" "$HOME/Development" "$HOME/src" "$HOME/dofs" "$HOME/Documents/work" "$HOME/Documents/personal")
PROJECTS_FILE=$(mktemp)
trap 'rm -f "$PROJECTS_FILE"' EXIT

if command -v zoxide >/dev/null 2>&1; then
    zoxide query -l > "$PROJECTS_FILE" || true
fi

for root in "${PROJECT_ROOTS[@]}"; do
    if [ -d "$root" ]; then
        fd --max-depth 2 --type d . "$root" >> "$PROJECTS_FILE" || true
    fi
done

count=0
while IFS= read -r pick; do
    [[ -n $pick && -d $pick ]] || continue
    count=$((count + 1))
    menu_item "$(basename "$pick")" "Open $pick in a new workspace" "folder-documents" \
        -- bash "$HOME/.config/niri/scripts/project-open.sh" "$pick"
done < <(sort -u "$PROJECTS_FILE" | grep -v "/\." || true)

[[ $count -gt 0 ]] || { echo "no projects found" >&2; exit 1; }
