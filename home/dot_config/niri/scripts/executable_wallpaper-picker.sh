#!/bin/bash
# Wallpaper picker for the dofs Quickshell launcher.
# Provider: one JSON item per wallpaper file; activation applies it.
set -euo pipefail

WALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/backgrounds"
REPO_WALL_DIR="$HOME/dofs/home/dot_config/backgrounds"
SETTER="${HOME}/.config/niri/scripts/wallpaper.sh"

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/menu-lib.sh"

count=0
for DIR in "$WALL_DIR" "$REPO_WALL_DIR"; do
    while IFS= read -r file; do
        count=$((count + 1))
        menu_item "$(basename "$file")" "Apply this wallpaper" "preferences-desktop-wallpaper" \
            -- bash "$SETTER" "$file"
    done < <(find "$DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.jpe' -o -iname '*.png' -o -iname '*.webp' \) \
        ! -iname 'blurry-*' ! -iname 'current*' ! -iname 'generated-*' -print 2>/dev/null | sort)
done

[[ $count -gt 0 ]] || { echo "no wallpaper images in $WALL_DIR or $REPO_WALL_DIR" >&2; exit 1; }
